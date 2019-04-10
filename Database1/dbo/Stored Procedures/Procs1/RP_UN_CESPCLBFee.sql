
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_CESPCLBFee
Description         :	Rapport des frais de BEC 

Valeurs de retours  :	Dataset :
							dtCESPSendFile	DATETIME	Date d’envoi du fichier
							dtRead			DATETIME	Date de réception du fichier
							ConventionNo	VARCHAR(15)	Numéro de convention
							vcTransID		VARCHAR(15)	ID PCEE
							fCLBFee			FLOAT		Frais de BEC

Note                :	ADX0001296	IA	2007-03-20	Alain Quirion			Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.RP_UN_CESPCLBFee (
	@iBlobID INTEGER ) -- ID du blob
AS
BEGIN
	DECLARE @tiCESPReceiveFileIDs TABLE(
		iCESPReceiveFileID INTEGER PRIMARY KEY)

	INSERT INTO @tiCESPReceiveFileIDs
		SELECT iVal
		FROM dbo.FN_CRI_BlobToIntegerTable(@iBlobID)
	
	SELECT 
		dtCESPSendFile = CSF.dtCESPSendFile,	--Date d’envoi du fichier
		dtRead = CRF.dtRead,					--Date de réception du fichier
		ConventionNo = C.ConventionNo,			--Numéro de convention
		vcTransID = C9.vcTransID,				--ID PCEE
		fCLBFee	= C9.fCLBFee					--Frais de BEC
	FROM Un_CESP900 C9
	JOIN Un_Convention C ON C.ConventionID = C9.ConventionID
	JOIN @tiCESPReceiveFileIDs CRFs ON CRFs.iCESPReceiveFileID = C9.iCESPReceiveFileID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = CRFs.iCESPReceiveFileID
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
	JOIN Un_CESPSendFile CSF ON CSF.iCESPSendFileID = C4.iCESPSendFileID
	WHERE C9.fCLBFee <> 0
	ORDER BY CRF.dtRead ASC, C.ConventionNo ASC
END

