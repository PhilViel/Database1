/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psIQEE_SupprimerDemandeAnnulation
Nom du service		: Supprimer une demande d'annulation
But 				: Permettre à l'utilisateur de retirer une demande d'annulation manuelle d'une transaction de l'IQÉÉ.
Facette				: IQEE

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						iID_Annulation				Identifiant unique de la demande d'annulation à supprimer.

Exemple d’appel		:	EXECUTE [dbo].[psIQEE_SupprimerDemandeAnnulation] 1

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iCode_Retour					1 = Traitement réussi
																					-1 = Traitement en erreur non
																						 prévisible

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2010-09-10		Éric Deshaies						Création du service

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_SupprimerDemandeAnnulation] 
(
	@iID_Annulation INT
)
AS
BEGIN
	SET XACT_ABORT ON 
	
	BEGIN TRANSACTION

	BEGIN TRY
		-- Supprimer la demande d'annulation
		DELETE FROM [dbo].[tblIQEE_Annulations]
		WHERE iID_Annulation = @iID_Annulation

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

		-- Retourner -1 en cas d'erreur non prévisible de traitement
		RETURN -1
	END CATCH

	-- Retourner 1 lors de la réussite du traitement
	RETURN 1
END




