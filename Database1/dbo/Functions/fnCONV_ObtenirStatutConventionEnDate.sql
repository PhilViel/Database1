/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: fnCONV_ObtenirStatutConventionEnDate
Nom du service		: 
But 				: Permet d'obtenir le statut de toutes les conventions en fonction d'une date
Description			: Cette fonction est appelée à chaque fois qu'il est nécesaire d'obtenir les statuts
					  des conventions
Facette				: CONV
Référence			: 

Paramètres d’entrée	:	Paramètre					Obligatoire	Description
						--------------------------	-----------	-----------------------------------------------------------------
						@iID_Convention				Oui			ID de la convention que l'on veut le statut
						@dtDateStatut				Non			Date à laquelle on identifie le statut à obtenir
		  			

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_ConventionState			ConventionStateID				Code du statut de la convention

Exemple d'appel : 
				SELECT dbo.fnCONV_ObtenirStatutConventionEnDate(100673,'2009-05-01')
	
Historique des modifications:
		Date			Programmeur					Description						Référence
		------------	-------------------------	---------------------------  	------------
		2009-07-31		Jean-François Gauthier		Création de la fonction		
		2015-09-30		Steeve Picard				Utilisation de la fonction global 
		2016-01-28		Steeve Picard				Ne plus utiliser l'ancien code du ELSE
*********************************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ObtenirStatutConventionEnDate]
(
	@iID_Convention	INT,
	@dtDateStatut	DATETIME = NULL
)
RETURNS VARCHAR(3)
AS
BEGIN
    DECLARE @vcStatutConvention VARCHAR(3)

    IF @dtDateStatut IS NULL
    BEGIN
        SET @dtDateStatut = GETDATE()
    END

    IF NOT (DB_Name() IN ('UnivBase'))  -- 2016-01-28
    BEGIN
        SELECT @vcStatutConvention = ConventionStateID
          FROM dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(@dtDateStatut, @iID_Convention)
    END
    ELSE
    BEGIN
        SELECT @vcStatutConvention = ucs.ConventionStateID
          FROM dbo.Un_ConventionState     ucs
               INNER JOIN dbo.Un_ConventionConventionState uccs
                     ON ucs.ConventionStateID = uccs.ConventionStateID 
               INNER JOIN (      
                   SELECT ccs.ConventionID, 
                          dtDateStatut = MAX(ccs.StartDate)  
                     FROM dbo.Un_ConventionConventionState ccs
                          INNER JOIN   dbo.Un_ConventionState cs
                                ON cs.ConventionStateID = ccs.ConventionStateID 
                    WHERE ccs.ConventionID    = @iID_Convention
                          AND ccs.StartDate       <= @dtDateStatut
                    GROUP BY ccs.ConventionID
                   ) AS tmp ON tmp.ConventionID = uccs.ConventionID AND tmp.dtDateStatut = uccs.StartDate
    END

    RETURN @vcStatutConvention
END
