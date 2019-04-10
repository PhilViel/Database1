/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ModifierFichier
Nom du service		: Modifier un fichier
But 				: Modifier un fichier de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant unique du fichier à mettre à jour.
						tCommentaires				Commentaires modifié du fichier.
						dtDate_Modification			Date de dernière modification originale de la transaction.  Si le
													fichier n’a jamais été modifié, la valeur nulle sera acceptée.
						iID_Utilisateur_			Identifiant unique de l'utilisateur qui fait la modification.   S’il 
							Modification			n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ModifierFichier] 9, 'Ceci est un test', '2008-10-07 10:33:50.472', 495707

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Paramètres incomplets
																					-2 = Erreur de concurrence
																					-3 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-10-31		Éric Deshaies						Création du service							
		2009-03-24		Éric Deshaies						Vérifier l'existance de l'utilisateur
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.			
		2010-08-31		Éric Deshaies						Correction de la gestion de la concurrence.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ModifierFichier] 
(
	@iID_Fichier_IQEE INT,
	@tCommentaires TEXT,
	@dtDate_Modification DATETIME = NULL,
	@iID_Utilisateur_Modification INT
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres manquants ou que le fichier n'existe pas
	IF @iID_Fichier_IQEE IS NULL OR @iID_Fichier_IQEE = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Fichiers
				  WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE)
		RETURN -1

	-- Retourner -2 s'il y a une erreur de concurrence
	DECLARE @DateDuJour DATETIME,
			@dtDate_Derniere_Modification DATETIME

	SET @DateDuJour = GETDATE()

	SELECT @dtDate_Derniere_Modification = F.dtDate_Modification
	FROM tblIQEE_Fichiers F
	WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE

	IF (@dtDate_Modification IS NULL AND @dtDate_Derniere_Modification IS NOT NULL) OR
	   (@dtDate_Modification IS NOT NULL AND @dtDate_Derniere_Modification IS NULL) OR
	   (ISNULL(@dtDate_Derniere_Modification,@DateDuJour) > ISNULL(@dtDate_Modification,@DateDuJour))
		RETURN -2

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Modification IS NULL OR @iID_Utilisateur_Modification = 0 OR
		NOT EXISTS (SELECT *
					FROM Mo_User U
					WHERE U.UserID = @iID_Utilisateur_Modification)
		SELECT TOP 1 @iID_Utilisateur_Modification = iID_Utilisateur_Systeme
		FROM Un_Def

	SET XACT_ABORT ON 
	
	BEGIN TRANSACTION

	BEGIN TRY
		-- Modifier le fichier
		UPDATE tblIQEE_Fichiers
		SET tCommentaires = @tCommentaires,
			iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
			dtDate_Modification = @DateDuJour
		WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

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

		-- Retourner -3 en cas d'erreur de traitement
		RETURN -3
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN 0
END

