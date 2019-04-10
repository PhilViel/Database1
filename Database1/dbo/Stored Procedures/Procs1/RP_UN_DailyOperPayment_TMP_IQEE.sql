
/********************************************************************************************************************
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
													Donald Huppé		Création de cette procédure temporaire pour un rapport temporaire (RapOpJournalierePayment_TMP_IQEE.rdl)
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2016-04-15	Donald Huppé		Ajout du destinataire du Chèque (comme dans RP_UN_DailyOperPayment)
										2016-05-30	Donald Huppé		Ajout du destinaire du Chèque du OUt fait la même date que le OUT qui n'a pas de chèque
										2016-06-01	Donald Huppé		Correction suite au 2016-05-30

exec RP_UN_DailyOperPayment_TMP_IQEE 1, '2016-01-01', '2016-05-27', 'OUT', 'ALL'
exec RP_UN_DailyOperPayment_TMP_IQEE 1, '2016-01-01', '2016-05-27', 'OUT', 'REEE'
exec RP_UN_DailyOperPayment_TMP_IQEE 1, '2016-01-01', '2016-05-31', 'OUT', 'ALL'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperPayment_TMP_IQEE] (
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
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end
					+ case when dc.OperID is null and dcOTHER.ConventionID is not NULL then ' ->?? ' + upper(isnull(hdOTHER.FirstName,'') + ' ' + isnull(hdOTHER.LastName,'')) else '' end,
			V.OperTypeID,
			OT.OperTypeDesc,
			CH.dtEmission,
			CH.iCheckNumber,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,			
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
					
			CBQAmount = SUM(V.CBQAmount),
					
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),
			ICQAmount = SUM(V.ICQAmount),
			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),
			IMQAmount = SUM(V.IMQAmount),

			MMQAmount = SUM(V.MMQAmount),
	
			Total = /*SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + */
				SUM(V.CBQAmount) + SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.ICQAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount) + SUM(V.IMQAmount) + SUM(V.MMQAmount)
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
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
										 
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

					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,

					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END
										
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+' , 'CBQ', 'IQI', 'MMQ', 'IMQ', 'MIM', 'ICQ', 'IIQ', 'III'))
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
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
					
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID

			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID	
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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

		LEFT JOIN (
			select o.OperID, p.iPayeeID--, iOperationPayeeID
			from un_oper o
			JOIN (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		LEFT JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID


		LEFT JOIN (
			select v.ConventionID, v.OTHERCHQ_OperDate, iPayeeID = max(P.iPayeeID)
			from (
				select
					u.ConventionID, OTHERCHQ_OperDate = o.OperDate, iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_Cotisation ct on o.OperID = ct.OperID
				join Un_Unit u on ct.UnitID = u.UnitID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				group by u.ConventionID, o.OperDate, co.iOperationID
				) v
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
			GROUP BY v.ConventionID, v.OTHERCHQ_OperDate	  
			) dcOTHER on dcOTHER.iPayeeID <> h.HumanID and dcOTHER.ConventionID = c.ConventionID and dcOTHER.OTHERCHQ_OperDate = v.OperDate --and dcOTHER.iOperationPayeeID <> dc.iOperationPayeeID
		LEFT JOIN dbo.Mo_Human hdOTHER on dcOTHER.iPayeeID = hdOTHER.HumanID


		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			Ch.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName

			,dcOTHER.ConventionID,hdOTHER.FirstName,hdOTHER.LastName

		HAVING /*SUM(V.Cotisation) <> 0
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
			
			OR */SUM(V.CBQAmount) <> 0
					
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0
			OR SUM(V.IMQAmount) <> 0

			OR SUM(V.MMQAmount) <> 0
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
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end
					+ case when dc.OperID is null and dcOTHER.ConventionID is not NULL then ' ->?? ' + upper(isnull(hdOTHER.FirstName,'') + ' ' + isnull(hdOTHER.LastName,'')) else '' end,
			V.OperTypeID,
			OT.OperTypeDesc,
			CH.dtEmission,
			CH.iCheckNumber,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
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
					
			CBQAmount = SUM(V.CBQAmount),
					
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),
			ICQAmount = SUM(V.ICQAmount),
			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),
			IMQAmount = SUM(V.IMQAmount),

			MMQAmount = SUM(V.MMQAmount),
	
			Total = /*SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + */
				SUM(V.CBQAmount) + SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.ICQAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount) + SUM(V.IMQAmount) + SUM(V.MMQAmount)
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
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
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
					
					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,

					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END
										
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+' , 'CBQ', 'IQI', 'MMQ', 'IMQ', 'MIM', 'ICQ', 'IIQ', 'III'))
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
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
					
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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

		LEFT JOIN (
			select o.OperID, p.iPayeeID
			from un_oper o
			JOIN (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		LEFT JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		LEFT JOIN (
			select v.ConventionID, v.OTHERCHQ_OperDate, iPayeeID = max(P.iPayeeID)
			from (
				select
					u.ConventionID, OTHERCHQ_OperDate = o.OperDate, iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_Cotisation ct on o.OperID = ct.OperID
				join Un_Unit u on ct.UnitID = u.UnitID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				group by u.ConventionID, o.OperDate, co.iOperationID
				) v
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
			GROUP BY v.ConventionID, v.OTHERCHQ_OperDate
			) dcOTHER on dcOTHER.iPayeeID <> h.HumanID and dcOTHER.ConventionID = c.ConventionID and dcOTHER.OTHERCHQ_OperDate = v.OperDate
		LEFT JOIN dbo.Mo_Human hdOTHER on dcOTHER.iPayeeID = hdOTHER.HumanID

		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			CH.dtEmission,
			CH.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName
			,dcOTHER.ConventionID,hdOTHER.FirstName,hdOTHER.LastName
		HAVING /*SUM(V.Cotisation) <> 0
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
			
			OR */SUM(V.CBQAmount) <> 0
					
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0
			OR SUM(V.IMQAmount) <> 0

			OR SUM(V.MMQAmount) <> 0

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
					+ case when dc.OperID is not null then ' ->' + upper(isnull(hd.FirstName,'') + ' ' + isnull(hd.LastName,'')) else '' end
					+ case when dc.OperID is null and dcOTHER.ConventionID is not NULL then ' ->?? ' + upper(isnull(hdOTHER.FirstName,'') + ' ' + isnull(hdOTHER.LastName,'')) else '' end,
			V.OperTypeID,
			OT.OperTypeDesc,
			CH.dtEmission,
			CH.iCheckNumber,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,
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
					
			CBQAmount = SUM(V.CBQAmount),
					
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),
			ICQAmount = SUM(V.ICQAmount),
			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),
			IMQAmount = SUM(V.IMQAmount),

			MMQAmount = SUM(V.MMQAmount),
	
			Total = /*SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + 
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) + */
				SUM(V.CBQAmount) + SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.ICQAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount) + SUM(V.IMQAmount) + SUM(V.MMQAmount)
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
					ISPAmount = 0 ,
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
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
					
					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,

					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END
					
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'INS', 'IBC', 'IS+' , 'CBQ', 'IQI', 'MMQ', 'IMQ', 'MIM', 'ICQ', 'IIQ', 'III'))
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
					
					CBQAmount = 0,
					
					IQIAmount = 0,
					MIMAmount = 0,
					ICQAmount = 0,
					IIQAmount = 0,
					IIIAmount = 0,
					IMQAmount = 0,

					MMQAmount = 0
				FROM Un_CESP G
				JOIN #tOperTable OT ON OT.OperID = G.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID	
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = G.ConventionID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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

		LEFT JOIN (
			select o.OperID, p.iPayeeID
			from un_oper o
			JOIN (
				select o.OperID, co.iOperationID,iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				--and o.OperID = 25403991
				group by o.OperID, co.iOperationID
				) v on o.OperID = v.OperID
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
				  
			) dc on dc.OperID = v.OperID and dc.iPayeeID <> h.HumanID
		LEFT JOIN dbo.Mo_Human hd on dc.iPayeeID = hd.HumanID

		LEFT JOIN (
			select v.ConventionID, v.OTHERCHQ_OperDate, iPayeeID = max(P.iPayeeID)
			from (
				select
					u.ConventionID, OTHERCHQ_OperDate = o.OperDate, iOperationPayeeIDBef = MAX(cop.iOperationPayeeID)
				from un_oper o
				JOIN #tOperTable OT ON OT.OperID = o.OperID
				join Un_Cotisation ct on o.OperID = ct.OperID
				join Un_Unit u on ct.UnitID = u.UnitID
				JOIN Un_OperLinkToCHQOperation ol on ol.OperID = o.OperID
				JOIN CHQ_Operation co on co.iOperationID = ol.iOperationID
				JOIN CHQ_OperationPayee cop on cop.iOperationID = co.iOperationID
				where cop.iPayeeChangeAccepted in ( 0,1)
				group by u.ConventionID, o.OperDate, co.iOperationID
				) v
			JOIN CHQ_OperationPayee cop on cop.iOperationPayeeID = v.iOperationPayeeIDBef
			JOIN CHQ_Payee P ON P.iPayeeID = cOP.iPayeeID
			GROUP BY v.ConventionID, v.OTHERCHQ_OperDate	  
			) dcOTHER on dcOTHER.iPayeeID <> h.HumanID and dcOTHER.ConventionID = c.ConventionID and dcOTHER.OTHERCHQ_OperDate = v.OperDate
		LEFT JOIN dbo.Mo_Human hdOTHER on dcOTHER.iPayeeID = hdOTHER.HumanID

		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,		
			CH.dtEmission,
			Ch.iCheckNumber,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
			,dc.OperID,hd.LastName,hd.FirstName
			,dcOTHER.ConventionID,hdOTHER.FirstName,hdOTHER.LastName
		HAVING /*SUM(V.Cotisation) <> 0
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
			
			OR */SUM(V.CBQAmount) <> 0
					
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0
			OR SUM(V.IMQAmount) <> 0

			OR SUM(V.MMQAmount) <> 0

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
				'Rapport TEMPORAIRE (RP_UN_DailyOperPayment_TMP_IQEE) journalier des opérations (Décaissement) selon le type d''opération '+CAST(@OperTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperPayment_TMP_IQEE',
				'EXECUTE RP_UN_DailyOperPayment_TMP_IQEE @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @OperTypeID ='+CAST(@OperTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
END


