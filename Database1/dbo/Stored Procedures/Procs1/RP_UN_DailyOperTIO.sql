/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOperTIO
Description         :	Rapport des opérations journalières (TIO)
Valeurs de retours  :	Dataset de données

Note                :	2009-09-11	Donald Huppé	Création
						2010-02-26	Donald Huppé	ajout de l'IQEE
						2010-06-10	Donald Huppé	Ajout des régime et groupe de régime
						2011-03-15	Donald Huppé	Ajout de IIQ dans clause where (était un oubli)<
						2013-08-15	Donald Huppé	Enlever le PrimaryKey dans #tOperTIO car au 2013-08-14 ça plante à cause d'un renversement de TIO dans U-20090615002
						2015-02-02	Donald Huppé	glpi 13409 : ajouter INM avec ITR
                        2017-02-27  Maxime Martel   TI-7031 : ajouter la cohorte dans le rapport
						2018-10-09	Donald Huppé	Retirer l'enregistrement de trace dans Un_Trace. Car la ps plante quand c'est une bd Read-Only (snapshot)

exec RP_UN_DailyOperTIO 1, '2016-01-01', '2016-12-31',  'ALL', 1

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperTIO] (
	@ConnectID	INTEGER,		--	ID de connexion
	@StartDate	DATETIME,		--	Date de début du rapport
	@EndDate	DATETIME,		--	Date de fin du rapport
	@ConventionStateID	VARCHAR(4), --	Filtre du rapport ('ALL' = tous, 'REEE' = en RÉÉÉ, 'TRA' = transitoire)
	@bGroupByUser BIT)			--  Est-ce que l'on groupe les données par usager ou non (1 = Groupées, 0 = Non)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	--	Création de la table temporaire #Convention contenant la date effective et la date d'entrée en vigueur par convention
	SELECT 
		C.ConventionID,
		EffectDate = 	CASE 
							WHEN C.dtRegStartDate IS NULL THEN @EndDate + 1
							ELSE C.dtRegStartDate
						END
	INTO #Convention	
	FROM dbo.Un_Convention C WITH(NOLOCK) 

	CREATE TABLE #tOperTable(
		OperID INT,-- PRIMARY KEY,
		iTioId integer
		)

	-- Seulement les opération relisé à UN_TIO, car c'est un rapport sur les TIO
	INSERT INTO #tOperTable
		SELECT 
			o.OperID,
			TioTIN.iTioId

		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioTIN on TioTIN.iTINOperID = o.operid
		WHERE OperDate BETWEEN @StartDate AND @EndDate

		UNION

		SELECT 
			o.OperID,
			TioOUT.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioOUT on TioOUT.iOUTOperID = o.operid
		WHERE OperDate BETWEEN @StartDate AND @EndDate

	IF @ConventionStateID = 'ALL'

		SELECT   
			GroupeTous = 1, -- Groupe bidon pour switcher avec UserName dans un groupe selon la demande faite via @bGroupByUser
			V.iTioId, -- Ce champ permet de regrouper ensemble les OUT et TIN d'un TIO
			V.OperDate,
			V.UserID,
			V.UserName,
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

			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
			
			INCAmount = SUM(V.INCAmount),
			ITRAmount = SUM(V.ITRAmount),	
			ISTAmount = SUM(V.ISTAmount),

			INSAmount = SUM(V.INSAmount),
			IBCAmount = SUM(V.IBCAmount),
			ISPAmount = SUM(V.ISPAmount),
			
			CBQAmount = SUM(V.CBQAmount),
			MMQAmount = SUM(V.MMQAmount),
			ICQAmount = SUM(V.ICQAmount),
			IMQAmount = SUM(V.IMQAmount),
								
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),

			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),

			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) +
				SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.ICQAmount) + SUM(V.IMQAmount) +
				SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount),
			Cohorte = C.YearQualif
		FROM ( 
				SELECT
					ot.iTioId,

					U.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,
					
					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_Cotisation CO WITH(NOLOCK) 
				JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID  
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				 
				---------
	      		UNION ALL
	  			---------
		
				SELECT

					ot.iTioId,

					CO.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
					Cotisation = 0,
					Fee = 0,

					fCESG = 0, 
					fACESG = 0,
					fCLB = 0 ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID in ('ITR','INM') THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,

					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,

					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,
										
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,

					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END
				FROM Un_ConventionOper CO WITH(NOLOCK) 
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST', 'INS', 'IBC', 'IS+'  , 'CBQ', 'IQI', 'MIM', 'ICQ', 'III', 'IMQ', 'MMQ' ,'IIQ','INM'))
				  AND (CO.ConventionOperAmount <> 0)				 
				
				---------
	      		UNION ALL
	  			---------
		
				SELECT

					ot.iTioId,

					G.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,
					
					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_CESP G WITH(NOLOCK) 
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
			) V
		JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID	
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
		GROUP BY 

			v.iTioId,

			V.OperDate, 
			V.UserID,
			V.UserName,	
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
            C.YearQualif
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
			OR SUM(V.ISTAmount) <> 0 
			OR SUM(V.INSAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0

			OR SUM(V.CBQAmount) <> 0
			OR SUM(V.MMQAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IMQAmount) <> 0
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0

		ORDER BY 

			V.OperDate, 
			V.iTioId,
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	ELSE IF @ConventionStateID = 'REEE'

		SELECT     
			GroupeTous = 1,
			V.iTioId, 
			V.OperDate,
			V.UserID,
			V.UserName,
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

			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
			
			INCAmount = SUM(V.INCAmount),
			ITRAmount = SUM(V.ITRAmount),	
			ISTAmount = SUM(V.ISTAmount),

			INSAmount = SUM(V.INSAmount),
			IBCAmount = SUM(V.IBCAmount),
			ISPAmount = SUM(V.ISPAmount),
	
			CBQAmount = SUM(V.CBQAmount),
			MMQAmount = SUM(V.MMQAmount),
			ICQAmount = SUM(V.ICQAmount),
			IMQAmount = SUM(V.IMQAmount),
								
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),

			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),

			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) +
				SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.ICQAmount) + SUM(V.IMQAmount) +
				SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount),
            Cohorte = C.YearQualif

		FROM ( 
				SELECT

					ot.iTioId, 

					U.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,
					
					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_Cotisation CO WITH(NOLOCK) 
				JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
					
	  			---------
	      		UNION ALL
	  			---------
		
				SELECT

					ot.iTioId, 

					CO.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
					Cotisation = 0,
					Fee = 0,

					fCESG = 0, 
					fACESG = 0,
					fCLB = 0 ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID in ('ITR','INM') THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,

					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,

					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,
										
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,

					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END

				FROM Un_ConventionOper CO WITH(NOLOCK) 
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST', 'INS', 'IBC', 'IS+' , 'CBQ', 'IQI', 'MIM', 'ICQ', 'III', 'IMQ', 'MMQ','IIQ','INM'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
	 
   				---------
	      		UNION ALL
	  			---------
		
				SELECT

					ot.iTioId, 

					G.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
											
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,

					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_CESP G WITH(NOLOCK) 
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
				WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
					
			) V
		JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
		GROUP BY 

			V.iTioId, 

			V.OperDate, 
			V.UserID,
			V.UserName,
			V.OperTypeID, 
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
            C.YearQualif
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
			OR SUM(V.ISTAmount) <> 0
			OR SUM(V.INSAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
			OR SUM(V.CBQAmount) <> 0
			OR SUM(V.MMQAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IMQAmount) <> 0
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0
			
		ORDER BY 
			V.OperDate, 
			V.iTioId, 
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo
	ELSE

		SELECT     
			GroupeTous = 1,
			V.iTioId, 
			V.OperDate,
			V.UserID,
			V.UserName,
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

			BenefInsur = SUM(V.BenefInsur),
			SubscInsur = SUM(V.SubscInsur),
			TaxOnInsur = SUM(V.TaxOnInsur),

			fCESG 	= SUM(V.fCESG),
			fACESG = SUM(V.fACESG),
			fCLB = SUM(V.fCLB),
			
			INCAmount = SUM(V.INCAmount),
			ITRAmount = SUM(V.ITRAmount),	
			ISTAmount = SUM(V.ISTAmount),

			INSAmount = SUM(V.INSAmount),
			IBCAmount = SUM(V.IBCAmount),
			ISPAmount = SUM(V.ISPAmount),
	
			CBQAmount = SUM(V.CBQAmount),
			MMQAmount = SUM(V.MMQAmount),
			ICQAmount = SUM(V.ICQAmount),
			IMQAmount = SUM(V.IMQAmount),
								
			IQIAmount = SUM(V.IQIAmount),
			MIMAmount = SUM(V.MIMAmount),

			IIQAmount = SUM(V.IIQAmount),
			IIIAmount = SUM(V.IIIAmount),

			Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
				SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
				SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
				SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
				SUM(V.INSAmount) + SUM(V.IBCAmount) + SUM(V.ISPAmount) +
				SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.ICQAmount) + SUM(V.IMQAmount) +
				SUM(V.IQIAmount) + SUM(V.MIMAmount) + SUM(V.IIQAmount) + SUM(V.IIIAmount),
			Cohorte = C.YearQualif
		FROM ( 
				SELECT

					ot.iTioId, 

					U.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,

					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_Cotisation CO WITH(NOLOCK) 
				JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
	
	  			---------
	      		UNION ALL
	  			---------
		
				SELECT
	
					ot.iTioId, 

					CO.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
					Cotisation = 0,
					Fee = 0,

					fCESG = 0, 
					fACESG = 0,
					fCLB = 0 ,
	
					BenefInsur = 0,
					SubscInsur = 0,
					TaxOnInsur = 0,
	
					INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
					ITRAmount = CASE WHEN CO.ConventionOperTypeID in ('ITR','INM') THEN CO.ConventionOperAmount ELSE 0 END,
					ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,

					INSAmount = CASE WHEN CO.ConventionOperTypeID = 'INS' THEN CO.ConventionOperAmount ELSE 0 END,
					IBCAmount = CASE WHEN CO.ConventionOperTypeID = 'IBC' THEN CO.ConventionOperAmount ELSE 0 END,
					ISPAmount = CASE WHEN CO.ConventionOperTypeID = 'IS+' THEN CO.ConventionOperAmount ELSE 0 END,

					CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
					MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
					ICQAmount = CASE WHEN CO.ConventionOperTypeID = 'ICQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IMQAmount = CASE WHEN CO.ConventionOperTypeID = 'IMQ' THEN CO.ConventionOperAmount ELSE 0 END,
										
					IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END,
					MIMAmount = CASE WHEN CO.ConventionOperTypeID = 'MIM' THEN CO.ConventionOperAmount ELSE 0 END,

					IIQAmount = CASE WHEN CO.ConventionOperTypeID = 'IIQ' THEN CO.ConventionOperAmount ELSE 0 END,
					IIIAmount = CASE WHEN CO.ConventionOperTypeID = 'III' THEN CO.ConventionOperAmount ELSE 0 END

				FROM Un_ConventionOper CO WITH(NOLOCK) 
				JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID	
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST', 'INS', 'IBC', 'IS+' , 'CBQ', 'IQI', 'MIM', 'ICQ', 'III', 'IMQ', 'MMQ','IIQ','INM'))
				  AND (CO.ConventionOperAmount <> 0)
				  AND (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
	 
   				---------
	      		UNION ALL
	  			---------
		
				SELECT

					ot.iTioId, 

					G.ConventionID,
					O.OperDate,
					O.OperTypeID,
					
					US.UserID,
					UserName = RTRIM(HU.LastName) + ', ' + RTRIM(HU.FirstName),
					
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
					ISTAmount = 0,

					INSAmount = 0,
					IBCAmount = 0,
					ISPAmount = 0,

					CBQAmount = 0,
					MMQAmount = 0,
					ICQAmount = 0,
					IMQAmount = 0,
										
					IQIAmount = 0,
					MIMAmount = 0,

					IIQAmount = 0,
					IIIAmount = 0

				FROM Un_CESP G WITH(NOLOCK) 
				JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
				JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
				JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
				JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
				JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
				LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
				WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
			) V
		JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
		JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
		JOIN UN_PLAN P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
		GROUP BY 
			V.OperDate, 

			V.iTioId, 

			V.OperTypeID, 
			V.UserID,
			V.UserName,
			OT.OperTypeDesc, 
			V.ConventionID, 
			C.ConventionNo, 
			H.LastName, 
			H.FirstName,
			H.IsCompany,
			P.PlanDesc,
			RR.vcDescription,
			OrderOfPlanInReport,
            C.YearQualif
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
			OR SUM(V.ISTAmount) <> 0 
			OR SUM(V.INSAmount) <> 0
			OR SUM(V.IBCAmount) <> 0
			OR SUM(V.ISPAmount) <> 0
			OR SUM(V.CBQAmount) <> 0
			OR SUM(V.MMQAmount) <> 0
			OR SUM(V.ICQAmount) <> 0
			OR SUM(V.IMQAmount) <> 0
			OR SUM(V.IQIAmount) <> 0
			OR SUM(V.MIMAmount) <> 0
			OR SUM(V.IIQAmount) <> 0
			OR SUM(V.IIIAmount) <> 0
			
		ORDER BY 
			V.OperDate, 
			V.iTioId, 

			--V.UserName,						
			V.OperTypeID, 
			H.LastName, 
			H.FirstName,
			C.ConventionNo

	DROP TABLE #Convention	
	DROP TABLE #tOperTable
/*
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
				'Rapport journalier des opérations TIO  '/*+CAST(@OperTypeID AS VARCHAR)*/ + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperTIO',
				'EXECUTE RP_UN_DailyOperTIO @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
*/
END


