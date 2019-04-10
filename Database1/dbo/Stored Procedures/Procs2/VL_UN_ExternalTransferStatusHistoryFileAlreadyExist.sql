/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	VL_UN_ExternalTransferStatusHistoryFileAlreadyExist
Description         :	Dit si un fichier dont on veut faire la lecture existe déjà.
Valeurs de retours  :	> 0 : Existe déjà, le ID correspond au fichier déjà importé
			0 : N'existe pas
Note                :						2006-09-11	Mireya Gonthier		Création										
*********************************************************************************************************************/
CREATE  PROCEDURE [dbo].[VL_UN_ExternalTransferStatusHistoryFileAlreadyExist] (
	@ExternalTransferStatusHistoryFileName VARCHAR(75))
AS
BEGIN
	-- Valeur de retour
	-- > 0 : Existe déjà, le ID correspond au fichier déjà importé
	-- 0 : N'existe pas

	DECLARE 
		@ExternalTransferStatusHistoryFileID INTEGER

	SET @ExternalTransferStatusHistoryFileID = 0

	SELECT 
		@ExternalTransferStatusHistoryFileID = ExternalTransferStatusHistoryFileID
	FROM Un_ExternalTransferStatusHistoryFile  
	WHERE @ExternalTransferStatusHistoryFileName = ExternalTransferStatusHistoryFileName
 
	RETURN @ExternalTransferStatusHistoryFileID
END


