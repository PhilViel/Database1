/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPSendFiles
Description         :	Retourne la liste des fichiers d'envois du PCEE.
Valeurs de retours  :	Dataset :
									iCESPSendFileID		INTEGER		ID du fichier d’envoi au PCEE.
									vcCESPSendFile			VARCHAR(75)	Nom du fichier d’envoi au PCEE.
									dtCESPSendFile			DATETIME		Date d’envoi du fichier au PCEE.
									iCESPReceiveFileID	INTEGER		ID du fichier de retour correspondant à ce fichier d’envoi.
Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPSendFiles]
AS
BEGIN
	SELECT
		iCESPSendFileID, -- ID du fichier d’envoi au PCEE.
		vcCESPSendFile, -- Nom du fichier d’envoi au PCEE.
		dtCESPSendFile, -- Date d’envoi du fichier au PCEE.
		iCESPReceiveFileID -- ID du fichier de retour correspondant à ce fichier d’envoi.
	FROM Un_CESPSendFile
	ORDER BY dtCESPSendFile DESC
END

