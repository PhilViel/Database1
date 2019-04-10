/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ModifierErreur
Nom du service		: Modifier une erreur
But 				: Modifier une erreur de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Erreur					Identifiant unique de l’erreur à mettre à jour.
						tiID_Statuts_Erreur			Identifiant unique du statut modifié de l’erreur
						tCommentaires				Commentaires modifié de l’erreur.
						dtDate_Modification			Date de dernière modification originale de la transaction.  Si
													l’erreur n’a jamais été modifiée, la valeur nulle sera acceptée.
						iID_Utilisateur_			Identifiant unique de l'utilisateur qui fait la modification.   S’il 
							Modification			n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ModifierErreur] 43, 2, 'Ceci est un test', '2008-10-07 10:33:50.472', 519626

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Paramètres incomplets
																					-2 = Erreur de concurrence
																					-3 = Erreur de traitement

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-10-07		Éric Deshaies						Création du service							
		2008-10-30		Patrice Péau						dtDate_Modification par default a null
		2009-03-24		Éric Deshaies						Vérification de l'existance de l'utilisateur
		2009-04-17		Éric Deshaies						Mettre à jour le statut du fichier d’erreurs
		2009-10-27		Éric Deshaies						Enregistrer l'utilisateur et la date de
															traitement de l'erreur.  Mise à niveau
															selon les normes de développement.
		2010-08-31		Éric Deshaies						Correction de la gestion de la concurrence.
		2010-09-09		Éric Deshaies						Séparation de la mise à jour du statut des
															rapports d'erreurs de ce service.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ModifierErreur] 
(
	@iID_Erreur	INT,
	@tiID_Statuts_Erreur TINYINT,
	@tCommentaires TEXT,
	@dtDate_Modification DATETIME = NULL,
	@iID_Utilisateur_Modification INT
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres manquants ou que l'erreur n'existe pas
	IF @iID_Erreur IS NULL OR @iID_Erreur = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Erreurs
				  WHERE iID_Erreur = @iID_Erreur) OR
	   @tiID_Statuts_Erreur IS NULL OR @tiID_Statuts_Erreur = 0 OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_StatutsErreur
				  WHERE tiID_Statuts_Erreur = @tiID_Statuts_Erreur)
		RETURN -1

	-- Retourner -2 s'il y a une erreur de concurrence
	DECLARE @DateDuJour DATETIME,
			@dtDate_Derniere_Modification DATETIME

	SET @DateDuJour = GETDATE()

	SELECT @dtDate_Derniere_Modification = E.dtDate_Modification
	FROM tblIQEE_Erreurs E
	WHERE E.iID_Erreur = @iID_Erreur

	IF (@dtDate_Modification IS NULL AND @dtDate_Derniere_Modification IS NOT NULL) OR
	   (@dtDate_Modification IS NOT NULL AND @dtDate_Derniere_Modification IS NULL) OR
	   (ISNULL(@dtDate_Derniere_Modification,@DateDuJour) > ISNULL(@dtDate_Modification,@DateDuJour))
		RETURN -2

	-- Prendre l'utilisateur du système s'il est absent en paramètre
	IF @iID_Utilisateur_Modification IS NULL OR @iID_Utilisateur_Modification = 0 OR
		NOT EXISTS (SELECT *
					FROM Mo_User U
					WHERE U.UserID = @iID_Utilisateur_Modification)
		SELECT TOP 1 @iID_Utilisateur_Modification = D.iID_Utilisateur_Systeme
		FROM Un_Def D

	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		-- Déterminer le code de statut de l'erreur
		DECLARE @vcCode_Statut VARCHAR(3)

		SELECT @vcCode_Statut = SE.vcCode_Statut
		FROM tblIQEE_StatutsErreur SE
		WHERE SE.tiID_Statuts_Erreur = @tiID_Statuts_Erreur

		-- Modifier l'erreur
		UPDATE tblIQEE_Erreurs
		SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur,
			tCommentaires = @tCommentaires,
			iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
			dtDate_Modification = @DateDuJour,
			iID_Utilisateur_Traite = CASE WHEN @vcCode_Statut = 'TAR' AND SE.vcCode_Statut = 'ATR' THEN @iID_Utilisateur_Modification
										  WHEN @vcCode_Statut = 'ATR' AND SE.vcCode_Statut <> 'ATR' THEN NULL
										  ELSE iID_Utilisateur_Traite
									 END,
			dtDate_Traite = CASE WHEN @vcCode_Statut = 'TAR' AND SE.vcCode_Statut = 'ATR' THEN @DateDuJour
								 WHEN @vcCode_Statut = 'ATR' AND SE.vcCode_Statut <> 'ATR' THEN NULL
								 ELSE dtDate_Traite
							END
		FROM tblIQEE_Erreurs E
			 JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
		WHERE E.iID_Erreur = @iID_Erreur

		-- Mettre à jour le statut du fichier d'erreurs RQ
		DECLARE @iID_Fichier_IQEE INT

		SELECT @iID_Fichier_IQEE = iID_Fichier_IQEE
		FROM tblIQEE_Erreurs E
		WHERE E.iID_Erreur = @iID_Erreur

		EXECUTE [dbo].[psIQEE_MettreAJourStatutRapportsErreurs] @iID_Fichier_IQEE

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
		RETURN -3
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN 0
END

