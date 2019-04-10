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
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	RP_UN_ScholarshipAccounting_IQEE
Description         :	Rapport de comptabilité des bourses
Valeurs de retours  :	Dataset de données
						PlanDesc 		Nom du plan de la convention	
						BourseNo		No de la bourse
						ConventionNo		No de la convention
						YearQualif		Année de qualification d'une convention
						Beneficiaire 		Nom, prénom du bénéficiaire
						Souscripteur		Nom, prénom du souscripteur
						UnitQty 		Nombre d'unité dans une convention
						ChequeDate 		Date d'émission du chèque
						ChequeNo 		No du chèque
						AdvanceAmount 		Montant des avances
						ScholarshipAmount	Montant de bourse versée
						fINM			Somme des Int. Sur montant souscrit 
										(INM individuel). 
						fCESG			Somme des montants provenant de la SCEE
						fACESG			Somme des montants provenant de la SCEE+
						fCLB 			Somme des montants provenant du BEC
						fINS			Somme des Int. Sur la SCEE (INS) et Int. SCEE TIN
						fISP			Somme des Int. Sur la SCEE+ (IS+)
						fIBC			Somme des Int. Sur le BEC (IBC)
						fITR			Somme des intérêts provenant d'un transfert IN (Int. TIN)
						fIRIOnVersedInt		Somme des intérêts sur RI versés / Intérêts versés (individuel)(INM collectif)
						ChequeAmount		Montant du chèque

Note                :	
						ADX0000704	IA	2005-11-03	Bruno Lapointe		Création
						ADX0000753	IA	2005-11-03	Bruno Lapointe		La procédure va chercher le montant du 
																		chèque d'UniSQL dans les nouvelles tables au lieu de celles d'UNISQL
						ADX0001112	IA	2006-10-10	Mireya Gonthier		Adaptation : Rapport de comptabilité des bourses
						ADX0001112	IA	2006-10-31	Bruno Lapointe		Optimisation
						ADX0001334	IA	2007-04-03	Bruno Lapointe		Suppression du ChequeAmount et ajout des champs fRGC 
																		et fTotal. Exclusion des lignes des opérations RGC.
						ADX0002439	BR	2007-05-21	Bruno Lapointe		La colonne fIST remplacé par fITR
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
						ADX0003089	UR	2007-10-24	Bruno Lapointe		Ajout de IST (Int. SCEE TIN) à la colonne fINS
										2008-05-16	Pierre-Luc Simard	Ajout des annulations de chèques
										2008-11-06	Pierre-Luc Simard	Correction des montant RGC car il y avait des doublons
										2009-07-29	Pierre-Luc Simard	Ajout des montants d'IQEE
										2009-12-22	Pierre-Luc Simard	Utilisation de Un_ConventionOper pour l'IQEE
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

exec RP_UN_ScholarshipAccounting_IQEE '2009-11-01' , '2009-11-30' , 'S'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipAccounting_IQEE] (
	@StartDate DATETIME, -- Date de début de l'intervalle des opérations
	@EndDate DATETIME, -- Date de fin de l'intervalle des opérations
	@cOrder	CHAR(1))	--Tri du rapport : 
				--S = Nom, prénom du souscripteur suivi du numéro de convention, 
				--B = Nom, prénom du bénéficiaire suivi du numéro de convention.) 
AS
BEGIN

    SELECT 1/0
    /*
	SET @EndDate = DATEADD(MINUTE,-1,DATEADD(DAY,1,@EndDate))

	-- Va chercher les chèques répondant au critère de la période et du statut.
	DECLARE @tCHQ_Check TABLE (
		iCheckHistoryID INTEGER PRIMARY KEY,
		iCheckID INTEGER,
		iCheckStatusID INTEGER,
		dtEmission DATETIME)
	INSERT INTO @tCHQ_Check
		SELECT 
			CH.iCheckHistoryID,
			C.iCheckID,
			CH.iCheckStatusID,
			dtEmission = CASE WHEN CH.iCheckStatusID = 5 THEN CH.dtHistory ELSE C.dtEmission END
		FROM CHQ_Check C
		JOIN CHQ_CheckHistory CH ON CH.iCheckID = C.iCheckID
		WHERE (CH.iCheckStatusID IN (4,6)
				AND dtEmission BETWEEN @StartDate AND @EndDate)		
			OR (CH.iCheckStatusID = 5 
				AND dtHistory BETWEEN @StartDate AND @EndDate) 	
	
	-- Va chercher tous les opérations dont le dernier chèque a été imprimé ou annulé dans l'interval donné
	DECLARE @tRP_UN_SchoCheck TABLE (
		iCheckHistoryID INTEGER, --PRIMARY KEY, Ne peut pas être une clé primaire car deux conventions peuvent avoir le même chèque.
		iCheckID INTEGER,		
		iCheckStatusID INTEGER,
		OperID INTEGER,-- PRIMARY KEY,
		vcPayeeName VARCHAR(87) NULL,
		iCheckNumber INTEGER NULL,
		dtEmission DATETIME NOT NULL,
		fAmount DECIMAL(18,2) NOT NULL )
	INSERT INTO @tRP_UN_SchoCheck
		SELECT DISTINCT
			Ct.iCheckHistoryID,
			Ct.iCheckID,			
			Ct.iCheckStatusID,
			L.OperID,
			vcPayeeName = ISNULL(H.LastName,'')+', '+ISNULL(H.FirstName,''),
			C.iCheckNumber,
			Ct.dtEmission,
			fAmount = CASE WHEN Ct.iCheckStatusID = 5 THEN -C.fAmount ELSE C.fAmount END -- Inverse le montant du chèque si c'est une annulation
		FROM @tCHQ_Check Ct
		JOIN CHQ_CheckOperationDetail COD ON Ct.iCheckID = COD.iCheckID
		JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN Un_OperLinkToCHQOperation L ON OD.iOperationID = L.iOperationID
		JOIN CHQ_Check C ON C.iCheckID = Ct.iCheckID
		JOIN dbo.Mo_Human H ON H.HumanID = C.iPayeeID
		JOIN Un_ScholarshipPmt M ON M.OperID = L.OperID -- Opérations de bourses uniquement
	
	-- Va chercher les différents numéro de convention qui ont reçues une bourses
	DECLARE @tConvention TABLE (
		ConventionID INTEGER PRIMARY KEY )
	INSERT INTO @tConvention
		SELECT DISTINCT S.ConventionID
		FROM @tRP_UN_SchoCheck Ch
		JOIN Un_Oper O ON Ch.OperID = O.OperID
		JOIN Un_ScholarshipPmt M ON O.OperID = M.OperID
		JOIN Un_Scholarship S ON S.ScholarshipID = M.ScholarshipID
	
	-- Table de tous les montants d'argent de type opération sur convention pour les opérations en question.
	DECLARE @tRP_UN_SchoConvOper TABLE (
		iCheckHistoryID INTEGER, 
		OperID INTEGER NOT NULL,
		ConventionOperTypeID CHAR(3) NOT NULL,
		ConventionOperAmount MONEY NOT NULL )
	INSERT INTO @tRP_UN_SchoConvOper
		SELECT
			SC.iCheckHistoryID,
			SC.OperID,
			CO.ConventionOperTypeID,
			ConventionOperAmount = CASE WHEN SC.iCheckStatusID = 5 THEN SUM(CO.ConventionOperAmount) ELSE -SUM(CO.ConventionOperAmount) END
		FROM @tRP_UN_SchoCheck SC
		JOIN Un_ConventionOper CO ON CO.OperID = SC.OperID
		GROUP BY
			SC.iCheckHistoryID,
			SC.OperID,
			CO.ConventionOperTypeID,
			SC.iCheckStatusID

	-- Table de tous les montants d'argent de type opération sur convention pour les opérations en question.
	DECLARE @tRP_UN_SchoRGC TABLE (
		ScholarshipID INTEGER,-- PRIMARY KEY,
		iCheckStatusID INTEGER,
		fRGC MONEY NOT NULL,
		fBRS MONEY NOT NULL )
	INSERT INTO @tRP_UN_SchoRGC
		SELECT 
			RGC.ScholarshipID,
			RGC.iCheckStatusID,
			fRGC = SUM(RGC.fRGC),
			fBRS = SUM(RGC.fBRS)
		FROM (
			SELECT DISTINCT
				M.ScholarshipID,
				iCheckStatusID,
				fRGC = CASE WHEN SC.iCheckStatusID = 5 THEN -(CO.ConventionOperAmount) ELSE (CO.ConventionOperAmount) END,
				fBRS = 
					(	CASE 
								WHEN CO.COnventionOperTypeID = 'BRS' THEN
									CASE WHEN SC.iCheckStatusID = 5 THEN -CO.ConventionOperAmount ELSE CO.ConventionOperAmount END
							ELSE 0
							END
						)
			FROM @tRP_UN_SchoCheck SC
			JOIN Un_ConventionOper CO ON CO.OperID = SC.OperID
			JOIN Un_ScholarshipPmt M ON SC.OperID = M.OperID
			JOIN Un_Oper O ON O.OperID = SC.OperID
			WHERE O.OperTypeID = 'RGC'
			GROUP BY
				M.ScholarshipID,
				SC.iCheckHistoryID,
				iCheckStatusID,
				CO.ConventionOperAmount,
				CO.OperID,
				CO.COnventionOperTypeID
			) RGC
		GROUP BY 
			RGC.ScholarshipID,
			RGC.iCheckStatusID		

/*	-- Table de tous les montants d'argent versés en IQEE pour les bourses, selon la table temporaire (DEVRA ÊTRE MODIFIÉ)
	DECLARE @tRP_UN_SchoIQEE TABLE (
		OperID INTEGER, --PRIMARY KEY,
		iCheckHistoryID INTEGER,	
		iCheckID INTEGER,
		mCredit_Base_Verse MONEY NOT NULL,
		mMajoration_Verse MONEY NOT NULL,
		mInterets_RQ_IQEE MONEY NOT NULL)

	INSERT INTO @tRP_UN_SchoIQEE
		SELECT 
			SC.OperID,
			SC.iCheckHistoryID,
			SC.iCheckID,
			mCredit_Base_Verse = CASE WHEN SC.iCheckStatusID = 5 THEN -ISNULL(IQEE.mCredit_Base_Verse, 0) ELSE ISNULL(IQEE.mCredit_Base_Verse, 0) END, -- Inverse le montant si c'est une annulation 
			mMajoration_Verse = CASE WHEN SC.iCheckStatusID = 5 THEN -ISNULL(IQEE.mMajoration_Verse, 0) ELSE ISNULL(IQEE.mMajoration_Verse, 0) END, -- Inverse le montant si c'est une annulation 
			mInterets_RQ_Verse = CASE WHEN SC.iCheckStatusID = 5 THEN -ISNULL(IQEE.mInterets_RQ_Verse, 0) ELSE ISNULL(IQEE.mInterets_RQ_Verse, 0) END -- Inverse le montant si c'est une annulation 

		FROM @tRP_UN_SchoCheck SC
		JOIN tblTEMP_InformationsIQEEPourPAE IQEE ON IQEE.iID_Operation = SC.OperID
	*/	

	-- TRI selon le nom, prénom du Bénéficiaire ensuite par No de convention
	IF @cOrder = 'B'
	BEGIN
		SELECT
			CH.iCheckHistoryID,
			CH.iCheckID,			
			CH.iCheckStatusID,
			CH.OperID,
			PlanDesc = P.PlanDesc,
			PlanType = CASE WHEN P.PlanTypeID = 'IND' THEN 'Individuel' ELSE 'Collectif' END,
			BourseNo = 'Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)),
			C.ConventionNo,
			Beneficiaire = ISNULL(CH.vcPayeeName,''),
			Souscripteur = ISNULL(SH.LastName,'')+', '+ISNULL(SH.FirstName,''),
			UnitQty =
				CASE O.OperTypeID
					WHEN 'PAE' THEN CASE WHEN Ch.iCheckStatusID = 5 THEN -U.UnitQty  ELSE U.UnitQty END 
				ELSE 0 
				END,
			ChequeDate = dbo.FN_CRQ_DateNoTime(CH.dtEmission),
			ChequeNo = ISNULL(CAST(CH.iCheckNumber AS VARCHAR(30)),''),
			AdvanceAmount = ISNULL(AV.ConventionOperAmount,0),
			ScholarshipAmount = ISNULL(OB.ConventionOperAmount,0)-ISNULL(RGC.fBRS,0),
			fINM = ISNULL(INMI.ConventionOperAmount, 0),
			fCESG = ISNULL(GG.fCESG, 0),
			fACESG = ISNULL(GG.fACESG,0),
			fCLB = ISNULL(GG.fCLB,0),
			fINS = ISNULL(INS.ConventionOperAmount,0)+ISNULL(IST.ConventionOperAmount,0),
			fISP = ISNULL(ISP.ConventionOperAmount,0),
			fIBC = ISNULL(IBC.ConventionOperAmount,0),
			fITR = ISNULL(ITR.ConventionOperAmount, 0),
			fIRIOnVersedInt = ISNULL(INMC.ConventionOperAmount, 0),
			fRGC = ISNULL(RGC.fRGC,0),
			fCBQ = ISNULL(CBQ.ConventionOperAmount,0),
			fMMQ = ISNULL(MMQ.ConventionOperAmount,0),
			fIQI = ISNULL(IQI.ConventionOperAmount,0),
			fMIM = ISNULL(MIM.ConventionOperAmount,0),
			fICQ = ISNULL(ICQ.ConventionOperAmount,0),
			fIMQ = ISNULL(IMQ.ConventionOperAmount,0),
			fIIQ = ISNULL(IIQ.ConventionOperAmount,0),
			fIII = ISNULL(III.ConventionOperAmount,0),
			mCredit_Base_Verse = ISNULL(CBQ.ConventionOperAmount,0),
			mMajoration_Verse = ISNULL(MMQ.ConventionOperAmount,0),
			mInterets_RQ_IQEE = ISNULL(IQI.ConventionOperAmount,0) + ISNULL(MIM.ConventionOperAmount,0) + ISNULL(ICQ.ConventionOperAmount,0) + ISNULL(IIQ.ConventionOperAmount,0) + ISNULL(III.ConventionOperAmount,0),
			mInterets_RQ_IQEE_Maj = ISNULL(IMQ.ConventionOperAmount,0),
			/*mCredit_Base_Verse = ISNULL(IQEE.mCredit_Base_Verse,0),
			mMajoration_Verse = ISNULL(IQEE.mMajoration_Verse,0),
			mInterets_RQ_IQEE = ISNULL(IQEE.mInterets_RQ_IQEE,0) + 0, -- 0 est Rendement de base calculé
			mInterets_RQ_IQEE_Maj = 0, -- rend. majoré calculé*/
			fTotal = 
				ISNULL(AV.ConventionOperAmount,0) +
				ISNULL(OB.ConventionOperAmount,0)-ISNULL(RGC.fBRS,0) +
				ISNULL(INMI.ConventionOperAmount, 0) +
				ISNULL(GG.fCESG, 0) +
				ISNULL(GG.fACESG,0) +
				ISNULL(GG.fCLB,0) +
				ISNULL(INS.ConventionOperAmount,0) +
				ISNULL(IST.ConventionOperAmount,0) +
				ISNULL(ISP.ConventionOperAmount,0) +
				ISNULL(IBC.ConventionOperAmount,0) +
				ISNULL(ITR.ConventionOperAmount, 0) +
				ISNULL(INMC.ConventionOperAmount, 0) +
				ISNULL(RGC.fRGC,0) + 
				ISNULL(CBQ.ConventionOperAmount,0) +
				ISNULL(MMQ.ConventionOperAmount,0) +
				ISNULL(IQI.ConventionOperAmount,0) +
				ISNULL(MIM.ConventionOperAmount,0) +
				ISNULL(ICQ.ConventionOperAmount,0) +
				ISNULL(IMQ.ConventionOperAmount,0) +
				ISNULL(IIQ.ConventionOperAmount,0) +
				ISNULL(III.ConventionOperAmount,0) +
				/*
				ISNULL(IQEE.mCredit_Base_Verse,0) + 
				ISNULL(IQEE.mMajoration_Verse,0) +
				ISNULL(IQEE.mInterets_RQ_IQEE,0) + 0 +*/
				0

		FROM @tRP_UN_SchoCheck Ch
		JOIN Un_Oper O ON Ch.OperID = O.OperID
		JOIN Un_ScholarshipPmt M ON O.OperID = M.OperID
		JOIN Un_Scholarship S ON S.ScholarshipID = M.ScholarshipID
		JOIN dbo.Un_Convention C ON S.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human BH ON C.BeneficiaryID = BH.HumanID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT 
				C.ConventionID, 
				UnitQty = SUM(U.UnitQty)
			FROM @tConvention C 
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			GROUP BY 
				C.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN @tRP_UN_SchoConvOper OB ON OB.OperID = O.OperID AND OB.iCheckHistoryID = Ch.iCheckHistoryID AND OB.ConventionOperTypeID = 'BRS'
		LEFT JOIN @tRP_UN_SchoConvOper AV ON AV.OperID = O.OperID AND AV.iCheckHistoryID = Ch.iCheckHistoryID AND AV.ConventionOperTypeID = 'AVC'
		LEFT JOIN @tRP_UN_SchoConvOper INMI ON INMI.OperID = O.OperID AND INMI.iCheckHistoryID = Ch.iCheckHistoryID AND INMI.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'IND' --INDIVIDUEL 
		LEFT JOIN @tRP_UN_SchoConvOper INS ON INS.OperID = O.OperID AND INS.iCheckHistoryID = Ch.iCheckHistoryID AND INS.ConventionOperTypeID = 'INS' -- IN ('INS', 'ITR')
		LEFT JOIN @tRP_UN_SchoConvOper IST ON IST.OperID = O.OperID AND IST.iCheckHistoryID = Ch.iCheckHistoryID AND IST.ConventionOperTypeID = 'IST'
		LEFT JOIN @tRP_UN_SchoConvOper ISP ON ISP.OperID = O.OperID AND ISP.iCheckHistoryID = Ch.iCheckHistoryID AND ISP.ConventionOperTypeID = 'IS+' 
		LEFT JOIN @tRP_UN_SchoConvOper IBC ON IBC.OperID = O.OperID AND IBC.iCheckHistoryID = Ch.iCheckHistoryID AND IBC.ConventionOperTypeID = 'IBC' 
		LEFT JOIN @tRP_UN_SchoConvOper ITR ON ITR.OperID = O.OperID AND ITR.iCheckHistoryID = Ch.iCheckHistoryID AND ITR.ConventionOperTypeID = 'ITR'
		LEFT JOIN @tRP_UN_SchoConvOper INMC ON INMC.OperID = O.OperID AND INMC.iCheckHistoryID = Ch.iCheckHistoryID AND INMC.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'COL' --COLLECTIF
		LEFT JOIN @tRP_UN_SchoConvOper CBQ ON CBQ.OperID = O.OperID AND CBQ.iCheckHistoryID = Ch.iCheckHistoryID AND CBQ.ConventionOperTypeID = 'CBQ'
		LEFT JOIN @tRP_UN_SchoConvOper MMQ ON MMQ.OperID = O.OperID AND MMQ.iCheckHistoryID = Ch.iCheckHistoryID AND MMQ.ConventionOperTypeID = 'MMQ'
		LEFT JOIN @tRP_UN_SchoConvOper IQI ON IQI.OperID = O.OperID AND IQI.iCheckHistoryID = Ch.iCheckHistoryID AND IQI.ConventionOperTypeID = 'IQI'
		LEFT JOIN @tRP_UN_SchoConvOper MIM ON MIM.OperID = O.OperID AND MIM.iCheckHistoryID = Ch.iCheckHistoryID AND MIM.ConventionOperTypeID = 'MIM'
		LEFT JOIN @tRP_UN_SchoConvOper ICQ ON ICQ.OperID = O.OperID AND ICQ.iCheckHistoryID = Ch.iCheckHistoryID AND ICQ.ConventionOperTypeID = 'ICQ'
		LEFT JOIN @tRP_UN_SchoConvOper IMQ ON IMQ.OperID = O.OperID AND IMQ.iCheckHistoryID = Ch.iCheckHistoryID AND IMQ.ConventionOperTypeID = 'IMQ'
		LEFT JOIN @tRP_UN_SchoConvOper IIQ ON IIQ.OperID = O.OperID AND IIQ.iCheckHistoryID = Ch.iCheckHistoryID AND IIQ.ConventionOperTypeID = 'IIQ'
		LEFT JOIN @tRP_UN_SchoConvOper III ON III.OperID = O.OperID AND III.iCheckHistoryID = Ch.iCheckHistoryID AND III.ConventionOperTypeID = 'III'		
		--LEFT JOIN @tRP_UN_SchoIQEE IQEE ON IQEE.OperID = CH.OperID AND IQEE.iCheckHistoryID = Ch.iCheckHistoryID
		LEFT JOIN (
			SELECT 
				Ch.iCheckHistoryID,
				CE.OperID, 
				fCESG = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM(CE.fCESG) ELSE -SUM(CE.fCESG) END,
				fACESG = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM(CE.fACESG) ELSE -SUM(CE.fACESG) END,
				fCLB = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM (CE.fCLB) ELSE -SUM (CE.fCLB) END
			FROM @tRP_UN_SchoCheck Ch
			JOIN UN_CESP CE ON CE.OperID = Ch.OperID
			GROUP BY Ch.iCheckHistoryID, CE.OperID, Ch.iCheckStatusID
			) GG ON GG.OperID = O.OperID AND GG.iCheckHistoryID = Ch.iCheckHistoryID
		LEFT JOIN @tRP_UN_SchoRGC RGC ON RGC.ScholarshipID = S.ScholarshipID AND RGC.iCheckStatusID = Ch.iCheckStatusID
		WHERE O.OperTypeID <> 'RGC' -- Exclus les paiements au Receveur général du Canada
		ORDER BY 
			P.PlanDesc,
			BourseNo,
			S.ScholarshipNo,
			BH.LastName,
			BH.FirstName,
			C.ConventionNo
	END
	ELSE --Trier selon le Nom, Prénom du souscripteur , ensuite par No de convention
	BEGIN
		SELECT 
			CH.iCheckHistoryID,
			CH.iCheckID,			
			CH.iCheckStatusID,
			CH.OperID,
			PlanDesc = P.PlanDesc,
			PlanType = CASE WHEN P.PlanTypeID = 'IND' THEN 'Individuel' ELSE 'Collectif' END,
			BourseNo = 'Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)),
			C.ConventionNo,
			Beneficiaire = ISNULL(CH.vcPayeeName,''),
			Souscripteur = ISNULL(SH.LastName,'')+', '+ISNULL(SH.FirstName,''),
			UnitQty =
				CASE O.OperTypeID
					WHEN 'PAE' THEN 
						CASE WHEN Ch.iCheckStatusID = 5 THEN -U.UnitQty  ELSE U.UnitQty END
				ELSE 0 
				END,
			ChequeDate = dbo.FN_CRQ_DateNoTime(CH.dtEmission),
			ChequeNo = ISNULL(CAST(CH.iCheckNumber AS VARCHAR(30)),''),
			AdvanceAmount = ISNULL(AV.ConventionOperAmount,0),
			ScholarshipAmount = ISNULL(OB.ConventionOperAmount,0),
			fINM = ISNULL(INMI.ConventionOperAmount, 0),
			fCESG = ISNULL(GG.fCESG, 0),
			fACESG = ISNULL(GG.fACESG,0),
			fCLB = ISNULL(GG.fCLB,0),
			fINS = ISNULL(INS.ConventionOperAmount,0)+ISNULL(IST.ConventionOperAmount,0),
			fISP = ISNULL(ISP.ConventionOperAmount,0),
			fIBC = ISNULL(IBC.ConventionOperAmount,0),
			fITR = ISNULL(ITR.ConventionOperAmount, 0),
			fIRIOnVersedInt = ISNULL(INMC.ConventionOperAmount, 0),
			fRGC = ISNULL(RGC.fRGC,0),
			fCBQ = ISNULL(CBQ.ConventionOperAmount,0),
			fMMQ = ISNULL(MMQ.ConventionOperAmount,0),
			fIQI = ISNULL(IQI.ConventionOperAmount,0),
			fMIM = ISNULL(MIM.ConventionOperAmount,0),
			fICQ = ISNULL(ICQ.ConventionOperAmount,0),
			fIMQ = ISNULL(IMQ.ConventionOperAmount,0),
			fIIQ = ISNULL(IIQ.ConventionOperAmount,0),
			fIII = ISNULL(III.ConventionOperAmount,0),
			mCredit_Base_Verse = ISNULL(CBQ.ConventionOperAmount,0),
			mMajoration_Verse = ISNULL(MMQ.ConventionOperAmount,0),
			mInterets_RQ_IQEE = ISNULL(IQI.ConventionOperAmount,0) + ISNULL(MIM.ConventionOperAmount,0) + ISNULL(ICQ.ConventionOperAmount,0) + ISNULL(IIQ.ConventionOperAmount,0) + ISNULL(III.ConventionOperAmount,0),
			mInterets_RQ_IQEE_Maj = ISNULL(IMQ.ConventionOperAmount,0),
			/*mCredit_Base_Verse = ISNULL(IQEE.mCredit_Base_Verse,0),
			mMajoration_Verse = ISNULL(IQEE.mMajoration_Verse,0),
			mInterets_RQ_IQEE = ISNULL(IQEE.mInterets_RQ_IQEE,0) + 0, -- 0 est Rendement de base calculé
			mInterets_RQ_IQEE_Maj = 0, -- rend. majoré calculé*/
			fTotal = 
				ISNULL(AV.ConventionOperAmount,0) +
				ISNULL(OB.ConventionOperAmount,0)-ISNULL(RGC.fBRS,0) +
				ISNULL(INMI.ConventionOperAmount, 0) +
				ISNULL(GG.fCESG, 0) +
				ISNULL(GG.fACESG,0) +
				ISNULL(GG.fCLB,0) +
				ISNULL(INS.ConventionOperAmount,0) +
				ISNULL(IST.ConventionOperAmount,0) +
				ISNULL(ISP.ConventionOperAmount,0) +
				ISNULL(IBC.ConventionOperAmount,0) +
				ISNULL(ITR.ConventionOperAmount, 0) +
				ISNULL(INMC.ConventionOperAmount, 0) +
				ISNULL(RGC.fRGC,0) + 
				ISNULL(CBQ.ConventionOperAmount,0) +
				ISNULL(MMQ.ConventionOperAmount,0) +
				ISNULL(IQI.ConventionOperAmount,0) +
				ISNULL(MIM.ConventionOperAmount,0) +
				ISNULL(ICQ.ConventionOperAmount,0) +
				ISNULL(IMQ.ConventionOperAmount,0) +
				ISNULL(IIQ.ConventionOperAmount,0) +
				ISNULL(III.ConventionOperAmount,0) +

				/*ISNULL(IQEE.mCredit_Base_Verse,0) + 
				ISNULL(IQEE.mMajoration_Verse,0) +
				ISNULL(IQEE.mInterets_RQ_IQEE,0) + 0 +*/
				0

		FROM @tRP_UN_SchoCheck Ch
		JOIN Un_Oper O ON Ch.OperID = O.OperID
		JOIN Un_ScholarshipPmt M ON O.OperID = M.OperID
		JOIN Un_Scholarship S ON S.ScholarshipID = M.ScholarshipID
		JOIN dbo.Un_Convention C ON S.ConventionID = C.ConventionID
		JOIN dbo.Mo_Human BH ON C.BeneficiaryID = BH.HumanID
		JOIN dbo.Mo_Human SH ON SH.HumanID = C.SubscriberID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN (
			SELECT 
				C.ConventionID, 
				UnitQty = SUM(U.UnitQty)
			FROM @tConvention C 
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			GROUP BY 
				C.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN @tRP_UN_SchoConvOper OB ON OB.OperID = O.OperID AND OB.iCheckHistoryID = Ch.iCheckHistoryID AND OB.ConventionOperTypeID = 'BRS'
		LEFT JOIN @tRP_UN_SchoConvOper AV ON AV.OperID = O.OperID AND AV.iCheckHistoryID = Ch.iCheckHistoryID AND AV.ConventionOperTypeID = 'AVC'
		LEFT JOIN @tRP_UN_SchoConvOper INMI ON INMI.OperID = O.OperID AND INMI.iCheckHistoryID = Ch.iCheckHistoryID AND INMI.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'IND'--NDIVIDUEL 
		LEFT JOIN @tRP_UN_SchoConvOper INS ON INS.OperID = O.OperID AND INS.iCheckHistoryID = Ch.iCheckHistoryID AND INS.ConventionOperTypeID = 'INS'-- IN ('INS', 'ITR')
		LEFT JOIN @tRP_UN_SchoConvOper IST ON IST.OperID = O.OperID AND IST.iCheckHistoryID = Ch.iCheckHistoryID AND IST.ConventionOperTypeID = 'IST'
		LEFT JOIN @tRP_UN_SchoConvOper ISP ON ISP.OperID = O.OperID AND ISP.iCheckHistoryID = Ch.iCheckHistoryID AND ISP.ConventionOperTypeID = 'IS+' 
		LEFT JOIN @tRP_UN_SchoConvOper IBC ON IBC.OperID = O.OperID AND IBC.iCheckHistoryID = Ch.iCheckHistoryID AND IBC.ConventionOperTypeID = 'IBC' 
		LEFT JOIN @tRP_UN_SchoConvOper ITR ON ITR.OperID = O.OperID AND ITR.iCheckHistoryID = Ch.iCheckHistoryID AND ITR.ConventionOperTypeID = 'ITR'
		LEFT JOIN @tRP_UN_SchoConvOper INMC ON INMC.OperID = O.OperID AND INMC.iCheckHistoryID = Ch.iCheckHistoryID AND INMC.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'COL' --COLLECTIF
		LEFT JOIN @tRP_UN_SchoConvOper CBQ ON CBQ.OperID = O.OperID AND CBQ.iCheckHistoryID = Ch.iCheckHistoryID AND CBQ.ConventionOperTypeID = 'CBQ'
		LEFT JOIN @tRP_UN_SchoConvOper MMQ ON MMQ.OperID = O.OperID AND MMQ.iCheckHistoryID = Ch.iCheckHistoryID AND MMQ.ConventionOperTypeID = 'MMQ'
		LEFT JOIN @tRP_UN_SchoConvOper IQI ON IQI.OperID = O.OperID AND IQI.iCheckHistoryID = Ch.iCheckHistoryID AND IQI.ConventionOperTypeID = 'IQI'
		LEFT JOIN @tRP_UN_SchoConvOper MIM ON MIM.OperID = O.OperID AND MIM.iCheckHistoryID = Ch.iCheckHistoryID AND MIM.ConventionOperTypeID = 'MIM'
		LEFT JOIN @tRP_UN_SchoConvOper ICQ ON ICQ.OperID = O.OperID AND ICQ.iCheckHistoryID = Ch.iCheckHistoryID AND ICQ.ConventionOperTypeID = 'ICQ'
		LEFT JOIN @tRP_UN_SchoConvOper IMQ ON IMQ.OperID = O.OperID AND IMQ.iCheckHistoryID = Ch.iCheckHistoryID AND IMQ.ConventionOperTypeID = 'IMQ'
		LEFT JOIN @tRP_UN_SchoConvOper IIQ ON IIQ.OperID = O.OperID AND IIQ.iCheckHistoryID = Ch.iCheckHistoryID AND IIQ.ConventionOperTypeID = 'IIQ'
		LEFT JOIN @tRP_UN_SchoConvOper III ON III.OperID = O.OperID AND III.iCheckHistoryID = Ch.iCheckHistoryID AND III.ConventionOperTypeID = 'III'	
		--LEFT JOIN @tRP_UN_SchoIQEE IQEE ON IQEE.OperID = CH.OperID AND IQEE.iCheckHistoryID = Ch.iCheckHistoryID
		LEFT JOIN (
			SELECT 
				Ch.iCheckHistoryID,
				CE.OperID, 
				fCESG = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM(CE.fCESG) ELSE -SUM(CE.fCESG) END,
				fACESG = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM(CE.fACESG) ELSE -SUM(CE.fACESG) END,
				fCLB = CASE WHEN Ch.iCheckStatusID = 5 THEN SUM (CE.fCLB) ELSE -SUM (CE.fCLB) END
			FROM @tRP_UN_SchoCheck Ch
			JOIN UN_CESP CE ON CE.OperID = Ch.OperID
			GROUP BY Ch.iCheckHistoryID, CE.OperID, Ch.iCheckStatusID
			) GG ON GG.OperID = O.OperID AND GG.iCheckHistoryID = Ch.iCheckHistoryID
		LEFT JOIN @tRP_UN_SchoRGC RGC ON RGC.ScholarshipID = S.ScholarshipID AND RGC.iCheckStatusID = Ch.iCheckStatusID
		WHERE O.OperTypeID <> 'RGC' -- Exclus les paiements au Receveur général du Canada
		ORDER BY 
			P.PlanDesc,
			BourseNo,
			S.ScholarshipNo,
			SH.LastName,
			SH.FirstName,
			C.ConventionNo
	END
    */
END

-- EXEC RP_UN_ScholarshipAccounting_IQEE '2009-07-01', '2009-07-31', 'S'