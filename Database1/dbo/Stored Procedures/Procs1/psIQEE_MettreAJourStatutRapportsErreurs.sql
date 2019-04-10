/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_MettreAJourStatutRapportsErreurs
Nom du service		: Mettre à jour le statut de rapports d'erreurs
But 				: Mettre à jour le statut d'un ou de tous les rapports d'erreurs de l'IQÉÉ.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Fichier_IQEE			Identifiant unique du rapport d'erreur pour lequel l'appelant veux
													mettre à jour le statut.  S'il est absent ou s'il est présent mais
													invalide, tous les rapports d'erreurs sont mis à jour.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_MettreAJourStatutRapportsErreurs] NULL

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					Code de retour standard

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-09-09		Éric Deshaies						Création du service							

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_MettreAJourStatutRapportsErreurs] 
(
	@iID_Fichier_IQEE INT
)
AS
BEGIN
	-- Si le rapport d'erreurs spécifique est présent mais invalide, mettre à jour tous les rapports d'erreurs
	IF @iID_Fichier_IQEE IS NOT NULL AND
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Fichiers F
				  WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE)
		SET @iID_Fichier_IQEE = NULL

	SET XACT_ABORT ON 

	BEGIN TRANSACTION

	BEGIN TRY
		DECLARE @iNB_Erreur_Fichier INT,
				@iNB_Erreur_A_Traiter INT,
				@vcCode_Statut VARCHAR(3)

		-- Rechercher les rapports d'erreurs applicables
		DECLARE curRapportsErreurs CURSOR LOCAL FAST_FORWARD FOR
			SELECT F.iID_Fichier_IQEE
			FROM tblIQEE_Fichiers F
				 JOIN tblIQEE_TypesFichier TF ON TF.tiID_Type_Fichier = F.tiID_Type_Fichier
											 AND TF.vcCode_Type_Fichier = 'ERR'
			WHERE @iID_Fichier_IQEE IS NULL OR F.iID_Fichier_IQEE = @iID_Fichier_IQEE

		-- Boucler parmis les rapports d'erreurs sélectionnés
		OPEN curRapportsErreurs
		FETCH NEXT FROM curRapportsErreurs INTO @iID_Fichier_IQEE
		WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Mettre à jour le statut du fichier d'erreurs RQ
				SELECT @iNB_Erreur_Fichier = COUNT(*)
				FROM tblIQEE_Erreurs E
				WHERE E.iID_Fichier_IQEE = @iID_Fichier_IQEE

				SELECT @iNB_Erreur_A_Traiter = COUNT(*)
				FROM tblIQEE_Erreurs E
					 JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
												  AND SE.vcCode_Statut = 'ATR'
				WHERE E.iID_Fichier_IQEE = @iID_Fichier_IQEE

				IF @iNB_Erreur_A_Traiter = @iNB_Erreur_Fichier
					SET @vcCode_Statut = 'ATR'
				ELSE
					IF @iNB_Erreur_A_Traiter = 0
						SET @vcCode_Statut = 'TCO'
					ELSE
						SET @vcCode_Statut = 'PCO'

				UPDATE tblIQEE_Fichiers
				SET tiID_Statut_Fichier = (SELECT SF.tiID_Statut_Fichier
										   FROM tblIQEE_StatutsFichier SF
										   WHERE SF.vcCode_Statut = @vcCode_Statut)
				WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE

				FETCH NEXT FROM curRapportsErreurs INTO @iID_Fichier_IQEE
			END
		CLOSE curRapportsErreurs
		DEALLOCATE curRapportsErreurs

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
		RETURN -1
	END CATCH

	-- Retourner 0 en cas de réussite du traitement
	RETURN 1
END

