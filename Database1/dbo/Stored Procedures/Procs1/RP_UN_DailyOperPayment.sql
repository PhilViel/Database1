/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOperPayment
Description         :	Rapport des opérations journalières (Décaissement)
Valeurs de retours  :	Dataset de données
				Dataset :
					ConventionNo	VARCHR(20)	Numéro de la convention
					SubscriberName	VARCHAR(75)	Nom et prénom du souscripteur (Ex Caron, Dany)
					dtEmission		DATETIME	Date d’émission du chèque sur l’opération
					iCheckNumber	INTEGER		Numéro du chèque
					Cotisation		MONEY		Montant d’épargne de l’opération
					Fee				MONEY		Montant de frais de l’opération
					BenefInsur		MONEY		Montant d’assurance bénéficiaire de l’opération
					SubsInsur		MONEY		Montant d’assurance souscripteur de l’opération
					TaxOnInsur		MONEY		Montant des taxes sur l’opération
					INCAmount		MONEY		Montant des intérêts chargés au souscripteur
					ITRINMAmount	MONEY		Montant des intérêts chargés au promoteur
					fCESG			MONEY		Montant de SCEE payé sur l’opération (OUT).
					INSAmount		MONEY		Montant des intérêts SCEE payés l’opération (OUT).
					fACESG			MONEY		Montant de SCEE+ payé sur l’opération (OUT).
					ISPAmount		MONEY		Montant des intérêts SCEE+ payés sur l’opération (OUT).
					fCLB			MONEY		Montant de BEC payé sur l’opération (OUT).
					IBCAmount		MONEY		Montant des intérêts BEC payés sur l’opération (OUT).
					fTotal			MONEY		Montant total. Somme de toutes les colonnes.

Note                :	ADX0001326	IA	2007-04-30	Alain Quirion		Création
										2009-09-10	Donald Huppé		(mis en prod le 22-09-2009)	(GLPI 1948) Exclure Les TIO, ils seront dans un nouveau rapport de TIO - mis en prod le 22-09-2009
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2010-10-13	Donald Huppé		GLPI 4394 - ajout de ISTAmount
										2010-12-14	Donald Huppé		Enlever RR.vcDescription dans le select du dernier else
										2011-06-07	Donald Huppé		GLPI 5639 : Ajout du champ INMAmount, qui sera additionné au champ ITRAmount. Dans cerapport, INMAmount sera souvent à 0 car on ne remet pas les rendement dans les retraits et les résiliations.
										2014-08-26	Donald Huppé		glpi 12179 : Ajout du nouveau destinaire de chèque (authorisé ou non), concaténé au nom du souscripteur
exec RP_UN_DailyOperPayment 1, '2014-08-01', '2014-08-25', 'ALL', 'ALL'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperPayment] (
	@ConnectID	INTEGER,		--	ID de connexion
	@StartDate	DATETIME,		--	Date de début du rapport
	@EndDate	DATETIME,		--	Date de fin du rapport
	@OperTypeID	CHAR(3),		--	Type d’opéartion (‘ALL’ = tous, ‘RET’=retrait, ‘RES’= résiliation, ‘OUT’ = transfert OUT)
	@ConventionStateID	VARCHAR(4)) --	Filtre du rapport (‘ALL’ = tous, ‘REEE’ = en RÉÉÉ, ‘TRA’ = transitoire)

AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@GlobalOperTypeID VARCHAR(20)

	SET @dtBegin = GETDATE()

	IF @OperTypeID = 'ALL'
		SET @GlobalOperTypeID = 'RET,RES,OUT'
	ELSE 
		SET @GlobalOperTypeID = @OperTypeID

	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o
		left JOIN Un_Tio TIO on TIO.iOUTOperID = o.operid
		WHERE OperDate BETWEEN @StartDate AND @EndDate
				AND CHARINDEX(OperTypeID, @GlobalOperTypeID) > 0			
				AND TIO.iOUTOperID is null -- exclure les TIO

	IF @ConventionStateID = 'ALL'
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,			
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			CH.dtEmission,
			CH.iCheckNumber,
			
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee) ,

			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
			
			INCAmount = SUM(V.INCAmount) ,
			ITRAmount = SUM(V.ITRAmount) ,
			INSAmount = SUM(V.INSAmount) ,
			IBCAmount = SUM(V.IBCAmount) ,
			ISPAmount = SUM(V.ISPAmount),
			ISTAmount = SUM(V.ISTAmount),
			INMAmount = SUM(V.INMAmount), -- On en retrouve uniquement pour les OUT
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + SUM(V.ISTAmount) + SUM(V.INMAmount)
			
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
				
					INCAmount = 0,
					ITRAmount = 0,					
					INSAmount = 0,					
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
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
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END 
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+', 'IST', 'INM'))
				  AND (CO.ConventionOperAmount <> 0)				 
				
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
	
					INCAmount = 0,
					ITRAmount = 0,
					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID

			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			P.PlanDesc,
			OrderOfPlanInReport,
			RR.vcDescription,
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			Ch.iCheckNumber
			,dc.OperID,hd.LastName,hd.FirstName
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 			
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 			
			OR SUM(V.INSAmount) <> 0 			
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
			OR SUM(V.ISTAmount) <> 0
			OR SUM(V.INMAmount) <> 0
		ORDER BY 
			V.OperDate, 
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo
	ELSE IF @ConventionStateID = 'REEE'
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			CH.dtEmission,
			CH.iCheckNumber,
			
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
	
			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),
			
			INCAmount = SUM(V.INCAmount),
			ITRAmount = SUM(V.ITRAmount),			
			INSAmount = SUM(V.INSAmount),			
			IBCAmount = SUM(V.IBCAmount),
			ISPAmount = SUM(V.ISPAmount),
			ISTAmount = SUM(V.ISTAmount),
			INMAmount = SUM(V.INMAmount), -- On en retrouve uniquement pour les OUT
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + 
				SUM(V.INCAmount) + SUM(V.ITRAmount) + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + SUM(ISTAmount) + SUM(V.INMAmount)
			
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
					
					INCAmount = 0,
					ITRAmount = 0,					
					INSAmount = 0,					
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
					
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
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+', 'IST', 'INM'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
	 
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
						
					INCAmount = 0,
					ITRAmount = 0,					
					INSAmount = 0,					
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
					
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID
		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			CH.iCheckNumber
			,dc.OperID,hd.LastName,hd.FirstName
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 			
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 		
			OR SUM(V.INSAmount) <> 0 			
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
			OR SUM(V.ISTAmount) <> 0
			OR SUM(V.INMAmount) <> 0
		ORDER BY 
			V.OperDate, 
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	ELSE
		SELECT     
			V.OperDate,
			C.ConventionNo,
			SubscriberName = isnull(CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END ,'')
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end,
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
			--RR.vcDescription, -- enlevé le 2010-12-14
			CH.dtEmission,
			CH.iCheckNumber,
			
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
	
			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),			
			
			INCAmount = SUM(V.INCAmount),
			ITRAmount = SUM(V.ITRAmount),			
			INSAmount = SUM(V.INSAmount),			
			IBCAmount = SUM(V.IBCAmount),
			ISPAmount = SUM(V.ISPAmount),
			ISTAmount = SUM(V.ISTAmount),
			INMAmount = SUM(V.INMAmount),-- On en retrouve uniquement pour les OUT
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur)  + 
				SUM(V.INCAmount) + SUM(V.ITRAmount)  + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + SUM(V.ISTAmount) + SUM(V.INMAmount)
			
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
					
					INCAmount = 0,
					ITRAmount = 0,					
					INSAmount = 0,					
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
	
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
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+', 'IST', 'INM'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
	 
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
					
					INCAmount = 0,
					ITRAmount = 0,					
					INSAmount = 0,					
					IBCAmount = 0,
					ISPAmount = 0,
					ISTAmount = 0,
					INMAmount = 0
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID -- select * from UN_PLAN
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		-- Va chercher les informations des chèques
		LEFT JOIN Un_OperLinkToCHQOperation L ON L.OperID = V.OperID
		LEFT JOIN (
					SELECT iCheckID = MAX(CH.iCheckID), OD.iOperationID
					FROM CHQ_OperationDetail OD
					JOIN CHQ_CheckOperationDetail COD ON COD.iOperationDetailID = OD.iOperationDetailID		
					JOIN CHQ_Check CH ON CH.iCheckID = COD.iCheckID					
					GROUP BY OD.iOperationID) R ON R.iOperationID = L.iOperationID
		LEFT JOIN CHQ_Check CH ON CH.iCheckID = R.iCheckID AND CH.iCheckStatusID IN (1,2,4)

		left join (
			select o.OperID, p.iPayeeID
			from un_oper o
			join (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				join CHQ_Operation co on co.iOperationID = ol.iOperationID
				join CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			join CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		left JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID
		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,		
			CH.dtEmission,
			Ch.iCheckNumber
			,dc.OperID,hd.LastName,hd.FirstName
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 			
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 			
			OR SUM(V.INSAmount) <> 0 			
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
			OR SUM(V.ISTAmount) <> 0
			OR SUM(V.INMAmount) <> 0
		ORDER BY 
			V.OperDate, 
			V.OperTypeID,
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	DROP TABLE #tOperTable

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport journalier des opérations (Décaissement) selon le type d''opération '+CAST(@OperTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperPayment',
				'EXECUTE RP_UN_DailyOperPayment @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @OperTypeID ='+CAST(@OperTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
END


