/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOperCashing
Description         :	Rapport des opérations journalières (Encaissement)
Valeurs de retours  :	Dataset de données
				Dataset :
					ConventionNo	VARCHR(20)	Numéro de la convention
					SubscriberName	VARCHAR(75)	Nom et prénom du souscripteur (Ex Caron, Dany)
					Cotisation		MONEY		Montant d’épargne de l’opération
					Fee				MONEY		Montant de frais de l’opération
					BenefInsur		MONEY		Montant d’assurance bénéficiaire de l’opération
					SubsInsur		MONEY		Montant d’assurance souscripteur de l’opération
					TaxOnInsur		MONEY		Montant des taxes sur l’opération
					INCAmount		MONEY		Montant des intérêts chargés au souscripteur
					ITRAmount		MONEY		Montant des intérêts reçus du promoteur
					fCESG			MONEY		Montant de SCEE sur l’opération (TIN).
					fACESG			MONEY		Montant de SCEE+ sur l’opération (TIN).
					fCLB			MONEY		Montant de BEC sur l’opération (TIN).
					fPCEETINAmount	MONEY		Montant des intérêts PCEE TIN reçus pour l’opération (TIN).
					fTotal			MONEY		Montant total. Somme de toutes les colonnes. 

Note                :	ADX0001326	IA	2007-04-30	Alain Quirion		Création
										2009-04-09	Pierre-Luc Simard	Paramètre pour regrouper par agente
										2009-09-10	Donald Huppé		(mis en prod le 22-09-2009)	(GLPI 1948) Exclure Les TIO, ils seront dans un nouveau rapport de TIO - mis en prod le 22-09-2009
										2009-12-22	Donald Huppé		Inclure l'IQEE
										2010-06-10	Donald Huppé		Ajout des régime et groupe de régime
										2017-11-02	Donald Huppé		jira SR-2674 (projet pret REEE) : inscrire UserName = Non déterminé quand connectID = 0 
										2018-08-30	Maxime Martel		JIRA MP-1142 obtenir le nom selon l'utiliateur de l'operation 
                                        2018-09-06  Pierre-Luc Simard   Il manquait les champs de l'IQEE dans un des UNION

exec RP_UN_DailyOperCashing 1, '2018-09-10', '2018-09-23', 'ALL', 'ALL', 1
exec RP_UN_DailyOperCashing 1, '2017-11-01', '2017-11-01', 'CHQ', 'ALL', 1
exec RP_UN_DailyOperCashing 1, '2017-11-01', '2017-11-01', 'CHQ', 'REEE', 1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperCashing] (
	@ConnectID	INTEGER,		--	ID de connexion
	@StartDate	DATETIME,		--	Date de début du rapport
	@EndDate	DATETIME,		--	Date de fin du rapport
	@OperTypeID	CHAR(3),		--	Type d’opéartion ('ALL' = tous, 'CHQ'=chèque, 'NSF'= effet retourné, 'PRD' = Premier dépôt, 'CPA' = paiement préautorisé, 'TIN' = transfert In)
	@ConventionStateID	VARCHAR(4), --	Filtre du rapport ('ALL' = tous, 'REEE' = en RÉÉÉ, 'TRA' = transitoire)
	@bGroupByUser BIT)			--  Est-ce que l'on groupe les données par usager ou non (1 = Groupées, 0 = Non)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@GlobalOperTypeID VARCHAR(MAX)

	SET @dtBegin = GETDATE()

	IF @OperTypeID = 'ALL'
		SET @GlobalOperTypeID = 'CHQ,PRD,NSF,CPA,TIN'
	ELSE 
		SET @GlobalOperTypeID = @OperTypeID

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
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		left join Un_Tio TIO on TIO.iTINOperID = o.operid
		WHERE OperDate BETWEEN @StartDate AND @EndDate
				AND CHARINDEX(OperTypeID, @GlobalOperTypeID) > 0		
				AND TIO.iTINOperID is null -- exclure les TIO

	IF @bGroupByUser = 1  -- Regroupement par agente
		IF @ConventionStateID = 'ALL'
		BEGIN
			SELECT     
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
				
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
			FROM ( 
					SELECT
						U.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,

						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						--UserName = US.LoginNameID,
						
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0

					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID  
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					
					---------
		      		UNION ALL
		  			---------
			
					SELECT
						CO.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
						
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
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END
					
					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)				 
					
					---------
		      		UNION ALL
		  			---------
			
					SELECT
						G.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
						
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0

					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID		
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
			GROUP BY 
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
				OrderOfPlanInReport
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
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0

			ORDER BY 
				V.OperDate, 
				V.UserName,						
				V.OperTypeID, 
				H.LastName, 
				H.FirstName,
				C.ConventionNo
		END
		ELSE IF @ConventionStateID = 'REEE'
			SELECT     
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
				Fee = SUM(V.Fee),

				fCESG 	= SUM(V.fCESG),
				fACESG = SUM(V.fACESG),
				fCLB = SUM(V.fCLB),
		
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),
				
				INCAmount = SUM(V.INCAmount),
				ITRAmount = SUM(V.ITRAmount),
				ISTAmount =  SUM(V.ISTAmount),
				
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
			FROM ( 
					SELECT
						U.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,

						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						--UserName = US.LoginNameID,
						
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
						
		  			---------
		      		UNION ALL
		  			---------
			
					SELECT
						CO.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
						
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
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END

					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)
					  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
		 
	   				---------
		      		UNION ALL
		  			---------
			
					SELECT
						G.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
												
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
						
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
			GROUP BY 
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
				OrderOfPlanInReport
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
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0

			ORDER BY 
				V.OperDate, 
				V.UserName,						
				V.OperTypeID, 
				H.LastName, 
				H.FirstName,
				C.ConventionNo
		ELSE
			SELECT     
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
				Fee = SUM(V.Fee),

				fCESG 	= SUM(V.fCESG),
				fACESG = SUM(V.fACESG),
				fCLB = SUM(V.fCLB),
		
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),			
				
				INCAmount = SUM(V.INCAmount),
				ITRAmount = SUM(V.ITRAmount),
				ISTAmount = SUM(V.ISTAmount),
		
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
			FROM ( 
					SELECT
						U.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,

						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						--UserName = US.LoginNameID,
						
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
		
		  			---------
		      		UNION ALL
		  			---------
			
					SELECT
						CO.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
						
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
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END

					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID	
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)
					  AND (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
		 
	   				---------
		      		UNION ALL
		  			---------
			
					SELECT
						G.ConventionID,
						O.OperDate,
						O.OperTypeID,
						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
						
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
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN dbo.Mo_Human HU WITH(NOLOCK) ON HU.HumanID = US.UserID
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
			GROUP BY 
				V.OperDate, 
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
				OrderOfPlanInReport
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
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0
			ORDER BY 
				V.OperDate, 
				V.UserName,						
				V.OperTypeID, 
				H.LastName, 
				H.FirstName,
				C.ConventionNo
	ELSE -- Sans regroupement par agente
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

				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),

				fCESG 	= SUM(V.fCESG),
				fACESG = SUM(V.fACESG),
				fCLB = SUM(V.fCLB),
				
				INCAmount = SUM(V.INCAmount),
				ITRAmount = SUM(V.ITRAmount),	
				ISTAmount = SUM(V.ISTAmount),
		
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
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
					
						INCAmount = 0,
						ITRAmount = 0,
						ISTAmount = 0,
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0	
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					 
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
		
						INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
						ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END

					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)				 
					
					---------
		      		UNION ALL
		  			---------
			
					SELECT
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
						ISTAmount = 0,
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0	
					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
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
				OR SUM(V.INCAmount) <> 0 
				OR SUM(V.ITRAmount) <> 0 
				OR SUM(V.ISTAmount) <> 0 
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0
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
				Fee = SUM(V.Fee),

				fCESG 	= SUM(V.fCESG),
				fACESG = SUM(V.fACESG),
				fCLB = SUM(V.fCLB),
		
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),
				
				INCAmount = SUM(V.INCAmount),
				ITRAmount = SUM(V.ITRAmount),
				ISTAmount =  SUM(V.ISTAmount),
				
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
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
						
						INCAmount = 0,
						ITRAmount = 0,
						ISTAmount = 0,
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID				
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
						
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
		
						INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
						ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END

					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)
					  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
		 
	   				---------
		      		UNION ALL
		  			---------
			
					SELECT
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
						ISTAmount = 0,
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0
					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
						
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
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
				OR SUM(V.INCAmount) <> 0 
				OR SUM(V.ITRAmount) <> 0
				OR SUM(V.ISTAmount) <> 0
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0
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
				Fee = SUM(V.Fee),

				fCESG 	= SUM(V.fCESG),
				fACESG = SUM(V.fACESG),
				fCLB = SUM(V.fCLB),
		
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),			
				
				INCAmount = SUM(V.INCAmount),
				ITRAmount = SUM(V.ITRAmount),
				ISTAmount = SUM(V.ISTAmount),
		
				CBQAmount = SUM(V.CBQAmount),
				MMQAmount = SUM(V.MMQAmount),
				IQIAmount = SUM(V.IQIAmount),
		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.fCESG) +
					SUM(V.fACESG) + SUM(V.fCLB) + SUM(V.BenefInsur) + 
					SUM(V.SubscInsur) + SUM(V.TaxOnInsur) +  
					SUM(V.INCAmount) + SUM(V.ITRAmount) + SUM(V.ISTAmount) +
					SUM(V.CBQAmount) + SUM(V.MMQAmount) + SUM(V.IQIAmount)
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
						
						INCAmount = 0,
						ITRAmount = 0,
						ISTAmount = 0,

                        CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0

					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
		
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
		
						INCAmount = CASE WHEN CO.ConventionOperTypeID = 'INC' THEN CO.ConventionOperAmount ELSE 0 END,
						ITRAmount = CASE WHEN CO.ConventionOperTypeID = 'ITR' THEN CO.ConventionOperAmount ELSE 0 END,
						ISTAmount = CASE WHEN CO.ConventionOperTypeID = 'IST' THEN CO.ConventionOperAmount ELSE 0 END,
						
						CBQAmount = CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END,
						MMQAmount = CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END,
						IQIAmount = CASE WHEN CO.ConventionOperTypeID = 'IQI' THEN CO.ConventionOperAmount ELSE 0 END

					FROM Un_ConventionOper CO WITH(NOLOCK) 
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					WHERE (CO.ConventionOperTypeID IN ('INC', 'ITR', 'IST','CBQ','MMQ','IQI'))
					  AND (CO.ConventionOperAmount <> 0)
					  AND (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
		 
	   				---------
		      		UNION ALL
		  			---------
			
					SELECT
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
						ISTAmount = 0,
						
						CBQAmount = 0,
						MMQAmount = 0,
						IQIAmount = 0

					FROM Un_CESP G WITH(NOLOCK) 
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = G.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					LEFT JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = G.ConventionID
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
				) V
			JOIN Un_OperType OT WITH(NOLOCK) ON OT.OperTypeID = V.OperTypeID
			JOIN dbo.Un_Convention C WITH(NOLOCK) ON C.ConventionID = V.ConventionID
			JOIN UN_PLAN P WITH(NOLOCK) ON P.PlanID = C.PlanID -- select * from UN_PLAN
			JOIN tblCONV_RegroupementsRegimes RR WITH(NOLOCK) ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime --select * from tblCONV_RegroupementsRegimes
			JOIN dbo.Mo_Human H WITH(NOLOCK) ON H.HumanID = C.SubscriberID		
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
				OR SUM(V.INCAmount) <> 0 
				OR SUM(V.ITRAmount) <> 0 
				OR SUM(V.ISTAmount) <> 0
				OR SUM(V.CBQAmount) <> 0
				OR SUM(V.MMQAmount) <> 0
				OR SUM(V.IQIAmount) <> 0
			ORDER BY 
				V.OperDate, 
				V.OperTypeID, 
				H.LastName, 
				H.FirstName,
				C.ConventionNo

	DROP TABLE #Convention	
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
				'Rapport journalier des opérations (Encaissement) selon le type d''opération '+CAST(@OperTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperCashing',
				'EXECUTE RP_UN_DailyOperCashing @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @OperTypeID ='+CAST(@OperTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID				
	END	
END

-- EXEC RP_UN_DailyOperCashing 1, '2009-04-08','2009-04-08', 'ALL', 'ALL', 1