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
Nom                 :	RP_UN_ScholarshipAccounting
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
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_ScholarshipAccountingBACKUP] (
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
		iCheckID INTEGER PRIMARY KEY )

	INSERT INTO @tCHQ_Check
		SELECT iCheckID
		FROM CHQ_Check
		WHERE iCheckStatusID IN (4,6)
			AND dtEmission BETWEEN @StartDate AND @EndDate

	-- Va chercher tous les opérations dont le dernier chèque a été imprimé dans l'interval donné
	DECLARE @tRP_UN_SchoCheck TABLE (
		OperID INTEGER PRIMARY KEY,
		vcPayeeName VARCHAR(87) NULL,
		iCheckNumber INTEGER NULL,
		dtEmission DATETIME NOT NULL,
		fAmount DECIMAL(18,2) NOT NULL )

	INSERT INTO @tRP_UN_SchoCheck
		SELECT DISTINCT
			L.OperID,
			vcPayeeName = ISNULL(H.LastName,'')+', '+ISNULL(H.FirstName,''),
			C.iCheckNumber,
			C.dtEmission,
			C.fAmount
		FROM @tCHQ_Check Ct
		JOIN CHQ_CheckOperationDetail COD ON Ct.iCheckID = COD.iCheckID
		JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN Un_OperLinkToCHQOperation L ON OD.iOperationID = L.iOperationID
		JOIN CHQ_Check C ON C.iCheckID = Ct.iCheckID
		JOIN dbo.Mo_Human H ON H.HumanID = C.iPayeeID

	-- Va chercher les différents numéro de convention
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
		OperID INTEGER NOT NULL,
		ConventionOperTypeID CHAR(3) NOT NULL,
		ConventionOperAmount MONEY NOT NULL )

	INSERT INTO @tRP_UN_SchoConvOper
		SELECT
			SC.OperID,
			CO.ConventionOperTypeID,
			ConventionOperAmount = -SUM(CO.ConventionOperAmount)
		FROM @tRP_UN_SchoCheck SC
		JOIN Un_ConventionOper CO ON CO.OperID = SC.OperID
		GROUP BY
			SC.OperID,
			CO.ConventionOperTypeID

	-- Table de tous les montants d'argent de type opération sur convention pour les opérations en question.
	DECLARE @tRP_UN_SchoRGC TABLE (
		ScholarshipID INTEGER PRIMARY KEY,
		fRGC MONEY NOT NULL,
		fBRS MONEY NOT NULL )

	INSERT INTO @tRP_UN_SchoRGC
		SELECT
			M.ScholarshipID,
			fRGC = SUM(CO.ConventionOperAmount),
			fBRS = 
				SUM(	CASE 
							WHEN CO.COnventionOperTypeID = 'BRS' THEN
								CO.ConventionOperAmount
						ELSE 0
						END
					)
		FROM @tRP_UN_SchoCheck SC
		JOIN Un_ConventionOper CO ON CO.OperID = SC.OperID
		JOIN Un_ScholarshipPmt M ON SC.OperID = M.OperID
		JOIN Un_Oper O ON O.OperID = SC.OperID
		WHERE O.OperTypeID = 'RGC'
		GROUP BY
			M.ScholarshipID

	-- TRI selon le nom, prénom du Bénéficiaire ensuite par No de convention
	IF @cOrder = 'B'
	BEGIN
		SELECT
			PlanDesc = P.PlanDesc,
			BourseNo = 'Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)),
			C.ConventionNo,
			Beneficiaire = ISNULL(CH.vcPayeeName,''),
			Souscripteur = ISNULL(SH.LastName,'')+', '+ISNULL(SH.FirstName,''),
			UnitQty =
				CASE O.OperTypeID
					WHEN 'PAE' THEN U.UnitQty 
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
				ISNULL(RGC.fRGC,0)
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
		LEFT JOIN @tRP_UN_SchoConvOper OB ON OB.OperID = O.OperID AND OB.ConventionOperTypeID = 'BRS'
		LEFT JOIN @tRP_UN_SchoConvOper AV ON AV.OperID = O.OperID AND AV.ConventionOperTypeID = 'AVC'
		LEFT JOIN @tRP_UN_SchoConvOper INMI ON INMI.OperID = O.OperID AND INMI.ConventionOperTypeID = 'INM'AND P.PlanTypeID = 'IND'--NDIVIDUEL 
		LEFT JOIN @tRP_UN_SchoConvOper INS ON INS.OperID = O.OperID AND INS.ConventionOperTypeID = 'INS'-- IN ('INS', 'ITR')
		LEFT JOIN @tRP_UN_SchoConvOper IST ON IST.OperID = O.OperID AND IST.ConventionOperTypeID = 'IST'
		LEFT JOIN @tRP_UN_SchoConvOper ISP ON ISP.OperID = O.OperID AND ISP.ConventionOperTypeID = 'IS+' 
		LEFT JOIN @tRP_UN_SchoConvOper IBC ON IBC.OperID = O.OperID AND IBC.ConventionOperTypeID = 'IBC' 
		LEFT JOIN @tRP_UN_SchoConvOper ITR ON ITR.OperID = O.OperID AND ITR.ConventionOperTypeID = 'ITR'
		LEFT JOIN @tRP_UN_SchoConvOper INMC ON INMC.OperID = O.OperID AND INMC.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'COL' --COLLECTIF
		LEFT JOIN (
			SELECT 
				CE.OperID, 
				fCESG = -SUM(CE.fCESG),
				fACESG = -SUM(CE.fACESG),
				fCLB = -SUM (CE.fCLB)
			FROM @tRP_UN_SchoCheck Ch
			JOIN UN_CESP CE ON CE.OperID = Ch.OperID
			GROUP BY CE.OperID
			) GG ON GG.OperID = O.OperID
		LEFT JOIN @tRP_UN_SchoRGC RGC ON RGC.ScholarshipID = S.ScholarshipID
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
			PlanDesc = P.PlanDesc,
			BourseNo = 'Bourse ' + RTRIM(CAST(S.ScholarshipNo AS VARCHAR)),
			C.ConventionNo,
			Beneficiaire = ISNULL(CH.vcPayeeName,''),
			Souscripteur = ISNULL(SH.LastName,'')+', '+ISNULL(SH.FirstName,''),
			UnitQty =
				CASE O.OperTypeID
					WHEN 'PAE' THEN U.UnitQty 
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
				ISNULL(RGC.fRGC,0)		
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
		LEFT JOIN @tRP_UN_SchoConvOper OB ON OB.OperID = O.OperID AND OB.ConventionOperTypeID = 'BRS'
		LEFT JOIN @tRP_UN_SchoConvOper AV ON AV.OperID = O.OperID AND AV.ConventionOperTypeID = 'AVC'
		LEFT JOIN @tRP_UN_SchoConvOper INMI ON INMI.OperID = O.OperID AND INMI.ConventionOperTypeID = 'INM'AND P.PlanTypeID = 'IND'--NDIVIDUEL 
		LEFT JOIN @tRP_UN_SchoConvOper INS ON INS.OperID = O.OperID AND INS.ConventionOperTypeID = 'INS'
		LEFT JOIN @tRP_UN_SchoConvOper IST ON IST.OperID = O.OperID AND IST.ConventionOperTypeID = 'IST'
		LEFT JOIN @tRP_UN_SchoConvOper ISP ON ISP.OperID = O.OperID AND ISP.ConventionOperTypeID = 'IS+' 
		LEFT JOIN @tRP_UN_SchoConvOper IBC ON IBC.OperID = O.OperID AND IBC.ConventionOperTypeID = 'IBC' 
		LEFT JOIN @tRP_UN_SchoConvOper ITR ON ITR.OperID = O.OperID AND ITR.ConventionOperTypeID = 'ITR'
		LEFT JOIN @tRP_UN_SchoConvOper INMC ON INMC.OperID = O.OperID AND INMC.ConventionOperTypeID = 'INM' AND P.PlanTypeID = 'COL' --COLLECTIF
		LEFT JOIN (
			SELECT 
				CE.OperID, 
				fCESG = -SUM(CE.fCESG),
				fACESG = -SUM(CE.fACESG),
				fCLB = -SUM (CE.fCLB)
			FROM @tRP_UN_SchoCheck Ch
			JOIN UN_CESP CE ON CE.OperID = Ch.OperID
			GROUP BY CE.OperID
			) GG ON GG.OperID = O.OperID
		LEFT JOIN @tRP_UN_SchoRGC RGC ON RGC.ScholarshipID = S.ScholarshipID
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