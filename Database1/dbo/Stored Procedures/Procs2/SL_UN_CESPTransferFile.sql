/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	SL_UN_CESPTransferFile
Description         :	Renvoi la liste des fichiers d'historique des status.
Valeurs de retours  :	Dataset
				ExternalTransferStatushistoryFileID	ID unique du fichier d'historique de transfert 
									(Un_ExternalTransferStatusHistoryFile). ID unique du 
									fichier d'historique de transfert 
									(Un_ExternalTransferStatusHistoryFile). 
				ExternalTransferStatusHistoryFileName	Nom du fichier. Correspond au nom du fichier Excel. 
				ExterneTransferStatusHistoriFileDate	Date de réception du fichier Excel. 

Note                :						2006-09-11	Mireya Gonthier		Création										
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[SL_UN_CESPTransferFile] (
	@ExternalTransferStatusHistoryFileID INTEGER) -- ID unique du fichier voulue (0 = Tous) 
AS
BEGIN
	SELECT 
		F.ExternalTransferStatusHistoryFileID,
		F.ExternalTransferStatusHistoryFileName,
		F.ExternalTransferStatusHistoryFileDate
	FROM Un_ExternalTransferStatusHistoryFile F
	WHERE @ExternalTransferStatusHistoryFileID = F.ExternalTransferStatusHistoryFileID
		OR @ExternalTransferStatusHistoryFileID = 0
	ORDER BY F.ExternalTransferStatusHistoryFileDate DESC 
END


