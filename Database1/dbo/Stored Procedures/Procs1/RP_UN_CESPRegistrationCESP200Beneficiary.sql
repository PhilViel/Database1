/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_CESPRegistrationCESP200Beneficiary
Description         :	Procédure qui sert au rapport de l'enregistrement de la convention au PCEE.
Valeurs de retours  :	Dataset de données
Note                :	2006-07-18	Mireya Gonthier 	Création  IA-ADX0001061		Convention\ Rapport\ 
												Enregistrement de la convention à la SCEE : 
												Adaptation pour PCEE 4.3				
						2015-02-13	Pierre-Luc Simard	Afficher aussi les 200 créés et non-envoyés et indiquer la statut											
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPRegistrationCESP200Beneficiary] (
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
		B.iCESP200ID,
		B.ConventionID,
		B.HumanID,
		B.vcTransID,
		SF.dtCESPSendFile,
		O.OperDate,
		siCESP800ErrorID = CASE WHEN B.iCESPSendFileID IS NULL OR RF.iCESPReceiveFileID IS NULL THEN -1 ELSE ISNULL(G8.siCESP800ErrorID,0) END,
		vcErrFieldName =	CASE WHEN B.iCESPSendFileID IS NULL 
									THEN 'Demande à envoyer' 
									ELSE
										CASE WHEN RF.iCESPReceiveFileID IS NULL 
										THEN 'Réponse à recevoir' 
										ELSE ISNULL( G8.vcErrFieldName, '')
										END  
									END,
		SocialNumber = 
			CAST(
					CASE 
						WHEN G8.vcErrFieldName IN ('SIN','NAS') AND G8.tyCESP800SINID <> 1 THEN 1
					ELSE 0
					END AS BIT),
		FirstName = 
			CAST(
					CASE 
						WHEN G8.vcErrFieldName IN ('SIN','NAS') AND G8.bFirstName <> 1 THEN 1
					ELSE 0
					END AS BIT),
		LastName = 
			CAST(
					CASE 
						WHEN G8.vcErrFieldName IN ('SIN','NAS') AND G8.bLastName <> 1 THEN 1
					ELSE 0
					END AS BIT),
		BirthDate = 
			CAST(
					CASE 
						WHEN G8.vcErrFieldName IN ('SIN','NAS') AND G8.bBirthDate <> 1 THEN 1
					ELSE 0
					END AS BIT),
		SexID = 
			CAST(
					CASE 
						WHEN G8.vcErrFieldName IN ('SIN','NAS') AND G8.bSex <> 1 THEN 1
					ELSE 0
					END AS BIT)
	FROM #Convention V
	JOIN dbo.Un_Convention C ON V.ConventionID = C.ConventionID
	JOIN Un_CESP200 B ON B.ConventionID = C.ConventionID AND C.BeneficiaryID = B.HumanID
	LEFT JOIN Un_CESPSendFile SF ON SF.iCESPSendFileID = B.iCESPSendFileID
	LEFT JOIN Un_CESPReceiveFile RF ON SF.iCESPReceiveFileID = RF.iCESPReceiveFileID
	LEFT JOIN Un_Oper O ON O.OperID = RF.OperID
	LEFT JOIN Un_CESP800 G8 ON G8.iCESP800ID = B.iCESP800ID
	ORDER BY 
		C.ConventionNo, 
		B.ConventionID, 
		ISNULL(SF.dtCESPSendFile, '2099-01-01')
END


