/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ModifierCheminFichier
Nom du service		: Modifier le chemin d’un fichier 
But 				: Modifier le dernier chemin connu d’un fichier de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant unique du fichier à mettre à jour.
						vcChemin_Fichier			Dernier chemin connu du fichier.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ModifierCheminFichier] 9, 'C:\'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Paramètres incomplets
																					-2 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-11-04		Éric Deshaies						Création du service							
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.
		2010-03-30		Éric Deshaies						Appliquer sur l'ensemble du fichier physique.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ModifierCheminFichier] 
(
	@iID_Fichier_IQEE INT,
	@vcChemin_Fichier VARCHAR(150)
)
AS
BEGIN
	DECLARE @vcNom_Fichier VARCHAR(50)

	-- Retourner -1 s'il y a des paramètres manquants ou que le fichier n'existe pas
	IF @vcChemin_Fichier IS NULL OR @vcChemin_Fichier = '' OR
	   @iID_Fichier_IQEE IS NULL OR @iID_Fichier_IQEE = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Fichiers
				  WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)
		RETURN -1

	-- Déterminer le nom du fichier physique basé sur le fichier logique passé en paramètre
	SELECT @vcNom_Fichier = F.vcNom_Fichier
	FROM tblIQEE_Fichiers F
	WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		-- Modifier le fichier
		UPDATE tblIQEE_Fichiers
		SET vcChemin_Fichier = @vcChemin_Fichier
		WHERE vcNom_Fichier = @vcNom_Fichier

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

