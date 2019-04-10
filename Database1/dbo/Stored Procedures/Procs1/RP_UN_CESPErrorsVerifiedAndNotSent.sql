/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_CESPErrorsVerifiedAndNotSent
Description         :	Renvoi les données pour le rapport des erreurs vérifiées non expédiées au PCEE.
Valeurs de retours  :	Dataset :
				dtCorrected		DATETIME	Date et heure de la correction
				dtRead			DATETIME	Date de réception du fichier d’erreur.
				vcTransID		VARCHAR(15)	ID PCEE
				ConventionNo		VARCHAR(75)	Numéro de convention.
				InForceDate		DATETIME	Date d’entré en vigueur du groupe d’unités
				UnitQty			MONEY		Nombre d’unités
				EffectDate		DATETIME	Date envoyé au PCEE pour la transaction. Correspond à la date effective. Dans le cas d’une opération sur la convention qui n’affecte pas un groupe d’unités (ex : PAE) elle correspondra à la date d’opération.
				OperType		CHAR(3)		Type d’opération
				ConventionStateName	VARCHAR(75)	État actuel de la convention
				vcErrFieldName		VARCHAR(30)	Champ en erreur
				siCESP800ErrorID	INTEGER		Code de l’erreur
				vcCESP800Error		VARCHAR(200)	Description de l’erreur
				
Note                :	ADX0001153	IA	2006-11-10	Alain Quirion		Création
                                        2008-12-15  Fatiha Araar        Ajouter les erreurs liées aux enregistrements 511
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_CESPErrorsVerifiedAndNotSent](
	@dtStart DATETIME,	-- Date de début
	@dtEnd DATETIME)	-- Date de fin
AS
BEGIN
	SELECT * FROM(	-- Va chercher les erreurs sur les 100
	SELECT
		dtCorrected = dbo.FN_CRQ_DateNoTime(C8C.dtCorrected),	
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),
		vcTransID = C8.vcTransID,		
		ConventionNo = C.ConventionNo,		
		InForceDate = NULL,		-- Ne peut déterminer le groupe d'unité
		UnitQty = NULL,			
		EffectDate = NULL,		
		OperType = NULL,		
		ConventionStateName = CCS.ConventionStateName,	
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error	
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP100 C1 ON C1.iCESP800ID = C8C.iCESP800ID
	JOIN dbo.Un_Convention C ON C.ConventionID = C1.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN (	SELECT 		
			T.ConventionID,
			CS.ConventionStateID,		
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID) CCS ON CCS.ConventionID = C.ConventionID	
	WHERE C8C.bCESP400Resend = 0
		AND dbo.FN_CRQ_DateNoTime(C8C.dtCorrected) BETWEEN @dtStart AND @dtEnd
	-----
	UNION -- Va chercher les erreurs sur les 200
	-----
	SELECT
		dtCorrected = dbo.FN_CRQ_DateNoTime(C8C.dtCorrected),	
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),
		vcTransID = C8.vcTransID,		
		ConventionNo = C.ConventionNo,		
		InForceDate = NULL,		-- Ne peut déterminer le groupe d'unité
		UnitQty = NULL,			
		EffectDate = NULL,		
		OperType = NULL,		
		ConventionStateName = CCS.ConventionStateName,	
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error	
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP200 C2 ON C2.iCESP800ID = C8.iCESP800ID
	JOIN dbo.Un_Convention C ON C.ConventionID = C2.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN (	SELECT 		
			T.ConventionID,
			CS.ConventionStateID,		
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID) CCS ON CCS.ConventionID = C.ConventionID	
	WHERE C8C.bCESP400Resend = 0
		AND dbo.FN_CRQ_DateNoTime(C8C.dtCorrected) BETWEEN @dtStart AND @dtEnd
	-----
	UNION -- Va chercher les erreurs sur les 400
	-----
	SELECT
		dtCorrected = dbo.FN_CRQ_DateNoTime(C8C.dtCorrected),	
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),
		vcTransID = C8.vcTransID,		
		ConventionNo = C.ConventionNo,		
		InForceDate = U.InforceDate,		
		UnitQty = U.UnitQty,			
		EffectDate = CT.EffectDate,		
		OperType = O.OperTypeID,		
		ConventionStateName = CCS.ConventionStateName,	
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error	
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP400 C4 ON C4.iCESP800ID = C8.iCESP800ID
	JOIN dbo.Un_Convention C ON C.ConventionID = C4.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN (	SELECT 		
			T.ConventionID,
			CS.ConventionStateID,		
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID) CCS ON CCS.ConventionID = C.ConventionID	
	JOIN Un_Cotisation CT ON CT.CotisationID = C4.CotisationID
	JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	JOIN Un_Oper O ON O.OperID = C4.OperID
	WHERE C8C.bCESP400Resend = 0
		AND dbo.FN_CRQ_DateNoTime(C8C.dtCorrected) BETWEEN @dtStart AND @dtEnd
    -----
	UNION -- Va chercher les erreurs sur les 511
	-----
	SELECT
		dtCorrected = dbo.FN_CRQ_DateNoTime(C8C.dtCorrected),	
		dtRead = dbo.FN_CRQ_DateNoTime(CRF.dtRead),
		vcTransID = C8.vcTransID,		
		ConventionNo = C.ConventionNo,		
		InForceDate = null,		
		UnitQty = 0,			
		EffectDate = null,		
		OperType = null,		
		ConventionStateName = CCS.ConventionStateName,	
		vcErrFieldName = C8.vcErrFieldName,
		siCESP800ErrorID = C8.siCESP800ErrorID,
		vcCESP800Error = C8E.vcCESP800Error	
	FROM Un_CESP800Corrected C8C
	JOIN Un_CESP800 C8 ON C8.iCESP800ID = C8C.iCESP800ID
	JOIN Un_CESP800Error C8E ON C8E.siCESP800ErrorID = C8.siCESP800ErrorID
	JOIN Un_CESP511 C5 ON C5.iCESP800ID = C8.iCESP800ID
	JOIN dbo.Un_Convention C ON C.ConventionID = C5.ConventionID
	JOIN Un_CESPReceiveFile CRF ON CRF.iCESPReceiveFileID = C8.iCESPReceiveFileID
	JOIN (	SELECT 		
			T.ConventionID,
			CS.ConventionStateID,		
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				S.ConventionID,
				MaxDate = MAX(S.StartDate)
			FROM Un_ConventionConventionState S
			JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
			WHERE S.StartDate <= GETDATE()
			GROUP BY S.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID) CCS ON CCS.ConventionID = C.ConventionID	
	WHERE C8C.bCESP400Resend = 0
		AND dbo.FN_CRQ_DateNoTime(C8C.dtCorrected) BETWEEN @dtStart AND @dtEnd) U
	ORDER BY 1, 2, 4, 6, 8, 7
END


