/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	psOPER_RapportDesChequesImprimes
Description         :	Rapport des chèques imprimés
Valeurs de retours  :	Dataset de données

Note                :	
					2012-10-12	Donald Huppé	    Création
                    2017-12-12  Pierre-Luc Simard   Ajout du compte RST dans le compte BRS

exec psOPER_RapportDesChequesImprimes '2012-10-09' , '2012-10-09' , 1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportDesChequesImprimes] (
	@dtDateFrom DATETIME, -- Date de début de l'intervalle des opérations
	@dtDateTo DATETIME, -- Date de fin de l'intervalle des opérations
	@iGroupeRegime	INT)
AS
BEGIN

-- drop table #tOperTable

	SELECT 
		ch.iCheckID, 
		ch.iCheckNumber,
		ch.dtEmission, 
		O.OperID, 
		O.OperTypeID, 
		O.OperDate,
		ch.fAmount,
		dtHistory = max(LEFT(CONVERT(VARCHAR, hi.dtHistory, 120), 10))
	INTO #tOperTable
	FROM 
		CHQ_Check ch
		JOIN Un_Plan P ON ch.iID_Regime = P.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON P.iID_Regroupement_Regime = RR.iID_Regroupement_Regime
		JOIN CHQ_CheckOperationDetail COD ON ch.iCheckID = COD.iCheckID
		JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
		JOIN CHQ_Operation CO ON OD.iOperationID = CO.iOperationID
		JOIN Un_OperLinkToCHQOperation OLO ON CO.iOperationID = OLO.iOperationID
		JOIN CHQ_CheckHistory hi ON hi.iCheckID = ch.iCheckID AND hi.iCheckStatusID = 4
		join UN_OPER O on OLO.operID = O.OperID
	WHERE
		ch.iCheckStatusID = 4
		and (RR.iID_Regroupement_Regime = @iGroupeRegime OR @iGroupeRegime = 0)
		--and iCheckNumber = 56345 
		--AND ch.iCheckID = 67319
	GROUP BY
		ch.iCheckID, 
		ch.iCheckNumber,
		ch.dtEmission, 
		O.OperID, 
		O.OperTypeID, 
		O.OperDate,
		ch.fAmount
	HAVING max(LEFT(CONVERT(VARCHAR, hi.dtHistory, 120), 10)) BETWEEN @dtDateFrom AND @dtDateTo
	
	SELECT     
	
		O.iCheckNumber,
	
		O.operID,

		TypeChequeOrdre = CASE 
				when V.OperTypeID IN ( 'RGC','PAE','AVC') THEN 2
				when V.OperTypeID IN ( 'RIN') THEN 1
				else 3
				end,

		TypeCheque = CASE 
				when V.OperTypeID IN ( 'RGC','PAE') THEN 'Bourse'
				when V.OperTypeID IN ( 'RIN') THEN 'RI'
				else 'Décaissement'
				end,
		
		V.OperTypeID,
		
		--
		V.OperDate,
		C.ConventionNo,
		SubscriberName = CASE
					WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
					ELSE RTRIM(H.LastName)
				END,			
		
		OT.OperTypeDesc,
		Regime = P.PlanDesc,
		GrRegime = RR.vcDescription,
		OrderOfPlanInReport,
		O.dtEmission,
		DateImpression = O.dtHistory,
		
		--	
		O.fAmount,
		
		Cotisation = SUM(V.Cotisation),
		Fee = SUM(V.Fee) ,

		BenefInsur = SUM(V.BenefInsur),
		SubscInsur = SUM(V.SubscInsur),
		TaxOnInsur = SUM(V.TaxOnInsur),

		fCESG 	= SUM(V.fCESG),
		fACESG = SUM(V.fACESG),
		fCLB = SUM(V.fCLB),
		
		INC = SUM(V.INC) ,
		ITR = SUM(V.ITR) ,
		INS = SUM(V.INS) ,
		IBC = SUM(V.IBC) ,
		ISP = SUM(V.ISP),
		IST = SUM(V.IST), --SELECT * from Un_ConventionOperType where ConventionOperTypeID = 'inm'
		INM = SUM(V.INM), -- On en retrouve uniquement pour les OUT
		BRS = sum(v.BRS),
		AVC = sum(v.AVC),
		RTN = sum(RTN),
		
		CBQ = sum(CBQ),
		MMQ = sum(MMQ),
		
		RendIQEE = SUM(IQI + MIM + ICQ + IIQ + III),
		RendIQEEMaj = SUM(IMQ),

		Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
			SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
			SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
			SUM(V.INC) + SUM(V.ITR) + 
			SUM(V.INS) + SUM(V.IBC) + SUM(V.ISP) + SUM(V.IST) + SUM(V.INM) + sum(v.BRS) + sum(V.AVC) + sum(RTN) 
			+ SUM(IQI + MIM + ICQ + IIQ + III) 
			+ SUM(IMQ)
			+ sum(CBQ)
			+ sum(MMQ)
	FROM ( 
			SELECT
				O.OperID,
				U.ConventionID,
				O.OperDate,
				O.OperTypeID,

				Co.Cotisation,
				Co.Fee,

				fCESG = 0,
				fACESG = 0,
				fCLB = 0,

				Co.BenefInsur,
				Co.SubscInsur,
				Co.TaxOnInsur,	
			
				INC = 0,
				ITR = 0,					
				INS = 0,					
				IBC = 0,
				ISP = 0,
				IST = 0,
				INM = 0,
				BRS = 0,
				AVC = 0,
				RTN = 0,
				
				CBQ = 0,
				MMQ = 0,
				IQI = 0,
				MIM = 0,
				ICQ = 0,
				IMQ = 0,
				IIQ = 0,
				III = 0
				
			FROM Un_Cotisation CO
			JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN #tOperTable OT ON OT.OperID = CO.OperID
			JOIN Un_Oper O ON O.OperID = OT.OperID		
			 
			---------
	      	UNION ALL
	  		---------
	
			SELECT
				O.OperID,
				CO.ConventionID,
				O.OperDate,
				O.OperTypeID,

				Cotisation = 0,
				Fee = 0,

				fCESG = 0, 
				fACESG = 0,
				fCLB = 0 ,

				BenefInsur = 0,
				SubscInsur = 0,
				TaxOnInsur = 0,

				INC = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
				ITR = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
				INS = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
				IBC = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
				ISP = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,
				IST = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
				INM = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END,
				BRS = CASE WHEN CO.ConventionOperTypeID IN ('BRS', 'RST') THEN CO.ConventionOperAmount ELSE 0 END,
				AVC = CASE WHEN CO.ConventionOperTypeID = 'AVC' THEN CO.ConventionOperAmount ELSE 0 END,
				RTN = CASE WHEN CO.ConventionOperTypeID = 'RTN' THEN CO.ConventionOperAmount ELSE 0 END,
				
				CBQ = CASE WHEN ConventionOperTypeID = 'CBQ' THEN ConventionOperAmount ELSE 0 END,
				MMQ = CASE WHEN ConventionOperTypeID = 'MMQ' THEN ConventionOperAmount ELSE 0 END,
				IQI = CASE WHEN ConventionOperTypeID = 'IQI' THEN ConventionOperAmount ELSE 0 END,
				MIM = CASE WHEN ConventionOperTypeID = 'MIM' THEN ConventionOperAmount ELSE 0 END,
				ICQ = CASE WHEN ConventionOperTypeID = 'ICQ' THEN ConventionOperAmount ELSE 0 END,
				IMQ = CASE WHEN ConventionOperTypeID = 'IMQ' THEN ConventionOperAmount ELSE 0 END,
				IIQ = CASE WHEN ConventionOperTypeID = 'IIQ' THEN ConventionOperAmount ELSE 0 END,
				III = CASE WHEN ConventionOperTypeID = 'III' THEN ConventionOperAmount ELSE 0 END	
				
			FROM Un_ConventionOper CO
			JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
			JOIN #tOperTable OT ON OT.OperID = CO.OperID
			JOIN Un_Oper O ON O.OperID = OT.OperID	
			WHERE 1=1
				--AND (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+', 'IST', 'INM', 'BRS','AVC','RTN'))
				--AND (CO.ConventionOperAmount <> 0)				 
			
			---------
	      	UNION ALL
	  		---------
	
			SELECT
				O.OperID,
				G.ConventionID,
				O.OperDate,
				O.OperTypeID,

				Cotisation = 0,
				Fee = 0,

				G.fCESG ,
				G.fACESG ,
				G.fCLB ,

				BenefInsur = 0,
				SubscInsur = 0,
				TaxOnInsur = 0,

				INC = 0,
				ITR = 0,
				INS = 0,
				IBC = 0,
				ISP = 0,
				IST = 0,
				INM = 0,
				BRS = 0,
				AVC = 0,
				RTN = 0,
				
				CBQ = 0,
				MMQ = 0,
				IQI = 0,
				MIM = 0,
				ICQ = 0,
				IMQ = 0,
				IIQ = 0,
				III = 0
				
			FROM Un_CESP G
			JOIN #tOperTable OT ON OT.OperID = G.OperID
			JOIN Un_Oper O ON O.OperID = OT.OperID	
			LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID

		) V
	JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
	JOIN #tOperTable O	ON V.OperID = O.operID
	JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
	JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	-- Va chercher les informations des chèques
	/*
	JOIN (
		SELECT distinct ch.iCheckID, ch.iCheckNumber, ch.dtEmission, O.OperID, O.OperTypeID, hi.dtHistory, O.OperDate,ch.fAmount
		FROM 
			CHQ_Check ch
			JOIN CHQ_CheckOperationDetail COD ON ch.iCheckID = COD.iCheckID
			JOIN CHQ_OperationDetail OD ON COD.iOperationDetailID = OD.iOperationDetailID
			JOIN CHQ_Operation CO ON OD.iOperationID = CO.iOperationID
			JOIN Un_OperLinkToCHQOperation OLO ON CO.iOperationID = OLO.iOperationID
			JOIN CHQ_CheckHistory hi ON hi.iCheckID = ch.iCheckID AND hi.iCheckStatusID = 4
			join UN_OPER O on OLO.operID = O.OperID
		where 1=1
			--and iCheckNumber = 1615 AND ch.iCheckID = 9910
			--AND hi.dtHistory BETWEEN '2012-07-01' AND '2012-10-05'
			--AND O.OperTypeID = 'PAE'
		)CHQ ON V.OperID = CHQ.OperID
		*/
	--where C.ConventionNo = 'U-20070730007'
	--where O.dtHistory <> V.OperDate
	GROUP BY 
		
		O.operID,
		V.OperTypeID, 
		
		-- 
		V.OperDate, 
		
		OT.OperTypeDesc, 
		P.PlanDesc,
		OrderOfPlanInReport,
		RR.vcDescription,
		V.ConventionID, 
		C.ConventionNo, 
		H.LastName, 
		H.FirstName,
		H.IsCompany,
		o.dtEmission,
		O.dtHistory,
		--
		
		o.iCheckNumber,
		O.fAmount

/*
	having abs(O.fAmount) <> abs(SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
			SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
			SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
			SUM(V.INC) + SUM(V.ITR) + 
			SUM(V.INS) + SUM(V.IBC) + SUM(V.ISP) + SUM(V.IST) + SUM(V.INM) + sum(v.BRS) + sum(V.AVC) + sum(RTN) 
			+ SUM(IQI + MIM + ICQ + IIQ + III) 
			+ SUM(IMQ)
			+ sum(CBQ)
			+ sum(MMQ))
*/
	ORDER BY 
		CASE 
				when V.OperTypeID IN ( 'RGC','PAE') THEN 'Bourse'
				when V.OperTypeID IN ( 'RIN') THEN 'RI'
				else 'Décaissement'
				end
		,o.iCheckNumber
			/*
			,V.OperDate, 
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo
			*/
		
END