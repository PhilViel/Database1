/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_FusionnerSouscripteurs
Nom du service		: Fusionner des souscripteurs
But 				: Traiter les fusions de souscripteurs pour l'IQÉÉ.  C'est à dire, mettre à jour les identifiants
					  dans les transactions. 
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Souscripteur_Supprime	Identifiant unique du souscripteur supprimé.
						iID_Souscripteur_Conserve	Identifiant unique du souscripteur qui est conservé.
						iID_Utilisateur_Fusion		Identifiant unique de l'utilisateur qui fait la fusion des
													souscripteurs.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_FusionnerSouscripteurs] 1, 2, 3

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement terminé normalement
																					-1 = Erreur dans les paramètres
																					-2 = Erreur imprévue

Historique des modifications:
		Date			Programmeur							Description								
		------------	----------------------------------	-----------------------------------------
		2010-03-22		Éric Deshaies						Création du service	
		2014-09-26		Stéphane Barbeau					Désactivation des UPDATE concernant les cosouscripteurs.
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_FusionnerSouscripteurs]
(
	@iID_Souscripteur_Supprime INT,
	@iID_Souscripteur_Conserve INT,
	@iID_Utilisateur_Fusion INT
) 
AS
BEGIN
	-----------------
	-- Initialisation
	-----------------
	DECLARE @iID_Utilisateur_Systeme INT

	-- Retourner -1 s'il y a des paramètres manquants ou invalides
	IF @iID_Souscripteur_Supprime IS NULL OR @iID_Souscripteur_Supprime = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Mo_Human H
				  WHERE H.HumanID = @iID_Souscripteur_Supprime) OR
	   @iID_Souscripteur_Conserve IS NULL OR @iID_Souscripteur_Conserve = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM dbo.Mo_Human H
				  WHERE H.HumanID = @iID_Souscripteur_Conserve)
		RETURN -1

	-- Déterminer l'utilisateur système
	SELECT TOP 1 @iID_Utilisateur_Systeme = D.iID_Utilisateur_Systeme
	FROM Un_Def D

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Fusion IS NULL OR @iID_Utilisateur_Fusion = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM Mo_User U
				  WHERE U.UserID = @iID_Utilisateur_Fusion)
		SET @iID_Utilisateur_Fusion = @iID_Utilisateur_Systeme

	SET XACT_ABORT ON

	BEGIN TRANSACTION

	BEGIN TRY
		--------------------------------------------------
		-- Mettre à jour les identifiants des transactions
		--------------------------------------------------
		UPDATE tblIQEE_Demandes
		SET iID_Souscripteur = @iID_Souscripteur_Conserve
		WHERE iID_Souscripteur = @iID_Souscripteur_Supprime

		--  2014-09-26 SB: Desactivation.  La notion de cosouscripteur n'existe pas presentement dans nos produits.
		/*
		UPDATE tblIQEE_Demandes
		SET iID_Cosouscripteur = @iID_Souscripteur_Conserve
		WHERE iID_Cosouscripteur = @iID_Souscripteur_Supprime
		*/

		UPDATE tblIQEE_Transferts
		SET iID_Souscripteur = @iID_Souscripteur_Conserve
		WHERE iID_Souscripteur = @iID_Souscripteur_Supprime

		--  2014-09-26 SB: Desactivation.  La notion de cosouscripteur n'existe pas presentement dans nos produits.
		--UPDATE tblIQEE_Transferts
		--SET iID_Cosouscripteur = @iID_Souscripteur_Conserve
		--WHERE iID_Cosouscripteur = @iID_Souscripteur_Supprime

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		-- Lever l'erreur et faire le rollback
		DECLARE @ErrorMessage NVARCHAR(4000),
				@ErrorSeverity INT,
				@ErrorState INT

		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorState = ERROR_STATE()

		IF (XACT_STATE()) = -1 AND @@TRANCOUNT > 0 
			ROLLBACK TRANSACTION

		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState) WITH LOG;

		-- Retourner -2 en cas d'erreur de traitement
		RETURN -2
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN 0
END


