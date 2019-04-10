/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOper
Description         :	Rapport journalier des opérations 
Valeurs de retours  :	Dataset de données
				OperDate		DATETIME	Date de l'opération. 
				ConventionNo	VARCHAR(15)	Numéro unique de la convention généré selon la formule de Gestion Universitas. 
											C'est le numéro que l'usager voit, qui est inscrit sur les dossiers et 
											sur les documents expédiés au client
				SubscriberName 	VARCHAR		Concaténation du nom et prénom du souscripteur
				OperTypeID		CHAR(3)		ID unique du type d'opération 
				OperTypeDesc	VARCHAR(75)	Type d'opération. 
				Cotisation 		INTEGER		Montant d'épargnes de la transaction
				Fee 			MONEY		Montant de frais de la transaction
				fCESG			MONEY		Somme des montants provenant de la SCEE
				fACESG			MONEY		Somme des montants provenant de la SCEE+
				fCLB 			MONEY		Somme des montants provenant du BEC
				BenefInsur 		MONEY		Somme des montants de prime d'assurance bénéficiaire de la transaction. 
				SubscInsur 		MONEY		Somme des Montant de prime d'assurance souscripteur de la transaction. 
				TaxOnInsur 		MONEY		Somme des taxes sur les primes d'assurances de la transaction,
				INMAmount 		MONEY		Somme des intérêts sur montant souscrit
				INCAmount 		MONEY		Somme des intérêts chargés au client
				ITRAmount 		MONEY		Somme des intérêts (Transfert IN)
				ISTAmount 		MONEY		Somme des intérêts sur la PCEE provenant d'un transfert IN
				INSAmount 		MONEY		Somme des intérêts sur la SCEE
				FDIAmount 		MONEY		Somme des frais disponible
				IBCAmount 		MONEY		Somme des intérêts sur le BEC
				ISPAmount		MONEY		Somme des Int. Sur la SCEE+ 	(IS+)
				Total   		MONEY		Total = 
												Somme (Cotisation )+	Somme (Fee )+ 		Somme (BenefInsur)+ 
												Somme (SubscInsur+ 	Somme (TaxOnInsur)+ 	Somme (INMAmount)+ 
												Somme (INCAmount)+ 	Somme (ITRAmount)+ 	Somme (ISTAmount)+ 
												Somme (INSAmount)+ 	Somme (FDIAmount)+ 	Somme (fCESG)+
												Somme (fACESG)+ 	Somme (fCLB)+ 		Somme (IBCAmount)+
												Somme (ISPAmount) 

Note                :	ADX000998	IA	2006-06-07	Mireya Gonthier		Adaptation du rapport des opérations journalières			
						ADX0001235	IA	2007-02-14	Alain Quirion		Utilisation de dtRegStartDate pour la date de début de régime
						ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2010-09-29	Donald Huppé		GLPI 4155

exec RP_UN_DailyOper 1, 'TRA', '2010-01-01','2010-05-31','ALL'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOper] (
	@ConnectID INTEGER, 	-- Identifiant unique de la connection	
	@OperTypeID CHAR(3), 	-- Filtre sur le type d'opération.  ('ALL' = tous, ‘AJU’=ajustement, ‘FCB’ = Fonds provenant d'un compte de garantie bloqué, ‘RCB’=Retrait d'un compte de garantie bloqué, ‘INT’=Calcul des intérêts)
	@StartDate DATETIME, 	-- Date de début de la période
	@EndDate DATETIME, 	-- Date de fin de la période
	@ConventionStateID VARCHAR(75)) -- Filtre : ALL = Tous, REEE = en RÉÉÉ, TRA = Transitoire
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@GlobalOperTypeID VARCHAR(20)

	SET @dtBegin = GETDATE()

	IF @OperTypeID = 'ALL'
		SET @GlobalOperTypeID = 'AJU,FCB,RCB,INT,TRA' -- GLPI 4155 : ajout de l'option TRA
	ELSE
		SET @GlobalOperTypeID = @OperTypeID

	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper
		WHERE OperDate BETWEEN @StartDate AND @EndDate
				  AND CHARINDEX(OperTypeID, @GlobalOperTypeID) > 0

	IF @ConventionStateID = 'ALL'
		SELECT    
			V.OperDate,
			C.ConventionNo,
			SubscriberName = CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END,
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,			
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee) ,
			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
	
			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),
			
			INMAmount = SUM(V.INMAmount),
			INCAmount = SUM(V.INCAmount) ,
			ITRAmount = SUM(V.ITRAmount) ,
			ISTAmount = SUM(V.ISTAmount) ,
			INSAmount = SUM(V.INSAmount) ,
			FDIAmount = SUM(V.FDIAmount) ,
			IBCAmount = SUM(V.IBCAmount) ,
			ISPAmount = SUM(V.ISPAmount),
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.INMAmount) + 
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) + 
				SUM(V.INSAmount) + SUM(V.FDIAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount)
		FROM ( 
				SELECT
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
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0 
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID	
				JOIN Un_Oper O ON O.OperID = OT.OperID			
				 
				---------
		      	UNION ALL
		  		---------
		
				SELECT
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
	
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END,
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					FDIAmount = CASE WHEN CO.ConventionOperTypeID = 'FDI' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE (CO.ConventionOperTypeID IN ('INM', 'INC', 'ITR', 'IST', 'INS', 'FDI', 'IBC', 'IS+'))
				  AND (CO.ConventionOperAmount <> 0)				 
				
				---------
		      	UNION ALL
		  		---------
		
				SELECT
					CE.ConventionID,
					O.OperDate,
					O.OperTypeID,
					Cotisation = 0,
					Fee = 0,
					CE.fCESG ,
					CE.fACESG ,
					CE.fCLB ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0
				FROM Un_CESP CE
				JOIN #tOperTable OT ON OT.OperID = CE.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID			
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 
			OR SUM(V.INMAmount) <> 0 
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 
			OR SUM(V.ISTAmount) <> 0 
			OR SUM(V.INSAmount) <> 0 
			OR SUM(V.FDIAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
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
			SubscriberName = CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END,
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,			

			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee) ,
			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
	
			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),
			
			INMAmount = SUM(V.INMAmount),
			INCAmount = SUM(V.INCAmount) ,
			ITRAmount = SUM(V.ITRAmount) ,
			ISTAmount = SUM(V.ISTAmount) ,
			INSAmount = SUM(V.INSAmount) ,
			FDIAmount = SUM(V.FDIAmount) ,
			IBCAmount = SUM(V.IBCAmount) ,
			ISPAmount = SUM(V.ISPAmount),
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.INMAmount) + 
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) + 
				SUM(V.INSAmount) + SUM(V.FDIAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount)
		FROM ( 
				SELECT
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
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0 
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
					AND O.OperTypeID <> 'RCB'
	
		  		---------
		      	UNION ALL
		  		---------
		
				SELECT
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
	
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END,
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					FDIAmount = CASE WHEN CO.ConventionOperTypeID = 'FDI' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE (CO.ConventionOperTypeID IN ('INM', 'INC', 'ITR', 'IST', 'INS', 'FDI', 'IBC', 'IS+'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
				  AND O.OperTypeID <> 'RCB'
	   			---------
		      	UNION ALL
		  		---------
		
				SELECT
					CE.ConventionID,
					O.OperDate,
					O.OperTypeID,
					Cotisation = 0,
					Fee = 0,
					CE.fCESG ,
					CE.fACESG ,
					CE.fCLB ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0
				FROM Un_CESP CE
				JOIN #tOperTable OT ON OT.OperID = CE.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1))) OR (ISNULL(C.dtRegStartDate, @EndDate+1) < '2003-01-01'))
					AND O.OperTypeID <> 'RCB'
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 
			OR SUM(V.INMAmount) <> 0 
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 
			OR SUM(V.ISTAmount) <> 0 
			OR SUM(V.INSAmount) <> 0 
			OR SUM(V.FDIAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
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
			SubscriberName = CASE
						WHEN H.IsCompany = 0 THEN RTRIM(H.LastName) + ', ' + RTRIM(H.FirstName)
						ELSE RTRIM(H.LastName)
					END,
			V.OperTypeID,
			OT.OperTypeDesc,
			Regime = P.PlanDesc,
			GrRegime = RR.vcDescription,
			OrderOfPlanInReport,			
			
			Cotisation = SUM(V.Cotisation),
			Fee = SUM(V.Fee) ,
			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
	
			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),
			
			INMAmount = SUM(V.INMAmount),
			INCAmount = SUM(V.INCAmount) ,
			ITRAmount = SUM(V.ITRAmount) ,
			ISTAmount = SUM(V.ISTAmount) ,
			INSAmount = SUM(V.INSAmount) ,
			FDIAmount = SUM(V.FDIAmount) ,
			IBCAmount = SUM(V.IBCAmount) ,
			ISPAmount = SUM(V.ISPAmount),
	
			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.INMAmount) + 
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) + 
				SUM(V.INSAmount) + SUM(V.FDIAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount)
		FROM ( 
				SELECT
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
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0 
				FROM Un_Cotisation CO
				JOIN dbo.Un_Unit U ON U.UnitID = CO.UnitID
				JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
					OR O.OperTypeID = 'RCB'
		  		---------
		      		UNION ALL
		  		---------
		
				SELECT
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
	
					INMAmount = CASE WHEN CO.ConventionOperTypeID = 'INM' THEN CO.ConventionOperAmount ELSE 0 END,
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					FDIAmount = CASE WHEN CO.ConventionOperTypeID = 'FDI' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO
				JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
				JOIN #tOperTable OT ON OT.OperID = CO.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				WHERE ((CO.ConventionOperTypeID IN ('INM', 'INC', 'ITR', 'IST', 'INS', 'FDI', 'IBC', 'IS+'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01'))
					OR O.OperTypeID = 'RCB'
	   			---------
		      	UNION ALL
		  		---------
		
				SELECT
					CE.ConventionID,
					O.OperDate,
					O.OperTypeID,
					Cotisation = 0,
					Fee = 0,
					CE.fCESG ,
					CE.fACESG ,
					CE.fCLB ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INMAmount = 0,
					INCAmount = 0,
					ITRAmount = 0,
					ISTAmount = 0,
					INSAmount = 0,
					FDIAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0
				FROM Un_CESP CE
				JOIN #tOperTable OT ON OT.OperID = CE.OperID
				JOIN Un_Oper O ON O.OperID = OT.OperID
				LEFT JOIN dbo.Un_Convention C ON C.ConventionID = CE.ConventionID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(ISNULL(C.dtRegStartDate, @EndDate+1)) AND ISNULL(C.dtRegStartDate, @EndDate+1) >= '2003-01-01')
					OR O.OperTypeID = 'RCB'
			) V
		JOIN Un_OperType OT ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
		GROUP BY 
			V.OperDate, 
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport
		HAVING SUM(V.Cotisation) <> 0
			OR SUM(V.Fee) <> 0
			OR SUM(V.fCESG) <> 0 
			OR SUM(V.fACESG)  <> 0 
			OR SUM(V.fCLB) <> 0
			OR SUM(V.BenefInsur) <> 0
			OR SUM(V.SubscInsur) <> 0 
			OR SUM(V.TaxOnInsur) <> 0 
			OR SUM(V.INMAmount) <> 0 
			OR SUM(V.INCAmount) <> 0 
			OR SUM(V.ITRAmount) <> 0 
			OR SUM(V.ISTAmount) <> 0 
			OR SUM(V.INSAmount) <> 0 
			OR SUM(V.FDIAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
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
				'Rapport journalier des opérations selon le type d''opération '+CAST(@OperTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOper',
				'EXECUTE RP_UN_DailyOper @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @OperTypeID ='+CAST(@OperTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
END


