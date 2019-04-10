/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESP900FollowUpTool
Description         :	Renvoi les données pour l’outil de traitement des erreurs sur 400.

Exemple d'appel		:
			EXECUTE [dbo].[SL_UN_CESP900FollowUpTool]
													NULL,		-- ID du fichier reçu
													-1,			-- ID de l’origine (-1 = non utilisé)
													'',			-- ID de la raison SCEE ('' = non utilisé)
													''

Valeurs de retours  :	Dataset :
			iCESP900ID		INTEGER		ID de l’enregistrement 900
			iCESP400ID		INTEGER		ID de l’enregistrement 400
			vcVerifiedUser		VARCHAR(87)	Non de l’usager qui a vérifié cet enregistrement.
			dtVerified		DATETIME	Date et heure auxquelles la vérification a été faite.
			bCESP400Resend		BIT		Indique si l’enregistrement 400 a été renvoyé au PCEE.
			vcTransID		VARCHAR(15)	ID PCEE
			ConventionID		INTEGER		ID de la convention
			ConventionNo		VARCHAR(75)	Numéro de convention.
			ConventionStateName	VARCHAR(75)	État actuel de la convention
			SubscriberID		INTEGER		ID du souscripteur
			BeneficiaryID		INTEGER		ID du bénéficiaire
			UnitID			INTEGER		ID du groupe d’unités
			InForceDate		DATETIME	Date d’entré en vigueur du groupe d’unités
			UnitQty			MONEY		Nombre d’unités
			EffectDate		DATETIME	Date envoyé au PCEE pour la transaction. Correspond à la date effective. Dans le cas d’une opération sur la convention qui n’affecte pas un groupe d’unités (ex : PAE) elle correspondra à la date d’opération.
			OperType		CHAR(3)		Type d’opération
			dtCESPSendFile		DATETIME	Date d’envoi du fichier qui contenait la 400 lié à de cette 900.
			fCESGPlanned		MONEY		Montant de SCEE prévue (20%)
			fCESG			MONEY		SCEE reçue.
			fACESG			MONEY		SCEE+ reçue.
			fCLB			MONEY		BEC reçu.
			tiCESP900OriginID	TINYINT		ID de l’origine
			vcCESP900Origin		VARCHAR(200)	Origine de la transaction 900

Note                :	ADX0001153	IA	2006-11-10	Alain Quirion		Création
								ADX0002327	BR	2007-03-07	Alain Quirion			Optimisation
								ADX0002493	BR	2007-06-14	Bruno Lapointe			fCESGPlanned ne retournait pas la bonne valeur
												2010-03-25	Jean-François Gauthier	Ajout des 2 champs contenant le NAS du bénéficiaire actif 
																					et celui provenant du PCEE
												2010-11-22	Jean-Francois Arial		Ajuster les paramètres lors de l'appel àmla fonction fntConv_RechercherChangementsBeneficiaire
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESP900FollowUpTool](
	@iCESPReceiveFileID INTEGER,		-- ID du fichier reçu
	@tiCESP900OriginID INT,			-- ID de l’origine (-1 = non utilisé)
	@cCESP900CESGReasonID CHAR(1),		-- ID de la raison SCEE ('' = non utilisé)
	@cCESP900ACESGReasonID CHAR(1))	-- ID de la raison SCEE+ ('' = non utilisé)	
AS
BEGIN
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

	IF @tiCESP900OriginID <> -1
	BEGIN
		SELECT
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
			vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,''),
			-- 2010-03-25 : JFG : Ajout des 2 champs concernant le NAS
			vcNASBeneficiaireActif	=	(	SELECT hu.SocialNumber 
											FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, C.ConventionID, NULL, CT.EffectDate, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL) f
												 INNER JOIN dbo.Mo_Human hu
													ON hu.HumanID = f.iID_Nouveau_Beneficiaire)
			,vcNASPCEE				=	CASE	WHEN C9.tiCESP900OriginID = 5 THEN C9.vcBeneficiarySIN
												ELSE ''
										END
		FROM 
			Un_CESP900 C9
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
		WHERE 
			@iCESPReceiveFileID = C9.iCESPReceiveFileID
			AND 
			@tiCESP900OriginID = C9.tiCESP900OriginID		
		ORDER BY 
			C.ConventionNo, U.UnitID, CT.EffectDate, O.OperTypeID, C9.vcTransID
	END
	ELSE IF @cCESP900CESGReasonID <> ' '
	BEGIN
		SELECT
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
			vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,''),
			-- 2010-03-25 : JFG : Ajout des 2 champs concernant le NAS
			vcNASBeneficiaireActif	=	(	SELECT DISTINCT hu.SocialNumber 
											FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, C.ConventionID, NULL, CT.EffectDate, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL) f
												 INNER JOIN dbo.Mo_Human hu
													ON hu.HumanID = f.iID_Nouveau_Beneficiaire)
			,vcNASPCEE				=	CASE	WHEN C9.tiCESP900OriginID = 5 THEN C9.vcBeneficiarySIN
												ELSE ''
										END
		FROM 
			Un_CESP900 C9
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
		WHERE 
			@iCESPReceiveFileID = C9.iCESPReceiveFileID
			AND 
			@cCESP900CESGReasonID = C9.cCESP900CESGReasonID			
		ORDER BY 
			C.ConventionNo, U.UnitID, CT.EffectDate, O.OperTypeID, C9.vcTransID
	END
	ELSE IF @cCESP900ACESGReasonID <> ' '
	BEGIN
		SELECT
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
			vcCESP900ACESGReason = ISNULL(C9AR.vcCESP900ACESGReason,''),
			-- 2010-03-25 : JFG : Ajout des 2 champs concernant le NAS
			vcNASBeneficiaireActif	=	(	SELECT hu.SocialNumber 
											FROM dbo.fntCONV_RechercherChangementsBeneficiaire(NULL, NULL, C.ConventionID, NULL, CT.EffectDate, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL) f
												 INNER JOIN dbo.Mo_Human hu
													ON hu.HumanID = f.iID_Nouveau_Beneficiaire)
			,vcNASPCEE				=	CASE	WHEN C9.tiCESP900OriginID = 5 THEN C9.vcBeneficiarySIN
												ELSE ''
										END
		FROM 
			Un_CESP900 C9
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
		WHERE 
			@iCESPReceiveFileID = C9.iCESPReceiveFileID
			AND 
			@cCESP900ACESGReasonID = C9.cCESP900ACESGReasonID	
		ORDER BY 
			C.ConventionNo, U.UnitID, CT.EffectDate, O.OperTypeID, C9.vcTransID
	END
END


