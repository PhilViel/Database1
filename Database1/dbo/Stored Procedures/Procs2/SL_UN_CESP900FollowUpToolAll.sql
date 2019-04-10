/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP900FollowUpToolAll
Description         :	Renvoi les données pour l’outil de traitement des erreurs sur 400.
Valeurs de retours  :	Dataset :
							vcList				VARCHAR(100)	Nom de la liste
							vcItem				VARCHAR(100)	Description de l'item							
							iCESP900ID			INTEGER			ID de l’enregistrement 900
							iCESP400ID			INTEGER			ID de l’enregistrement 400
							vcVerifiedUser		VARCHAR(87)		Non de l’usager qui a vérifié cet enregistrement.
							dtVerified			DATETIME		Date et heure auxquelles la vérification a été faite.
							bCESP400Resend		BIT				Indique si l’enregistrement 400 a été renvoyé au PCEE.
							vcTransID			VARCHAR(15)		ID PCEE
							ConventionID		INTEGER			ID de la convention
							ConventionNo		VARCHAR(75)		Numéro de convention.
							ConventionStateName	VARCHAR(75)		État actuel de la convention
							SubscriberID		INTEGER			ID du souscripteur
							BeneficiaryID		INTEGER			ID du bénéficiaire
							UnitID				INTEGER			ID du groupe d’unités
							InForceDate			DATETIME		Date d’entré en vigueur du groupe d’unités
							UnitQty				MONEY			Nombre d’unités
							EffectDate			DATETIME		Date envoyé au PCEE pour la transaction. Correspond à la date effective. Dans le cas d’une opération sur la convention qui n’affecte pas un groupe d’unités (ex : PAE) elle correspondra à la date d’opération.
							OperType			CHAR(3)			Type d’opération
							dtCESPSendFile		DATETIME		Date d’envoi du fichier qui contenait la 400 lié à de cette 900.
							fCESGPlanned		MONEY			Montant de SCEE prévue (20%)
							fCESG				MONEY			SCEE reçue.
							fACESG				MONEY			SCEE+ reçue.
							fCLB				MONEY			BEC reçu.
							tiCESP900OriginID	TINYINT			ID de l’origine
							vcCESP900Origin		VARCHAR(200)	Origine de la transaction 900

Note                :	ADX0002678	UR	2007-04-03	Alain Quirion		Création
								ADX0002493	BR	2007-06-14	Bruno Lapointe		fCESGPlanned ne retournait pas la bonne valeur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP900FollowUpToolAll](
	@iCESPReceiveFileID INTEGER)		-- ID du fichier reçu
AS
BEGIN
	CREATE TABLE #tGlobalFollowUp(
		vcList VARCHAR(100),			--Nom de la liste
		vcDetailID VARCHAR(5),			--ID de l'item
		vcItem VARCHAR(100),			--Description de l'item							
		iCESP900ID INTEGER,				--ID de l’enregistrement 900
		iCESP400ID INTEGER,				--ID de l’enregistrement 400
		vcVerifiedUser VARCHAR(87),		--Non de l’usager qui a vérifié cet enregistrement.
		dtVerified DATETIME,			--Date et heure auxquelles la vérification a été faite.
		bCESP400Resend BIT,				--Indique si l’enregistrement 400 a été renvoyé au PCEE.
		vcTransID VARCHAR(15),			--ID PCEE
		ConventionID INTEGER,			--ID de la convention
		ConventionNo VARCHAR(75),		--Numéro de convention.
		ConventionStateName VARCHAR(75),	--État actuel de la convention
		SubscriberID INTEGER,				--ID du souscripteur
		BeneficiaryID INTEGER,			--ID du bénéficiaire
		UnitID INTEGER,					--ID du groupe d’unités
		InForceDate DATETIME,			--Date d’entré en vigueur du groupe d’unités
		UnitQty MONEY,					--Nombre d’unités
		EffectDate DATETIME,			--Date envoyé au PCEE pour la transaction. Correspond à la date effective. Dans le cas d’une opération sur la convention qui n’affecte pas un groupe d’unités (ex : PAE) elle correspondra à la date d’opération.
		OperType CHAR(3),				--Type d’opération
		dtCESPSendFile DATETIME,		--Date d’envoi du fichier qui contenait la 400 lié à de cette 900.
		fCESGPlanned MONEY,				--Montant de SCEE prévue (20%)
		fCESG MONEY,					--SCEE reçue.
		fACESG MONEY,					--SCEE+ reçue.
		fCLB MONEY,						--BEC reçu.
		tiCESP900OriginID TINYINT,		--ID de l’origine
		vcCESP900Origin VARCHAR(200),	--Origine de la transaction 900)
		vcCESP900CESGReason VARCHAR(200), --Raison de non paiuement SCEE et BEC
		vcCESP900ACESGReason VARCHAR(200)) --Raison de non paiuement SCEE+

	CREATE TABLE #tConventionState (
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateID CHAR(3),
		ConventionStateName VARCHAR(75))

	INSERT INTO #tConventionState
		SELECT 		
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
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID

	INSERT INTO #tGlobalFollowUp
	SELECT
		vcList = 'Origine de transaction',
		vcDetailID = CAST(C9.tiCESP900OriginID AS VARCHAR(5)),
		vcItem = C9O.vcCESP900Origin,
		iCESP900ID = C9.iCESP900ID,	
		iCESP400ID = C4.iCESP400ID,		
		vcVerifiedUser = ISNULL(H.FirstName,'') + ' ' + ISNULL(H.LastName,''),		
		dtVerified = C9V.dtVerified,		
		bCESP400Resend = ISNULL(C9V.bCESP400Resend,0),	
		vcTransID = C9.vcTransID,		
		ConventionID = C.ConventionID,		
		ConventionNo = C.ConventionNo,		
		ConventionStateName = CCS.ConventionStateName,	
		SubscriberID = C.SubscriberID,		
		BeneficiaryID = C.BeneficiaryID,		
		UnitID = U.UnitID,			
		InForceDate = U.InForceDate,		
		UnitQty = ISNULL(U.UnitQty,0),			
		EffectDate = CT.EffectDate,		
		OperType = ISNULL(O.OperTypeID,''),	
		dtCESPSendFile = CSF.dtCESPSendFile,		
		fCESGPlanned = 
			CASE
				WHEN C4.tiCESP400TypeID = 11 THEN C4.fCotisation * 0.2
			ELSE 0
			END,
		fCESG = C9.fCESG,			
		fACESG = C9.fACESG,			
		fCLB = C9.fCLB,			
		tiCESP900OriginID = C9.tiCESP900OriginID,	
		vcCESP900Origin	= C9O.vcCESP900Origin,
		vcCESP900CESGReason = ISNULL(C9CR.vcCESP900CESGReason,''),
		vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,'')
	FROM Un_CESP900 C9
	LEFT JOIN Un_CESP900Verified C9V ON C9.iCESP900ID = C9V.iCESP900ID
	JOIN Un_CESP900Origin C9O ON C9O.tiCESP900OriginID = C9.tiCESP900OriginID
	LEFT JOIN Un_CESP900ACESGReason C9AR ON C9.cCESP900ACESGReasonID = C9AR.cCESP900ACESGReasonID
	LEFT JOIN Un_CESP900CESGReason C9CR ON C9.cCESP900CESGReasonID = C9CR.cCESP900CESGReasonID
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
	JOIN dbo.Un_Convention C ON C4.ConventionID = C.ConventionID
	LEFT JOIN Mo_Connect CO ON CO.ConnectID = C9V.iVerifiedConnectID
	LEFT JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
	LEFT JOIN Un_Cotisation CT ON CT.CotisationID = C4.CotisationID
	LEFT JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	LEFT JOIN Un_Oper O ON O.OperID = C4.OperID
	JOIN Un_CESPSendFile CSF ON CSF.iCESPSendFileID = C4.iCESPSendFileID
	JOIN #tConventionState CCS ON CCS.ConventionID = C.ConventionID	
	WHERE @iCESPReceiveFileID = C9.iCESPReceiveFileID
	
	INSERT INTO #tGlobalFollowUp
	SELECT
		vcList = 'Raisons de non-paiement SCEE et BEC',
		vcDetailID = C9.cCESP900CESGReasonID,
		vcItem = C9CR.vcCESP900CESGReason,
		iCESP900ID = C9.iCESP900ID,	
		iCESP400ID = C4.iCESP400ID,		
		vcVerifiedUser = ISNULL(H.FirstName,'') + ' ' + ISNULL(H.LastName,''),		
		dtVerified = C9V.dtVerified,		
		bCESP400Resend = ISNULL(C9V.bCESP400Resend,0),	
		vcTransID = C9.vcTransID,		
		ConventionID = C.ConventionID,		
		ConventionNo = C.ConventionNo,		
		ConventionStateName = CCS.ConventionStateName,	
		SubscriberID = C.SubscriberID,		
		BeneficiaryID = C.BeneficiaryID,		
		UnitID = U.UnitID,			
		InForceDate = U.InForceDate,		
		UnitQty = ISNULL(U.UnitQty,0),			
		EffectDate = CT.EffectDate,		
		OperType = ISNULL(O.OperTypeID,''),			
		dtCESPSendFile = CSF.dtCESPSendFile,		
		fCESGPlanned = 
			CASE
				WHEN C4.tiCESP400TypeID = 11 THEN C4.fCotisation * 0.2
			ELSE 0
			END,
		fCESG = C9.fCESG,			
		fACESG = C9.fACESG,			
		fCLB = C9.fCLB,			
		tiCESP900OriginID = C9.tiCESP900OriginID,	
		vcCESP900Origin	= C9O.vcCESP900Origin,
		vcCESP900CESGReason = ISNULL(C9CR.vcCESP900CESGReason,''),
		vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,'')
	FROM Un_CESP900 C9
	LEFT JOIN Un_CESP900Verified C9V ON C9.iCESP900ID = C9V.iCESP900ID
	JOIN Un_CESP900Origin C9O ON C9O.tiCESP900OriginID = C9.tiCESP900OriginID
	LEFT JOIN Un_CESP900ACESGReason C9AR ON C9.cCESP900ACESGReasonID = C9AR.cCESP900ACESGReasonID
	LEFT JOIN Un_CESP900CESGReason C9CR ON C9.cCESP900CESGReasonID = C9CR.cCESP900CESGReasonID
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
	JOIN dbo.Un_Convention C ON C4.ConventionID = C.ConventionID
	LEFT JOIN Mo_Connect CO ON CO.ConnectID = C9V.iVerifiedConnectID
	LEFT JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
	LEFT JOIN Un_Cotisation CT ON CT.CotisationID = C4.CotisationID
	LEFT JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	LEFT JOIN Un_Oper O ON O.OperID = C4.OperID
	JOIN Un_CESPSendFile CSF ON CSF.iCESPSendFileID = C4.iCESPSendFileID
	JOIN #tConventionState CCS ON CCS.ConventionID = C.ConventionID	
	WHERE @iCESPReceiveFileID = C9.iCESPReceiveFileID		
	
	INSERT INTO #tGlobalFollowUp
	SELECT
		vcList = 'Raisons de non-paiement SCEE+',
		vcDetailID = C9.cCESP900ACESGReasonID,
		vcItem = C9AR.vcCESP900ACESGReason,
		iCESP900ID = C9.iCESP900ID,	
		iCESP400ID = C4.iCESP400ID,		
		vcVerifiedUser = ISNULL(H.FirstName,'') + ' ' + ISNULL(H.LastName,''),		
		dtVerified = C9V.dtVerified,		
		bCESP400Resend = ISNULL(C9V.bCESP400Resend,0),	
		vcTransID = C9.vcTransID,		
		ConventionID = C.ConventionID,		
		ConventionNo = C.ConventionNo,		
		ConventionStateName = CCS.ConventionStateName,	
		SubscriberID = C.SubscriberID,		
		BeneficiaryID = C.BeneficiaryID,		
		UnitID = U.UnitID,			
		InForceDate = U.InForceDate,		
		UnitQty = ISNULL(U.UnitQty,0),			
		EffectDate = CT.EffectDate,		
		OperType = ISNULL(O.OperTypeID,''),			
		dtCESPSendFile = CSF.dtCESPSendFile,		
		fCESGPlanned = 
			CASE
				WHEN C4.tiCESP400TypeID = 11 THEN C4.fCotisation * 0.2
			ELSE 0
			END,
		fCESG = C9.fCESG,			
		fACESG = C9.fACESG,			
		fCLB = C9.fCLB,			
		tiCESP900OriginID = C9.tiCESP900OriginID,	
		vcCESP900Origin	= C9O.vcCESP900Origin,
		vcCESP900CESGReason = ISNULL(C9CR.vcCESP900CESGReason,''),
		vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,'')
	FROM Un_CESP900 C9
	LEFT JOIN Un_CESP900Verified C9V ON C9.iCESP900ID = C9V.iCESP900ID
	JOIN Un_CESP900Origin C9O ON C9O.tiCESP900OriginID = C9.tiCESP900OriginID
	LEFT JOIN Un_CESP900ACESGReason C9AR ON C9.cCESP900ACESGReasonID = C9AR.cCESP900ACESGReasonID
	LEFT JOIN Un_CESP900CESGReason C9CR ON C9.cCESP900CESGReasonID = C9CR.cCESP900CESGReasonID
	JOIN Un_CESP400 C4 ON C4.iCESP400ID = C9.iCESP400ID
	JOIN dbo.Un_Convention C ON C4.ConventionID = C.ConventionID
	LEFT JOIN Mo_Connect CO ON CO.ConnectID = C9V.iVerifiedConnectID
	LEFT JOIN dbo.Mo_Human H ON H.HumanID = CO.UserID
	LEFT JOIN Un_Cotisation CT ON CT.CotisationID = C4.CotisationID
	LEFT JOIN dbo.Un_Unit U ON U.UnitID = CT.UnitID
	LEFT JOIN Un_Oper O ON O.OperID = C4.OperID
	JOIN Un_CESPSendFile CSF ON CSF.iCESPSendFileID = C4.iCESPSendFileID
	JOIN #tConventionState CCS ON CCS.ConventionID = C.ConventionID	
	WHERE @iCESPReceiveFileID = C9.iCESPReceiveFileID
	
	SELECT * 
	FROM #tGlobalFollowUp
	ORDER BY vcList, vcDetailID, ConventionNo, UnitID, EffectDate, OperType, vcTransID
END


