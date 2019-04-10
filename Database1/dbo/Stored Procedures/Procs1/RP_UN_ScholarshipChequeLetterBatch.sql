/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipChequeLetterBatch
Description         :	Rapport de fusion word des lettres de transmission de chèque de bourses en lot
Valeurs de retours  :	Dataset de données
Note                :			ADX0000704	IA	2005-07-07	Bruno Lapointe		Création
								ADX0000706	IA	2005-07-13	Bruno Lapointe		Pas de lettre pour les bénéficiaires dont
																				l'adresse est marquée perdue.
								ADX0000753	IA	2005-11-03	Bruno Lapointe		La procédure va chercher le montant du chèque
																				dans les nouvelles tables au lieu de celles 
																				d'UniSQL 
								ADX0001765	BR	2005-11-22	Bruno Lapointe		Pharse "et dernière" ne s'inscrit pas quand il faut.
								ADX0000878	IA	2006-05-31	Bruno Lapointe		Inclure la SCEE + dans le champ GrantAmountTXT.
																				Inclure l'int. SCEE+ dans le champ GrantIntAmountTXT.
																				Utilise les tables du nouveau système de subvention.
								ADX0002109	BR	2006-10-03	Bruno Lapointe		Sélect 2000 plan B ne s'inscrit pas dans l'historique
																				des documents des conventions.
								ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
								ADX0001355	IA	2007-06-06	Alain Quirion		Utilisation de dtRegEndDateAdjust en remplacement de RegEndDateAddyear
												2008-09-25	Josée Parent		Ne pas produire de DataSet pour les 
																				documents commandés
												2008-11-24	Josée Parent		Modification pour utiliser la fonction "fnCONV_ObtenirDateFinRegime"
												2009-07-29	Pierre-Luc Simard	Correction du champ InterestOnSubscribedAmountTXT 
																				Correction du champ GrantIntAmountTXT pour ajouter un . si aucun intérêts
																				Ajout du champ IQEEAmountTXT
												2009-09-04	Pierre-Luc Simard	Ajout des intérêts dans les montants de subvention.
												2009-12-22	Pierre-Luc Simard	Utilisation de Un_ConventionOper pour l'IQEE
												2010-10-22	Donald Huppé		GLPI 4487 : Sortir UnitQtyTXT avec 3 décimales au lieu de 2
												2010-11-29	Donald Huppé		GLPI 4192 : Exclure (comme avant 2009-09-04) les intérêts des montants de subvention du PCEE
																				Exclure les intérêts des montants de subvention d'IQEE
												2011-06-23	Donald Huppé		GLPI 5706
												2012-06-12	Donald Huppé		GLPI 7697
												2012-11-30	Donald Huppé		GLPI 8654 Ajout de BeneficiaryID
											    2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipChequeLetterBatch] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ScholarshipIDs INTEGER, -- ID du blob contenant les ScholarshipID séparés par des « , » des bourses dont il faut faire le PAE.
	@DocAction INTEGER) -- ID de l'action (0 = commander le document, 1 = imprimer, 2 = imprimer et créer un historique dans la gestion des documents
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@Today DATETIME,
		@DocTypeID INTEGER,
		@LastScholarshipID INTEGER,
		@ScholarshipYear INTEGER,
		@UserName VARCHAR(77),
		@LineStep VARCHAR(2)

	SET @Today = GETDATE()	

	SET @LineStep = CHAR(13) + CHAR(13)

	-- Table temporaire qui contient les documents
	CREATE TABLE #Letter(
		DocTemplateID INTEGER,
		LangID VARCHAR(3),
		LetterMedDate VARCHAR(75),
		OutResid BIT,
		BeneficiaryLongSexName VARCHAR(75),
		BeneficiaryShortSexName VARCHAR(75),
		BeneficiaryFirstName VARCHAR(35),
		BeneficiaryLastName VARCHAR(50),
		BeneficiaryAddress VARCHAR(75),
		BeneficiaryCity VARCHAR(100),
		BeneficiaryState VARCHAR(75),
		BeneficiaryZipCode VARCHAR(75),
		ConventionNO VARCHAR(75),
		PlanName VARCHAR(75),
		ScholarshipNo VARCHAR(75),
		ScholarshipNoLast VARCHAR(75),
		LAStScholarship BIT,
		UnitValue VARCHAR(75),
		ScholarshipYear INTEGER,
		UnitQtyTXT VARCHAR(75),
		ScholarshipAmount VARCHAR(75),
		ChequeAmount VARCHAR(75), 
		AdvanceAmountTXT VARCHAR(125),
		GrantAmountTXT VARCHAR(350),
		GrantIntAmountTXT VARCHAR(125),
		CollGrantAmountTXT VARCHAR(200),
		TrINInterestAmountTXT VARCHAR(200),
		InterestOnSubscribedAmountTXT VARCHAR(200),
		IQEEAmountTXT VARCHAR(500),
		NonResident VARCHAR(200),
		EndYear INTEGER,
		CurrentYear INTEGER,
		UserName VARCHAR(77),
		SubscriberName VARCHAR(87),
		BeneficiaryID INTEGER
	)

	-- Va chercher le bon type de document
	SELECT 
		@DocTypeID = DocTypeID
	FROM CRQ_DocType
	WHERE DocTypeCode = 'ScholChequeLetter'

	-- Recherche le nom du User 
	SELECT
		@UserName = HU.FirstName + ' ' + HU.LastName
	FROM Mo_Connect CO
	JOIN Mo_User U ON (CO.UserID = U.UserID)
	JOIN dbo.Mo_Human HU ON (HU.HumanID = U.UserID)
	WHERE Co.ConnectID = @ConnectID

	SELECT
		@ScholarshipYear = ScholarshipYear
	FROM Un_Def

	DECLARE @tScholarship TABLE (
		ScholarshipID INTEGER PRIMARY KEY )

	INSERT INTO @tScholarship
		SELECT Val
		FROM dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs)

	-- Trouve la bourse qui sera la dernière 
	CREATE TABLE #tLastScholarship (
		ConventionID INTEGER PRIMARY KEY,
		LastScholarshipID INTEGER )
	INSERT INTO #tLastScholarship
		SELECT
			S.ConventionID,
			LastScholarshipID = MAX(LS.ScholarshipID)
		FROM Un_Scholarship S
		JOIN @tScholarship V ON V.ScholarshipID = S.ScholarshipID
		JOIN Un_Scholarship LS ON LS.ConventionID = S.ConventionID
		WHERE LS.ScholarshipStatusID IN ('RES', 'TPA', 'ADM', 'WAI', 'PAD')
		  AND LS.YearDeleted = 0
		GROUP BY S.ConventionID

	-- Insert la lettre dans la table temporaire
	INSERT INTO #Letter
		-- Trouve l'information du reste à partie de cette bourse 
		SELECT
			T.DocTemplateID,
			BH.LangID,
			LetterMedDate = dbo.fn_mo_DateToLongDateStr(GetDate(), BH.LangID),
			OutResid =
				CASE BH.ResidID
					WHEN 'CAN' THEN 0
				ELSE 1
				END,
			BeneficiaryLongSexName = X.LongSexName,
			BeneficiaryShortSexName = X.ShortSexName,
			BeneficiaryFirstName = RTRIM(BH.FirstName),
			BeneficiaryLastName = RTRIM(BH.LastName),
			BeneficiaryAddress = RTRIM(A.Address),
			BeneficiaryCity = ISNULL(RTRIM(A.City),''),
			BeneficiaryState = ISNULL(RTRIM(A.StateName),''),
			BeneficiaryZipCode = dbo.fn_Mo_FormatZip(IsNULL(A.ZipCode,''), A.CountryID),
			ConventionNO = LTRIM(RTRIM(C.ConventionNo)),
				/*CASE P.PlanID
					WHEN 11 THEN 'b' + RTRIM(C.ConventionNo)
				ELSE RTRIM(C.ConventionNo)
				END,*/
			--PlanName = P.PlanDesc,
			PlanName = case when BH.LangID = 'ENU' AND P.PlanID IN (10,12) then 'REFLEX' else  UPPER(P.PlanDesc) end,
			ScholarshipNo = 
				CASE BH.LangID
					WHEN 'FRA' THEN 
						CASE S.ScholarshipNo
							WHEN 1 THEN 'première'
							WHEN 2 THEN 'deuxième'
							WHEN 3 THEN 'troisième'
						END
					WHEN 'ENU' THEN  
						CASE S.ScholarshipNo
							WHEN 1 THEN 'First'
							WHEN 2 THEN 'Second'
							WHEN 3 THEN 'Third'
						END
					ELSE '???'
				END,
			ScholarshipNoLast = 
				CASE 
					WHEN LS.LastScholarshipID = S.ScholarshipID THEN 
						CASE BH.LangID
							WHEN 'FRA' THEN 'et dernière'
							WHEN 'ENU' THEN 'and last'
						END
				ELSE ''
				END,
			LastScholarship = 
				CASE S.ScholarshipID
					WHEN LS.LastScholarshipID THEN 1
				ELSE 0
				END,
			UnitValue = dbo.fn_Mo_MoneyToStr(V.UnitValue, BH.LangID, 1),
			ScholarshipYear = @ScholarshipYear,
			UnitQtyTXT = 
				CASE
					WHEN (U.UnitQty = 1) THEN 
						CASE BH.LangID
							WHEN 'FRA' THEN '1,000 unité'
							WHEN 'ENU' THEN '1.000 unit'
						END
				ELSE  
					CASE BH.LangID
						--WHEN 'FRA' THEN dbo.fn_Mo_MoneyToStr(U.UnitQty, BH.LangID, 0) + ' unités'
						--WHEN 'ENU' THEN dbo.fn_Mo_MoneyToStr(U.UnitQty, BH.LangID, 0) + ' units'
						WHEN 'FRA' THEN  replace(convert(varchar,convert(decimal(10,3), U.UnitQty)),'.',',') + CASE WHEN U.UnitQty < 1 THEN ' unité' ELSE ' unités' END
						WHEN 'ENU' THEN convert(varchar,convert(decimal(10,3), U.UnitQty)) + CASE WHEN U.UnitQty < 1 THEN ' unit' ELSE ' units' END
					END
				END,
			ScholarshipAmount = dbo.fn_Mo_MoneyToStr(S.ScholarshipAmount, BH.LangID , 1)   
			   +CASE -- Si une des deux subventions a un montant en intérêt et non en subvention, le montant en intérêts sur la ou les subventions est ajoutés à la suite du montant de la bourse
					WHEN
						CASE WHEN (ISNULL(INS.fCESGInt,0) <> 0) AND (ISNULL(GG.fCESG,0) = 0) THEN ISNULL(INS.fCESGInt,0) ELSE 0 END + 
						CASE WHEN ((ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) <> 0) AND ((ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.IQEEMaj,0)) = 0) THEN (ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) ELSE 0 END
						<> 0
					THEN
						CASE BH.LangID	WHEN 'FRA' THEN ' et de ' WHEN 'ENU' THEN ' and ' END + 
						dbo.fn_Mo_MoneyToStr(ABS(
							CASE WHEN (ISNULL(INS.fCESGInt,0) <> 0) AND (ISNULL(GG.fCESG,0) = 0) THEN ISNULL(INS.fCESGInt,0) ELSE 0 END + 
							CASE WHEN ((ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) <> 0) AND ((ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.IQEEMaj,0)) = 0) THEN (ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) ELSE 0 END
							) , BH.LangID , 1) +
						CASE BH.LangID	WHEN 'FRA' THEN ' en intérêts' WHEN 'ENU' THEN ' in interest' END
					ELSE
						''
					END,
			ChequeAmount = dbo.fn_Mo_MoneyToStr(CH.fAmount, BH.LangID , 1), 
			AdvanceAmountTXT = 
				CASE
					WHEN IsNULL(AV.AdvanceAmount,0) <> 0 THEN
						CASE BH.LangID
							WHEN 'FRA' THEN 
								'Vous avez reçu une avance de ' + dbo.fn_Mo_MoneyToStr(ABS(AV.AdvanceAmount), BH.LangID , 1) +
								' sur le montant de votre bourse qui sera déduite du chèque.'
							WHEN 'ENU' THEN 
								'You already have received an advance of ' +	dbo.fn_Mo_MoneyToStr(ABS(AV.AdvanceAmount), BH.LangID , 1) +
								' on your scholarship amount. This amout will be deducted of your cheque.'
						END
				ELSE ''
				END,
			GrantAmountTXT = 
				CASE
					WHEN IsNULL(GG.fCESG,0) <> 0 THEN
						CASE BH.LangID
							WHEN 'FRA' THEN  @LineStep +
								'La Subvention canadienne pour l''épargne-études (SCEE) s''applique depuis 1998 ' +
								'aux dépôts faits à un REEE d''un bénéficiaire de moins de 18 ans.  Le montant ' +
								'admissible, avec le versement de votre bourse, est de ' +
								dbo.fn_Mo_MoneyToStr(ABS(GG.fCESG), BH.LangID , 1) +
								CASE WHEN IsNULL(INS.fCESGInt,0) = 0 THEN '.' ELSE '' END
							WHEN 'ENU' THEN @LineStep +
								'Since 1998, the Canadian Education Savings Grant (CESG) has assisted contributions made to the RESP of a beneficiary younger than 18 years of age. ' +
								'The CESG sum to which you are entitled for this scholarship corresponds to ' + 
								 dbo.fn_Mo_MoneyToStr(ABS(GG.fCESG), BH.LangID , 1) +
								CASE WHEN IsNULL(INS.fCESGInt,0) = 0 THEN '.' ELSE '' END
						END
					ELSE ''
					END,
			GrantIntAmountTXT = 
				CASE
					WHEN IsNULL(INS.fCESGInt,0) <> 0  AND (ISNULL(GG.fCESG,0) <> 0) THEN
						CASE BH.LangID
							WHEN 'FRA' THEN ' et de ' + dbo.fn_Mo_MoneyToStr(ABS(INS.fCESGInt), BH.LangID , 1) + ' en revenus générés sur ce montant.'
							WHEN 'ENU' THEN ' and an additional ' + dbo.fn_Mo_MoneyToStr(ABS(INS.fCESGInt), BH.LangID , 1) + ' in earned income.'
						END
				ELSE ''
				END,
			CollGrantAmountTXT = -- Boni
				CASE 
					WHEN ABS(IsNuLL(SUC.CollectiveGrantAmount,0)) + ABS(IsNull(INC.CollectiveInterestAmount,0)) <> 0 THEN
						CASE BH.LangID
							WHEN 'FRA' THEN 
								' Le fonds commun de subvention a généré pour votre compte un boni de ' +
								dbo.fn_Mo_MoneyToStr(ABS(IsNULL(SUC.CollectiveGrantAmount,0)) +
								ABS(IsNULL(INC.CollectiveInterestAmount,0)), BH.LangID , 1) +
								' qui sera ajouté à votre chèque.'
							WHEN 'ENU' THEN ' The common fund of grant has generated a bonus of ' +
								dbo.fn_Mo_MoneyToStr(ABS(IsNULL(SUC.CollectiveGrantAmount,0)) +
								ABS(IsNULL(INC.CollectiveInterestAmount,0)), BH.LangID , 1) +
								' to your account.'
						ELSE '?????'
						END
				ELSE ''
				END,
			TrINInterestAmountTXT = 
				CASE
					WHEN (ABS(IsNULL(ITR.TrINInterestAmount,0)) + ABS(IsNULL(IST.fCESGIntTIN,0)))<> 0  THEN
						CASE BH.LangID
							WHEN 'FRA' THEN @LineStep +
								'Par ailleurs, vous êtes admissible à l''intérêt sur transfert de ' +
								dbo.fn_Mo_MoneyToStr(ABS(IsNULL(ITR.TrINInterestAmount,0)) +
								ABS(IsNULL(IST.fCESGIntTIN,0)), BH.LangID , 1) +
								'.'
							WHEN 'ENU' THEN @LineStep +
								'Moreover, you are eligible to interest on transfer of ' +
								dbo.fn_Mo_MoneyToStr(ABS(IsNULL(ITR.TrINInterestAmount,0)) +
								ABS(IsNULL(IST.fCESGIntTIN,0)), BH.LangID , 1) +
								'.'
						END
				ELSE ''
				END,
			InterestOnSubscribedAmountTXT = 
				CASE
					WHEN ( IsNULL(INM.InterestOnSubscribedAmount,0) <> 0) THEN
						CASE BH.LangID
						WHEN 'FRA' THEN 
							@LineStep + 'De plus, vous êtes admissible à l''intérêt sur capital épargné de ' +
							dbo.fn_Mo_MoneyToStr(ABS(INM.InterestOnSubscribedAmount) , BH.LangID , 1) +
							'.'
						WHEN 'ENU' THEN 
							@LineStep + 'Also, you are eligible to receive the earned income on the capital saved, which represents an amount of ' +
							dbo.fn_Mo_MoneyToStr(ABS(INM.InterestOnSubscribedAmount) , BH.LangID , 1) +
							'.'
						END
				ELSE ''
				END,
			--IQEEAmountTXT = 
			--	CASE
			--		WHEN (ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.IQEEMaj,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0) <> 0) THEN
			--			CASE BH.LangID
			--				WHEN 'FRA' THEN  @LineStep +
			--					'Nous sommes fiers d''inclure, à même votre chèque de bourse, un montant de ' + 
			--					dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.IQEEMaj,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)), BH.LangID , 1) +
			--					' incluant les intérêts et qui représente l''Incitatif Québécois à l''Épargne-Études (IQEE) annoncé dans ' +
			--					'le budget provincial du 21 février 2007.'
			--				WHEN 'ENU' THEN @LineStep +
			--					'We are also proud to include in your cheque the amount of ' +
			--					dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.IQEEMaj,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)), BH.LangID , 1) +
			--					' including interest, which represents the Quebec Education Savings Incentive (QESI), made public ' +
			--					'in the February' + CHAR(160) + '21,' + CHAR(160) + '2007 provincial budget.'
			--			END 
			--	ELSE ''
			--	END,
			
			IQEEAmountTXT = 
				CASE
					WHEN (ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.IQEEMaj,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0) <> 0) THEN
						CASE BH.LangID
							WHEN 'FRA' THEN  @LineStep +
								'Nous sommes fiers d''inclure, à même votre chèque de bourse, l''Incitatif québécois à l''épargne-études (IQEE) annoncé dans le budget provincial du 21 février 2007. Le montant admissible, avec le versement de votre bourse, est de ' + 
								dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.IQEEMaj,0)), BH.LangID , 1) +
								case when (ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) <> 0 then 
									' et de ' + 
									dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)), BH.LangID , 1) +
									' en revenus générés'
								else ''
								end
								+ '.'
							WHEN 'ENU' THEN @LineStep +
								'We are also proud to include in your cheque the Quebec Education Savings Incentive (QESI), released in the February 21, 2007, provincial budget. The QESI sum to which you are entitled for this scholarship corresponds to ' + 
								dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.IQEE,0) + ISNULL(IQEE.IQEEMaj,0)), BH.LangID , 1) +
								case when (ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)) <> 0 then 
									' and an additional ' + 
									dbo.fn_Mo_MoneyToStr(ABS(ISNULL(IQEE.RendIQEE,0) + ISNULL(IQEE.RendIQEEMaj,0) + ISNULL(IQEE.RendIQEETin,0)), BH.LangID , 1) +
									' in earned income'
								else ''
								end
								+ '.'
						END 
				ELSE ''
				END,
							
			NonResident = 
				CASE BH.ResidID
					WHEN 'CAN' THEN ''
				ELSE 
					CASE BH.LangID
						WHEN 'FRA' THEN @LineStep + 'Cependant, nous sommes dans l''obligation de retenir 25% de ce revenu et le remettre à Impôt Canada en vertu de la loi de l''impôt des non-résidents (partie XIII, art. 212 (1) r).'
						WHEN 'ENU' THEN @LineStep + 'However we must deduct 25% from this income and send it to Canada Income Tax as a non resident tax (Part XIII, Art. 212 (1) r).'
					END
				END,
			EndYear = (SELECT YEAR([dbo].[fnCONV_ObtenirDateFinRegime](C.ConventionID,'R',NULL))),
			CurrentYear = @ScholarshipYear,
			UserName = @UserName,
			SubscriberName = RTRIM(SH.LastName)+', '+ RTRIM(SH.FirstName),
			c.BeneficiaryID
		FROM Un_Scholarship S
		JOIN @tScholarship SV ON SV.ScholarshipID = S.ScholarshipID
		JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
		JOIN #tLastScholarship LS ON LS.ConventionID = C.ConventionID
		JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
		JOIN (
			SELECT 
				ConventionID, 
				InForceDate = MIN(InForceDate)
			FROM dbo.Un_Unit 
			GROUP BY ConventionID
			) N ON N.ConventionID = C.ConventionID
		LEFT JOIN Un_Plan P ON P.PlanID = C.PlanID
		LEFT JOIN Un_PlanValues V ON V.PlanID = P.PlanID AND V.ScholarshipYear = @ScholarshipYear AND V.ScholarshipNo = S.ScholarshipNo
		JOIN dbo.Mo_Human BH ON BH.HumanID = C.BeneficiaryID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		JOIN Mo_Sex X ON X.SexID = BH.SexID AND X.LangID = BH.LangID
		JOIN (
			SELECT 
				C.ConventionID, 
				UnitQty = SUM(U.UnitQty)
			FROM dbo.Un_Convention C 
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			GROUP BY 
				C.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN dbo.Mo_Adr A ON A.AdrID = BH.AdrID
		JOIN Un_ScholarshipPmt M ON M.ScholarshipID = S.ScholarshipID
		JOIN Un_Oper O ON O.OperID = M.OperID AND O.OperTypeID = 'PAE'
		JOIN (
			SELECT 
				L.OperID,
				fAmount = SUM(OD.fAmount)
			FROM Un_ScholarshipPmt SP
			JOIN @tScholarship SV ON SV.ScholarshipID = SP.ScholarshipID
			JOIN Un_OperLinkToCHQOperation L ON SP.OperID = L.OperID
			JOIN CHQ_Operation O ON O.iOperationID = L.iOperationID
			JOIN CHQ_OperationDetail OD ON OD.iOperationID = O.iOperationID AND OD.vcAccount = O.vcAccount
			GROUP BY L.OperID
			) CH ON CH.OperID = O.OperID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				AdvanceAmount = SUM(C.ConventionOperAmount)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.ConventionOperTypeID = 'AVC'
			GROUP BY
				V.ScholarshipID
			) AV ON AV.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				fCESG = SUM(CE.fCESG)+SUM(CE.fACESG)
			FROM Un_Oper O
			JOIN Un_CESP CE ON O.OperID = CE.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			GROUP BY
				V.ScholarshipID
			) GG ON GG.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				fCESGInt = SUM(C.ConventionOperAmount)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.ConventionOperTypeID IN ('INS', 'IS+')
			GROUP BY
				V.ScholarshipID
			) INS ON INS.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				fCESGIntTIN = SUM(C.ConventionOperAmount)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.ConventionOperTypeID = 'IST'
			GROUP BY
				V.ScholarshipID
			) IST ON IST.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				InterestOnSubscribedAmount = SUM(C.ConventionOperAmount)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.ConventionOperTypeID = 'INM'
			GROUP BY
				V.ScholarshipID
			) INM ON INM.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				TrINInterestAmount = SUM(C.ConventionOperAmount)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.ConventionOperTypeID = 'ITR'
			GROUP BY
				V.ScholarshipID
			) ITR ON ITR.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				CollectiveInterestAmount = SUM(C.PlanOperAmount)
			FROM Un_Oper O
			JOIN Un_PlanOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.PlanOperTypeID = 'INC'
			GROUP BY
				V.ScholarshipID
			) INC ON INC.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT
				V.ScholarshipID,
				CollectiveGrantAmount = SUM(C.PlanOperAmount)
			FROM Un_Oper O
			JOIN Un_PlanOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			WHERE C.PlanOperTypeID = 'SUC'
			GROUP BY
				V.ScholarshipID
			) SUC ON SUC.ScholarshipID = S.ScholarshipID
		LEFT JOIN (
			SELECT 
				V.ScholarshipID,
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
					)
			FROM Un_Oper O
			JOIN Un_ConventionOper C ON O.OperID = C.OperID
			JOIN Un_ScholarshipPmt P ON P.OperID = O.OperID
			JOIN @tScholarship V ON V.ScholarshipID = P.ScholarshipID
			GROUP BY
				V.ScholarshipID		
			) IQEE ON IQEE.ScholarshipID = S.ScholarshipID
		JOIN ( -- Va chercher les templates les plus récents et qui n'entrent pas en vigueur dans le futur
			SELECT 
				LangID,
				DocTypeID,
				DocTemplateTime = MAX(DocTemplateTime)
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND DocTemplateTime < @Today
			GROUP BY LangID, DocTypeID
			) VT ON VT.LangID = BH.LangID
		JOIN CRQ_DocTemplate T ON VT.DocTypeID = T.DocTypeID AND VT.DocTemplateTime = T.DocTemplateTime AND T.LangID = BH.LangID
		WHERE B.bAddressLost = 0
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
				ISNULL(BeneficiaryLastName,'')+', '+ISNULL(BeneficiaryFirstName,''),
				ISNULL(ScholarshipNo,'')+' - '+SubscriberName,
				ISNULL(LangID,'')+';'+
				ISNULL(LetterMedDate,'')+';'+
				ISNULL(CAST(OutResid AS VARCHAR),'')+';'+
				ISNULL(BeneficiaryLongSexName,'')+';'+
				ISNULL(BeneficiaryShortSexName,'')+';'+
				ISNULL(BeneficiaryFirstName,'')+';'+
				ISNULL(BeneficiaryLastName,'')+';'+
				ISNULL(BeneficiaryAddress,'')+';'+
				ISNULL(BeneficiaryCity,'')+';'+
				ISNULL(BeneficiaryState,'')+';'+
				ISNULL(BeneficiaryZipCode,'')+';'+
				ISNULL(ConventionNO,'')+';'+
				ISNULL(PlanName,'')+';'+
				ISNULL(ScholarshipNo,'')+';'+
				ISNULL(ScholarshipNoLast,'')+';'+
				ISNULL(CAST(LAStScholarship AS VARCHAR),'')+';'+
				ISNULL(UnitValue,'')+';'+
				ISNULL(CAST(ScholarshipYear AS VARCHAR),'')+';'+
				ISNULL(UnitQtyTXT,'')+';'+
				ISNULL(ScholarshipAmount,'')+';'+
				ISNULL(ChequeAmount,'')+';'+
				ISNULL(AdvanceAmountTXT,'')+';'+
				ISNULL(GrantAmountTXT,'')+';'+
				ISNULL(GrantIntAmountTXT,'')+';'+
				ISNULL(CollGrantAmountTXT,'')+';'+
				ISNULL(TrINInterestAmountTXT,'')+';'+
				ISNULL(InterestOnSubscribedAmountTXT,'')+';'+
				ISNULL(IQEEAmountTXT,'')+';'+
				ISNULL(NonResident,'')+';'+
				ISNULL(CAST(EndYear AS VARCHAR),'')+';'+
				ISNULL(CAST(CurrentYear AS VARCHAR),'')+';'+
				ISNULL(UserName,'')+';'+
				ISNULL(CAST(BeneficiaryID AS VARCHAR),'')+';'
			FROM #Letter

		-- Fait un lient entre le document et la convention pour que retrouve le document 
		-- dans l'historique des documents de la convention
		INSERT INTO CRQ_DocLink 
			SELECT
				C.ConventionID,
				1,
				D.DocID
			FROM CRQ_Doc D 
			JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
			JOIN dbo.Un_Convention C ON C.ConventionNo = D.DocGroup1 OR (C.PlanID = 11 AND 'b'+C.ConventionNo = D.DocGroup1)
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
				JOIN CRQ_DocTemplate T ON T.DocTemplateID = D.DocTemplateID
				LEFT JOIN CRQ_DocPrinted P ON P.DocID = D.DocID AND P.DocPrintConnectID = @ConnectID AND P.DocPrintTime = @Today
				WHERE P.DocID IS NULL
				  AND T.DocTypeID = @DocTypeID
				  AND D.DocOrderTime = @Today
				  AND D.DocOrderConnectID = @ConnectID					
	END

	IF @DocAction <> 0
	BEGIN
		-- Produit un dataset pour la fusion
		SELECT 
			DocTemplateID,
			LangID,
			LetterMedDate,
			OutResid,
			BeneficiaryLongSexName,
			BeneficiaryShortSexName,
			BeneficiaryFirstName,
			BeneficiaryLastName,
			BeneficiaryAddress,
			BeneficiaryCity,
			BeneficiaryState,
			BeneficiaryZipCode,
			ConventionNO,
			PlanName,
			ScholarshipNo,
			ScholarshipNoLast,
			LAStScholarship,
			UnitValue,
			ScholarshipYear,
			UnitQtyTXT,
			ScholarshipAmount,
			ChequeAmount, 
			AdvanceAmountTXT,
			GrantAmountTXT,
			GrantIntAmountTXT,
			CollGrantAmountTXT,
			TrINInterestAmountTXT,
			InterestOnSubscribedAmountTXT,
			IQEEAmountTXT,
			NonResident,
			EndYear,
			CurrentYear,
			UserName,
			BeneficiaryID
		FROM #Letter 
		WHERE @DocAction IN (1,2)
	END

	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM CRQ_DocTemplate
			WHERE DocTypeID = @DocTypeID
			  AND DocTemplateTime < @Today)
		RETURN -1 -- Pas de template d'entré ou en vigueur pour ce type de document
	IF NOT EXISTS (
			SELECT 
				DocTemplateID
			FROM #Letter)
		RETURN -2 -- Pas de document(s) de généré(s)
	ELSE 
		RETURN 1 -- Tout a bien fonctionné

	-- RETURN VALUE
	---------------
	-- >0  : Tout ok
	-- <=0 : Erreurs
	-- 	-1 : Pas de template d'entré ou en vigueur pour ce type de document
	-- 	-2 : Pas de document(s) de généré(s)

	DROP TABLE #Letter
    */
END