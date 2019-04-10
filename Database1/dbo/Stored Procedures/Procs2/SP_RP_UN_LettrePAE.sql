/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc
Nom                 :	SP_RP_UN_LettrePAE
Description         :	Régime Individuel – lettre PAE
Valeurs de retours  :	
GLPI	2011-10-11	Eric Michaud		Création
		2012-02-21	Eric Michaud		Ajout de IST dans rendement TIN
		2012-11-30	Donald Huppé		GLPI 8654 Ajout de BeneficiaryID
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_LettrePAE] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ConventionID INTEGER, -- ID de la convention  
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN

	DECLARE 
		@Today DATETIME,
		@DocTypeID INTEGER,
		@UserName VARCHAR(77)

	SET @Today = GetDate()	

	-- Table temporaire qui contient l'information
	CREATE TABLE #Lettre(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		ConventionNo VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCity VARCHAR(100),
		BeneficiaryState VARCHAR(75),
		BeneficiaryZipCode VARCHAR(75),
		SubscriberFirstName VARCHAR(35),
		SubscriberLastName VARCHAR(50),
		LetterMedDate VARCHAR(75),
		BeneficiaryShortSexName VARCHAR(75),
		BeneficiaryLongSexName VARCHAR(75),
		ChequeAmount VARCHAR(20),
		PAE VARCHAR(20),
		SCEE VARCHAR(20),
		IntSCEE VARCHAR(20),
		IQEE VARCHAR(20),
		IntIQEE VARCHAR(20),
		Total VARCHAR(20),
		LettrePAESCEETXT1 VARCHAR(200),
		LettrePAEIQEETXT1 VARCHAR(200),
		BeneficiaryID INTEGER
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'LettrePAE'

	SELECT 
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE (Co.ConnectID = @ConnectID);

	-- Remplis la table temporaire
	INSERT INTO #Lettre
		SELECT
			T.DocTemplateID,
			BH.LangID,
			ConventionNO = LTRIM(RTRIM(C.ConventionNo)),
			BeneficiaryFirstName = RTRIM(BH.FirstName),
			BeneficiaryLastName = RTRIM(BH.LastName),
			BeneficiaryAddress = RTRIM(A.Address),
			BeneficiaryCity = ISNULL(RTRIM(A.City),''),
			BeneficiaryState = ISNULL(RTRIM(A.StateName),''),
			BeneficiaryZipCode = dbo.fn_Mo_FormatZip(IsNULL(A.ZipCode,''), A.CountryID),
			SubscriberFirstName = RTRIM(SH.FirstName),
			SubscriberLastName = RTRIM(SH.LastName),
			LetterMedDate = dbo.fn_mo_DateToLongDateStr(GetDate(), BH.LangID),
			BeneficiaryShortSexName = X.ShortSexName,
			BeneficiaryLongSexName = X.LongSexName,
			ChequeAmount = dbo.fn_Mo_MoneyToStr(CH.fAmount, BH.LangID , 1),
			PAE =		CASE WHEN ( IsNULL(INM.InterestOnSubscribedAmount,0) <> 0) THEN
							dbo.fn_Mo_MoneyToStr(ABS(INM.InterestOnSubscribedAmount)+ ABS(RendTin) , BH.LangID , 1) 
						ELSE
							dbo.fn_Mo_MoneyToStr(ABS(0.00), BH.LangID , 1) 
						END,
			SCEE =		CASE WHEN IsNULL(GG.fCESG,0) <> 0 THEN
							dbo.fn_Mo_MoneyToStr(ABS(GG.fCESG), BH.LangID , 1)
						ELSE
							dbo.fn_Mo_MoneyToStr(ABS(0.00), BH.LangID , 1) 
						END,
			IntSCEE =	CASE WHEN IsNULL(INS.fCESGInt,0) <> 0 THEN
							dbo.fn_Mo_MoneyToStr(ABS(INS.fCESGInt), BH.LangID , 1) 
						ELSE
							dbo.fn_Mo_MoneyToStr(ABS(0.00), BH.LangID , 1) 
						END,
			IQEE =		CASE WHEN (ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.IQEEMaj,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0) <> 0) THEN
							dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.IQEEMaj,0)), BH.LangID , 1) 
						ELSE
							dbo.fn_Mo_MoneyToStr(ABS(0.00), BH.LangID , 1) 
						END,
			IntIQEE  =	CASE WHEN (ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) <> 0 THEN
							dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)), BH.LangID , 1) 
						ELSE
							dbo.fn_Mo_MoneyToStr(ABS(0.00), BH.LangID , 1) 
						END,
			Total = dbo.fn_Mo_MoneyToStr(CH.fAmount, BH.LangID , 1),
			LettrePAESCEETXT1 =	CASE WHEN IsNULL(GG.fCESG,0) <> 0 THEN
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettrePAESCEETXT1' AND P.vcDimension1 = BH.LangID)
								END,
			LettrePAEIQEETXT1 = CASE WHEN (ISNULL(IQEE.IQEE,0) <> 0) THEN			
									(SELECT vcValeur_Parametre
										FROM tblGENE_TypesParametre T
										JOIN tblGENE_Parametres P ON T.iID_Type_Parametre = P.iID_Type_Parametre
										WHERE vcCode_Type_Parametre = 'LettrePAEIQEETXT1' AND P.vcDimension1 = BH.LangID)
								END,
			C.BeneficiaryID
		FROM Un_Scholarship S
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID	
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN (
			SELECT 
				ConventionID, 
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) N ON N.ConventionID = C.ConventionID
		LEFT JOIN Un_Plan P ON P.PlanID = C.PlanID
		LEFT JOIN Un_PlanValues V ON V.PlanID = P.PlanID AND V.ScholarshipNo = S.ScholarshipNo
		JOIN dbo.Mo_Human BH ON BH.HumanID = C.BeneficiaryID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		JOIN Mo_Sex X ON X.SexID = BH.SexID AND X.LangID = BH.LangID
		JOIN (
			SELECT 
				C.ConventionID, 
				UnitQty = SUM(U.UnitQty)
			FROM dbo.Un_Convention C 
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			GROUP BY C.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
		JOIN Un_ScholarshipPmt M ON M.ScholarshipID = S.ScholarshipID
		JOIN Un_Oper O ON O.OperID = M.OperID AND O.OperTypeID = 'PAE'  AND datediff(dd,@today,O.OperDate) >= 0 
		JOIN (
			SELECT 
				L.OperID,
				SP.ScholarshipID,
				fAmount = SUM(OD.fAmount)
			FROM Un_ScholarshipPmt SP
			JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
			JOIN CHQ_Operation O ON O.iOperationID = L.iOperationID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = O.iOperationID AND OD.vcAccount = O.vcAccount
			GROUP BY L.OperID,SP.ScholarshipID
			) CH ON CH.OperID = O.OperID AND CH.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				AdvanceAmount = ISNULL(SUM(C.ConventionOperAmount),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID		
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.ConventionOperTypeID = 'AVC'
			GROUP BY O.OperID,ScholarshipID
			) AV ON (AV.OperID = O.OperID AND AV.ScholarshipID = S.ScholarshipID)
		LEFT JOIN (
			SELECT
				OperID = MIN(O.OperID),
				fCESG = SUM(CE.fCESG)+SUM(CE.fACESG),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_CESP CE ON O.OperID = CE.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			GROUP BY O.OperID,ScholarshipID
			) GG ON GG.OperID = O.OperID AND GG.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				fCESGInt = ISNULL(SUM(C.ConventionOperAmount),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.ConventionOperTypeID IN ('INS', 'IS+')
			GROUP BY O.OperID,ScholarshipID
			) INS ON INS.OperID = O.OperID AND INS.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				fCESGIntTIN = ISNULL(SUM(C.ConventionOperAmount),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.ConventionOperTypeID = 'IST'
			GROUP BY O.OperID,ScholarshipID
			) IST ON IST.OperID = O.OperID AND IST.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				InterestOnSubscribedAmount = ISNULL(SUM(C.ConventionOperAmount),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.ConventionOperTypeID = 'INM'
			GROUP BY O.OperID,ScholarshipID
			) INM ON INM.OperID = O.OperID AND INM.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				TrINInterestAmount = ISNULL(SUM(C.ConventionOperAmount),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.ConventionOperTypeID = 'ITR'
			GROUP BY O.OperID,ScholarshipID
			) ITR ON ITR.OperID = O.OperID AND ITR.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				CollectiveInterestAmount = ISNULL(SUM(ISNULL(C.PlanOperAmount,0)),0),
				ScholarshipID = P.ScholarshipID				
			FROM Un_Oper O
			JOIN Un_PlanOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.PlanOperTypeID = 'INC'
			GROUP BY O.OperID,ScholarshipID
			) INC ON INC.OperID = O.OperID AND INC.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				OperID = ISNULL(MIN(O.OperID),0),
				CollectiveGrantAmount = ISNULL(SUM(ISNULL(C.PlanOperAmount,0)),0),
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_PlanOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			WHERE C.PlanOperTypeID = 'SUC'
			GROUP BY O.OperID,ScholarshipID
			) SUC ON SUC.OperID = O.OperID AND SUC.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT 
				OperID = ISNULL(MIN(O.OperID),0),
				IQEE = SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') = 'CBQ' THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEE = SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') IN ('ICQ', 'MIM', 'IIQ') THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),
				IQEEMaj = SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') = 'MMQ' THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEEMaj	= SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') = 'IMQ' THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendIQEETin	= SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') IN ('III', 'IQI') THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),
				RendTin	= SUM (
					CASE
						WHEN ISNULL(C.ConventionOperTypeID,'') IN ('ITR','IST') THEN ISNULL(C.ConventionOperAmount,0)
					ELSE 0
					END
					),					
				ScholarshipID = P.ScholarshipID
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			GROUP BY O.OperID,ScholarshipID
			) IQEE ON IQEE.OperID = O.OperID AND IQEE.ScholarshipID = S.ScholarshipID	
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)--@DocTypeID
			  AND (DocTemplateTime < @Today) --@Today
			GROUP BY LangID, DocTypeID
			) VT ON (VT.LangID = BH.LangID)
		JOIN CRQ_DocTemplate T ON (VT.DocTypeID = T.DocTypeID) AND (VT.DocTemplateTime = T.DocTemplateTime) AND (T.LangID = BH.LangID)
		WHERE (C.ConventionID = @ConventionID)
			AND B.bAddressLost = 0 
			AND O.OperID NOT IN(SELECT OperSourceID FROM Un_OperCancelation) -- Pas annulé
			
	-- Gestion des documents
	IF @DocAction IN (0,2)
	BEGIN

		-- Crée le document dans la gestion des documents
		INSERT INTO CRQ_Doc (DocTemplateID, DocOrderConnectID, DocOrderTime, DocGroup1, DocGroup2, DocGroup3, Doc)
			SELECT 
				DocTemplateID,
				@ConnectID,
				@Today,
				ISNULL(ConventionNo,''),
				ISNULL(SubscriberLastName,'')+', '+ISNULL(SubscriberFirstName,''),
				ISNULL(BeneficiaryLastName,'')+', '+ISNULL(BeneficiaryFirstName,''),
				ISNULL(LangID,'')+';'+
				ISNULL(ConventionNo,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCity,'')+';'+
				ISNULL(BeneficiaryState,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'+
				ISNULL(SubscriberFirstName,'')+';'+
				ISNULL(SubscriberLastName,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(BeneficiaryShortSexName,'')+';'+
				ISNULL(BeneficiaryLongSexName,'')+';'+
				ISNULL(ChequeAmount,'')+';'+
				ISNULL(PAE,'')+';'+
				ISNULL(SCEE,'')+';'+
				ISNULL(IntSCEE,'')+';'+
				ISNULL(IQEE,'')+';'+
				ISNULL(IntIQEE,'')+';'+
				ISNULL(Total,'')+';'+
				ISNULL(LettrePAESCEETXT1,'')+';'+
				ISNULL(LettrePAEIQEETXT1,'')+';'+
				ISNULL(CAST(BeneficiaryID AS VARCHAR),'')+';'
			FROM #Lettre

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
			JOIN dbo.Un_Convention C ON (C.ConventionNo = D.DocGroup1)
			LEFT JOIN CRQ_DocLink L ON L.DocLinkID = C.ConventionID AND L.DocLinkType = 1 AND L.DocID = D.DocID
			WHERE L.DocID IS NULL
			  AND T.DocTypeID = @DocTypeID
			  AND D.DocOrderTime = @Today
			  AND D.DocOrderConnectID = @ConnectID	

		IF @DocAction = 2
			-- Dans le cas que l'usager a choisi imprimer et garder la trace dans la gestion 
			-- des documents, on indique qu'il a déjà été imprimé pour ne pas le voir dans 
			-- la queue d'impression
			INSERT INTO CRQ_DocPrinted(DocID, DocPrintConnectID, DocPrintTime)
				SELECT
					D.DocID,
					@ConnectID,
					@Today
				FROM CRQ_Doc D 
				JOIN CRQ_DocTemplate T ON (T.DocTemplateID = D.DocTemplateID)
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	-- Produit un dataset pour la fusion
	IF @DocAction <> 0
	SELECT 
		DocTemplateID,
		LangID,
		ConventionNo = l.ConventionNo,
		BeneficiaryFirstName,
		BeneficiaryLastName,
		BeneficiaryAddress,
		BeneficiaryCity,
		BeneficiaryState,
		BeneficiaryZipCode,
		SubscriberFirstName,
		SubscriberLastName,
		LetterMedDate,
		BeneficiaryShortSexName,
		BeneficiaryLongSexName,
		ChequeAmount,
		PAE,
		SCEE,
		IntSCEE,
		IQEE,
		IntIQEE,
		Total,
		LettrePAESCEETXT1,
		LettrePAEIQEETXT1,
		BeneficiaryID
	FROM #Lettre l
	--JOIN dbo.Un_Convention c on l.ConventionNo = c.ConventionNo
	--join un_plan p on c.planid = p.planid 
	WHERE @DocAction IN (1,2)

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE (DocTypeID = @DocTypeID)
			  AND (DocTemplateTime < @Today))
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #Lettre)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Lettre;
END;


