/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psCONV_RechercherConvSousBenef
Nom du service		: Rechercher les conventions, souscripteurs et bénéficiaires
But 				: Rechercher les conventions, souscripteurs et bénéficiaires selon les identifiants.
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						cID_Langue					Identifiant unique de la langue de l’utilisateur selon « Mo_Lang ».
													Le français est la langue par défaut si elle n’est pas spécifiée.
						iID_Convention				Identifiant unique de la convention.  S’il est vide, toutes les
													conventions sont considérées.
						iID_Beneficiaire			Identifiant unique du bénéficiaire.  S'il est vide, tous les
													bénéficiaires sont considérés.
						iID_Souscripteur			Identifiant unique du souscripteur.  S'il est vide, tous les
													souscripteurs sont considérés.

Exemple d’appel		:	EXECUTE [dbo].[psCONV_RechercherConvSousBenef] 'FRA', 214276, NULL, NULL
						EXECUTE [dbo].[psCONV_RechercherConvSousBenef] 'FRA', NULL, 380490, NULL
						EXECUTE [dbo].[psCONV_RechercherConvSousBenef] 'FRA', NULL, NULL, 380489

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						Un_Convention				iID_Convention					Identifiant de la convention
						Un_Convention				vcNo_Convention					Numéro de la convention
						Un_Convention				iID_Beneficiaire				Identifiant du bénéficiaire
						Mo_Human					vcPrenom_Beneficiaire			Prénom du bénéficiaire
						Mo_Human					vcNom_Beneficiaire				Nom du bénéficiaire
						Un_Convention				iID_Souscripteur				Identifiant du souscripteur
						Mo_Human					vcPrenom_Souscripteur			Prénom du souscripteur
						Mo_Human					vcNom_Souscripteur				Nom du souscripteur

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2011-05-11		Éric Deshaies						Création du service
	
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RechercherConvSousBenef] 
(
	@cID_Langue CHAR(3),
	@iID_Convention INT = NULL,
	@iID_Beneficiaire INT = NULL,
	@iID_Souscripteur INT = NULL
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
		SELECT 	A.iID_Convention,
				A.vcNo_Convention,
				A.iID_Beneficiaire,
				A.vcPrenom_Beneficiaire,
				A.vcNom_Beneficiaire,
				A.iID_Souscripteur,
				A.vcPrenom_Souscripteur,
				A.vcNom_Souscripteur
		FROM [dbo].[fntCONV_RechercherConvSousBenef](@cID_Langue,@iID_Convention,@iID_Beneficiaire,@iID_Souscripteur) A 
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

