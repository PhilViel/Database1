/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_CESPRegistrationCESP100
Description         :	Procédure qui sert au rapport de l'enregistrement de la convention au PCEE.
Valeurs de retours  :	Dataset de données
Note                :	2006-07-18	Mireya Gonthier 	Création  IA-ADX0001061		Convention\ Rapport\ 
												Enregistrement de la convention à la SCEE : 
												Adaptation pour PCEE 4.3														
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPRegistrationCESP100] (
	@ConventionID INTEGER)
AS
BEGIN
	CREATE TABLE #Convention (
		ConventionID INTEGER PRIMARY KEY
	) 

	INSERT INTO #Convention
	VALUES (@ConventionID)

	SELECT
		C.ConventionNo,
		B.iCESP100ID,
		B.ConventionID,
		B.vcTransID,
		SF.dtCESPSendFile,
		O.OperDate,
		siCESP800ErrorID = ISNULL(G8.siCESP800ErrorID,0),
		G8.vcErrFieldName
	FROM #Convention V
	JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID 
	JOIN Un_CESP100 B ON B.ConventionID = C.ConventionID
	JOIN Un_CESPSendFile SF ON SF.iCESPSendFileID = B.iCESPSendFileID
	LEFT JOIN Un_CESPReceiveFile RF ON SF.iCESPReceiveFileID = RF.iCESPReceiveFileID
	LEFT JOIN Un_Oper O ON O.OperID = RF.OperID
	LEFT JOIN Un_CESP800 G8 ON G8.iCESP800ID = B.iCESP800ID
	ORDER BY 
		C.ConventionNo, 
		B.ConventionID, 
		SF.dtCESPSendFile
END


