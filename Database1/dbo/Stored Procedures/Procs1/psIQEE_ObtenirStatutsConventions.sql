/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ObtenirStatutsConventions
Nom du service		: Obtenir les statuts des conventions
But 				: Obtenir la liste des statuts d'IQÉÉ des conventions selon la langue de l’utilisateur et la
					  terminologie désirée selon le contexte.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Structure_Historique_	Identifiant unique de la structure de présentation afin de déterminer
							Presentation			la terminologie à afficher.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ObtenirStatutsConventions] 'FRA', 3

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Tous les champs de la table « tblIQEE_HistoStatutsConventions ».  Les statuts des conventions
						sont triés en ordre de présentation.

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-10-20		Éric Deshaies						Création du service	

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ObtenirStatutsConventions] 
(
	@cID_Langue CHAR(3),
	@iID_Structure_Historique_Presentation INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON

	BEGIN TRY
		-- Considérer le français comme la langue par défaut
		IF @cID_Langue IS NULL
			SET @cID_Langue = 'FRA'

		-- Retourner les structures d'historique
		SELECT S.iID_Statut_Convention,
			   S.vcCode_Statut,
			   COALESCE([dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoPresentations','vcDescription',PS.iID_Presentation,NULL,@cID_Langue),
					   PS.vcDescription,
					   [dbo].[fnGENE_ObtenirTraduction]('tblIQEE_HistoStatutsConventions','vcDescription',S.iID_Statut_Convention,NULL,@cID_Langue),
					   S.vcDescription) AS vcDescription
		FROM tblIQEE_HistoStatutsConventions S
			 LEFT JOIN tblIQEE_HistoPresentations PS ON PS.iID_Structure_Historique = @iID_Structure_Historique_Presentation
													AND PS.vcCode_Type_Info = 'STC'
													AND PS.vcCode_Info = S.vcCode_Statut
		ORDER BY S.iOrdre_Presentation
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -1 en cas d'erreur de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 en cas de réussite du traitement
	RETURN 1
END

