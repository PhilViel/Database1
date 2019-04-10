/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_ModifierParametres
Nom du service		: Modifier des paramètres 
But 				: Modifier une série de paramètres de l’IQÉÉ.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				iID_Parametres_IQEE			Identifiant unique de la série de paramètres à mettre à jour.
						dtDate_Debut_Cotisation		Date de début d'admissibilité des cotisations à l'IQÉÉ.
						dtDate_Fin_Cotisation		Date de fin d'admissibilité des cotisations à l'IQÉÉ.
						siNb_Jour_Limite_Demande	Nombre limite de jour après la fin de l'année fiscale pour faire
													une demande qui est considérée dans les délais.
						tiNb_Maximum_Annee_Fiscale_	Nombre maximum d'années fiscales antérieurs à l'année en 
							Anterieur				cours qu'il est permis de faire une demande en retard.
						iID_Utilisateur_			Identifiant unique de l'utilisateur fait la modification.  S’il 
							Modification			n’est pas spécifié, le service considère l’utilisateur système.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_ModifierParametres] 1, '2007-01-01', '2007-12-31', 90, 3, 495707

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					0 = Traitement réussi
																					-1 = Paramètres incomplets
																					-2 = Erreur de traitement


Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2008-06-02		Éric Deshaies						Création du service							
		2009-03-24		Éric Deshaies						Vérifier l'existence de l'utilisateur
		2009-07-21		Éric Deshaies						Correction ROLLBACK
		2009-11-05		Éric Deshaies						Mise à niveau selon les normes de développement.

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_ModifierParametres] 
(
	@iID_Parametres_IQEE INT,
	@dtDate_Debut_Cotisation DATETIME,
	@dtDate_Fin_Cotisation DATETIME,
	@siNb_Jour_Limite_Demande SMALLINT,
	@tiNb_Maximum_Annee_Fiscale_Anterieur TINYINT,
	@iID_Utilisateur_Modification INT
)
AS
BEGIN
	-- Retourner -1 s'il y a des paramètres manquants ou que la série de paramètre n'existe pas ou
	-- n'est pas la dernière série en vigueur
	IF @iID_Parametres_IQEE IS NULL OR @iID_Parametres_IQEE = 0 OR
	   @dtDate_Debut_Cotisation IS NULL OR 
	   @dtDate_Fin_Cotisation IS NULL OR
	   @siNb_Jour_Limite_Demande IS NULL OR 
	   @tiNb_Maximum_Annee_Fiscale_Anterieur IS NULL OR
	   NOT EXISTS(SELECT * 
				  FROM tblIQEE_Parametres
				  WHERE iID_Parametres_IQEE = @iID_Parametres_IQEE AND
						dtDate_Fin_Application IS NULL)
		RETURN -1

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
		-- Modifier la série de paramètres
		UPDATE tblIQEE_Parametres
		SET dtDate_Debut_Cotisation = dbo.FN_CRQ_DateNoTime(@dtDate_Debut_Cotisation),
			dtDate_Fin_Cotisation = dbo.fnGENE_DateDeFinAvecHeure(@dtDate_Fin_Cotisation),
			siNb_Jour_Limite_Demande = @siNb_Jour_Limite_Demande,
			tiNb_Maximum_Annee_Fiscale_Anterieur = @tiNb_Maximum_Annee_Fiscale_Anterieur,
			iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
			dtDate_Modification = GETDATE()
		WHERE iID_Parametres_IQEE = @iID_Parametres_IQEE

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

