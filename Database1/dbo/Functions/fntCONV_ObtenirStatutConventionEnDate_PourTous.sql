/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service     : fntCONV_ObtenirStatutConventionEnDate_PourTous
Nom du service		: 
But 				: Permet d'obtenir le statut de toutes les conventions en fonction d'une date
Description		: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir les statuts des conventions
Facette			: CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
					--------------------------	-----------	-----------------------------------------------------------------
					@dtDateStatut				Non			Date à laquelle on veut récupérer les statuts, par défaut, ce sont les actuels
					@idConvention				Non			ID de la convention pour laquelle on veut le statut, par défaut, pour tous


Paramètres de sortie:	Table					Champ					Description
	  				-------------------------	--------------------------- 	---------------------------------
					Un_ConventionState			ConventionID				ID de la convention
					Un_ConventionState			ConventionStateID			Code du statut de la convention
					Un_ConventionState			StartDate					Date d'entrée en vigueur du statut

Exemple d'appel : 
        SELECT * FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, NULL)
        SELECT * FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(NULL, 319586)
        SELECT * FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous('2016-04-01', 319586)

Historique des modifications:
        Date        Programmeur			Description						Référence
        ----------  ------------------  ---------------------------  	------------
        2015-09-30  Steeve Picard       Création de la fonction		
        2016-07-08  Pierre-Luc Simard   Ajouter 23:59:59 à la date passée en paramètre lorsqu'elle ne contient pas 
                                        déjà des heures afin de tenir compte de tous les statuts de la journée demandée 
        2017-02-02  Steeve Picard       Remplacer la correction du 2016-07-08 en faisant plutôt un «CAST» pour éliminer les heures
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fntCONV_ObtenirStatutConventionEnDate_PourTous]
(
	@dtDateStatut	DATETIME = NULL,
	@idConvention	INT = NULL
)
RETURNS TABLE AS
RETURN (
	SELECT C.ConventionID, C.ConventionStateID, C.StartDate, C.ConventionConventionStateID
	FROM dbo.Un_ConventionConventionState C
	JOIN (
        SELECT
            ConventionID ,
            MAX(StartDate) AS LastStartDate
        FROM dbo.Un_ConventionConventionState
		WHERE ConventionID = ISNULL(@idConvention, ConventionID)
            AND Cast(StartDate as Date) <=  Cast(IsNull(@dtDateStatut, GETDATE()) as date)
        GROUP BY ConventionID
    ) S On S.ConventionID = C.ConventionID AND S.LastStartDate = C.StartDate
)

