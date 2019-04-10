/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_CESPReceivedFileDtl
Description         :	Sauvegarde l'ajout et la modification de fichiers fesant parti d'un retour du PCEE
Valeurs de retours  :	Dataset :
									iCESPSendFileID		INTEGER		ID du fichier d’envoi au PCEE.
									vcCESPSendFile			VARCHAR(75)	Nom du fichier d’envoi au PCEE.
									dtCESPSendFile			DATETIME		Date d’envoi du fichier au PCEE.
									iCESPReceiveFileID	INTEGER		ID du fichier de retour correspondant à ce fichier d’envoi.
Note                :	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*********************************************************************************************************************/
CREATE PROC [dbo].[IU_UN_CESPReceivedFileDtl] (
	@iCESPReceiveFileDtlID INTEGER,
	@iCESPReceiveFileID INTEGER,
	@vcCESPReceiveFileName VARCHAR(75) )
AS
BEGIN
	DECLARE
		@iResult INTEGER

	IF @iCESPReceiveFileDtlID = 0
	BEGIN
		INSERT INTO Un_CESPReceiveFileDtl (
			iCESPReceiveFileID,
			vcCESPReceiveFileName)
		VALUES (
			@iCESPReceiveFileID,
			@vcCESPReceiveFileName)
			
		IF @@ERROR = 0
			SET @iResult = IDENT_CURRENT('Un_CESPReceiveFileDtl')
		ELSE
			SET @iResult = 0
	END
	ELSE
	BEGIN
		UPDATE Un_CESPReceiveFileDtl SET
			iCESPReceiveFileID = @iCESPReceiveFileID,
			vcCESPReceiveFileName = @vcCESPReceiveFileName
		WHERE iCESPReceiveFileDtlID = @iCESPReceiveFileDtlID

		IF @@ERROR = 0
			SET @iResult = @iCESPReceiveFileDtlID
		ELSE
			SET @iResult = 0
	END

	RETURN @iResult 
END

