/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ModifierRejet
Nom du service		: Modifier un rejet
But 				: Modifier un rejet de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Rejet					Identifiant unique du rejet à mettre à jour.
						tCommentaires				Commentaires modifié du rejet.
						dtDate_Modification			Date de dernière modification originale de la transaction.  Si le 
													rejet n’a jamais été modifié, la valeur nulle sera acceptée.
						iID_Utilisateur_			Identifiant unique de l'utilisateur qui fait la modification.  S’il
							Modification			n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ModifierRejet] 100000, 'Ceci est un test', '2008-10-07 10:33:50.472', 495707

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						tblIQEE_Rejets				dtDate_Modification				Nouvelle date de la modification
																					après la mise à jour.
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Paramètres incomplets
																					-2 = Erreur de concurrence
																					-3 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-06-30		Éric Deshaies						Création du service							
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.		

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ModifierRejet] 
(
	@iID_Rejet INT,
	@tCommentaires TEXT,
	@dtDate_Modification DATETIME = NULL,
	@iID_Utilisateur_Modification INT,
	@dtNouvelle_Date_Modification DATETIME OUTPUT
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres manquants ou que le fichier n'existe pas
	IF @iID_Rejet IS NULL OR @iID_Rejet = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Rejets
				  WHERE iID_Rejet = @iID_Rejet)
		RETURN -1

	DECLARE @DateDuJour DATETIME;
	SET @DateDuJour = GETDATE()

	-- Retourner -2 s'il y a une erreur de concurrence
	IF (SELECT ISNULL(dtDate_Modification,@DateDuJour)
		FROM tblIQEE_Rejets
		WHERE iID_Rejet = @iID_Rejet) > ISNULL(@dtDate_Modification,@DateDuJour)
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
		-- Modifier le rejet
		UPDATE tblIQEE_Rejets
		SET tCommentaires = @tCommentaires,
			iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
			dtDate_Modification = @DateDuJour
		WHERE iID_Rejet = @iID_Rejet

		SET @dtNouvelle_Date_Modification = @DateDuJour

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

