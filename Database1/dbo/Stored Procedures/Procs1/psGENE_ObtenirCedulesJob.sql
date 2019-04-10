/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psGENE_ObtenirCedulesJob
Nom du service		: Obtenir les cédules d’une job 
But 				: Obtenir les cédules d’exécutions unitaires d’une job SQL.
Facette				: GENE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						vcNom_Job					Nom de la job SQL.  Le nom est requis sinon les champs de sortie
													seront nuls.

Exemple d’appel		:	EXECUTE [dbo].[psGENE_ObtenirCedulesJob] 'joIQEE_CreerFichiers'

Paramètres de sortie:	Tous les champs de la fonction "fntGENE_ObtenirCedulesJob"				

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-11-23		Éric Deshaies						Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_ObtenirCedulesJob] 
(
	@vcNom_Job VARCHAR(128)
)
AS
BEGIN
	SET NOCOUNT ON;

	-- Retourner les cédules
	SELECT  iID_Cedule,
			vcNom_Cedule,
			dtDate_Execution
	FROM [dbo].[fntGENE_ObtenirCedulesJob](@vcNom_Job)
END

