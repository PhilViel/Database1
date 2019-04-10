/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	DL_UN_CESPTransferFile
Description         :	Suppression d'un fichier d'historique de status de transfert. 
Valeurs de retours  :	-- Valeurs de retours :
			-- >0  : La suppression a été effectué avec succès.  La valeur correspond au GovernmentSendFileID du fichier supprimé.
			-- -1  : Erreur lors de la suppression des historiques attachés au fichier
			-- -2  : Erreur lors de la suppression du fichier

Note                :						2006-09-11	Mireya Gonthier		Création										
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[DL_UN_CESPTransferFile] (
	@ExternalTransferStatusHistoryFileID INTEGER)
AS
BEGIN
	-- Valeurs de retours :
	-- >0  : La suppression a été effectué avec succès.  La valeur correspond au GovernmentSendFileID du fichier supprimé.
	-- -1  : Erreur lors de la suppression des historiques attachés au fichier
	-- -2  : Erreur lors de la suppression du fichier

	BEGIN TRANSACTION

	DELETE 
	FROM Un_ExternalTransferStatusHistory
	WHERE ExternalTransferStatusHistoryFileID = @ExternalTransferStatusHistoryFileID

	IF @@ERROR <> 0
		SET @ExternalTransferStatusHistoryFileID = -1 -- Erreur lors de la suppression des historiques attachés au fichier

	DELETE 
	FROM Un_ExternalTransferStatusHistoryFile
	WHERE ExternalTransferStatusHistoryFileID = @ExternalTransferStatusHistoryFileID

	IF @@ERROR <> 0
		SET @ExternalTransferStatusHistoryFileID = -2 -- Erreur lors de la suppression du fichier
  
	IF @ExternalTransferStatusHistoryFileID > 0
		COMMIT TRANSACTION
	ELSE
		ROLLBACK TRANSACTION

	RETURN @ExternalTransferStatusHistoryFileID
END


