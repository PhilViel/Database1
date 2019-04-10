/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas Inc.
Nom                 :	RP_UN_DailyOperCashing_Coupon
Description         :	Rapport des opérations journalières (Encaissement) pour l'opération Coupon
Valeurs de retours  :	Dataset de données
Note                :	2018-09-21	Maxime Martel		Création à partir de RP_UN_DailyOperCashing	
						2018-12-19	Donald Huppé		JIRA PROD-13379 : Ajout de SignatureDate, UnitID, enlever section INC non relié à operid (pas utile) et empêche d'avoir le UnitID

exec RP_UN_DailyOperCashing_Coupon 1, '2018-01-04', '2018-12-18', 'ALL', 1
exec RP_UN_DailyOperCashing_Coupon 1, '2017-11-01', '2017-11-01', 'REEE', 1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_DailyOperCashing_Coupon] (
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
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		left join Un_Tio TIO on TIO.iTINOperID = o.operid
		WHERE OperDate BETWEEN @StartDate AND @EndDate
				AND OperTypeID = 'COU'	
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
				MontantInteret = SUM(V.MontantInteret),
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),  
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						Co.Cotisation,
						Co.Fee,
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,	
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID  
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 

					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	UserID = 0,
					--	UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					--LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0 		
				OR SUM(V.MontantInteret) <> 0	
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
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),
				MontantInteret = SUM(V.MontantInteret),
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),  
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,						
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						Co.Cotisation,
						Co.Fee,
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID	
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))

					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	UserID = 0,
					--	UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					--LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
					--  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0	
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0 
				OR SUM(V.MontantInteret) <> 0			
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
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),	
				MontantInteret = SUM(V.MontantInteret),		
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),  
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,
						UserID = 0,
						UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), ISNULL(US.LoginNameID,'Non déterminé')),--jira SR-2674
						Co.Cotisation,
						Co.Fee,
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID	
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID
					LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
					
					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	UserID = 0,
					--	UserName = COALESCE(SUBSTRING(O.LoginName, CHARINDEX('\', O.LoginName) + 1, LEN(O.LoginName)), US.LoginNameID),
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Mo_Connect CT WITH(NOLOCK) ON CT.ConnectID = O.ConnectID
					--LEFT JOIN Mo_User US WITH(NOLOCK) ON US.UserID = CT.UserID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
					--  AND (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0 	
				OR SUM(V.MontantInteret) <> 0		
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
				MontantInteret = SUM(V.MontantInteret),	
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),  
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,
						Co.Cotisation,
						Co.Fee,
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,	
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 
					
					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0 
				OR SUM(V.MontantInteret) <> 0			
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
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),
				MontantInteret = SUM(V.MontantInteret),	
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),  
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,
						Co.Cotisation,
						Co.Fee,	
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID		
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID	
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 
					WHERE ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))

					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
					--  AND ((O.OperDate >= dbo.fn_Mo_DateNoTime(F.EffectDate)) OR (F.EffectDate < '2003-01-01'))
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0	
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0
				OR SUM(V.MontantInteret) <> 0 			
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
				BenefInsur = SUM(V.BenefInsur),
				SubscInsur = SUM(V.SubscInsur),
				TaxOnInsur = SUM(V.TaxOnInsur),	
				MontantInteret = SUM(V.MontantInteret),					
				Total = SUM(V.Cotisation) + SUM(V.Fee) + SUM(V.BenefInsur) + SUM(V.SubscInsur) + SUM(V.TaxOnInsur) + SUM(V.MontantInteret),
				RepCodeRepresentant = V.RepCodeRepresentant,
				RepCodeDirecteur = V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			FROM ( 
					SELECT
						U.ConventionID,
						U.UnitID,
						U.SignatureDate,
						O.OperDate,
						O.OperTypeID,
						Co.Cotisation,
						Co.Fee,
						Co.BenefInsur,
						Co.SubscInsur,
						Co.TaxOnInsur,
						RepCodeRepresentant = R.RepCode,
						RepCodeDirecteur = DIR.RepCode,
						MontantInteret = ISNULL(interet.MontantInteret,0)
					FROM Un_Cotisation CO WITH(NOLOCK) 
					JOIN dbo.Un_Unit U WITH(NOLOCK) ON U.UnitID = CO.UnitID
					JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = U.ConventionID
					JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID	
					JOIN Un_Rep R WITH(NOLOCK) ON R.RepID = U.RepID	
					LEFT JOIN (
						SELECT
							M.UnitID,
							BossID = MAX(RBH.BossID)
						FROM (
							SELECT
								U.UnitID,
								U.RepID,
								RepBossPct = MAX(RBH.RepBossPct)
							FROM dbo.Un_Unit U
							JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
							JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
							JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
							GROUP BY 
								U.UnitID, 
								U.RepID
							) M
						JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
						JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
						GROUP BY M.UnitID
					) UDIR ON UDIR.UnitID = U.UnitID
					LEFT JOIN Un_Rep DIR on DIR.RepID = UDIR.BossID
					LEFT JOIN (
						SELECT MontantInteret = SUM(conventionOperAmount), CO.OperID
						FROM Un_ConventionOper CO 
						WHERE ConventionOperTypeID = 'INC' 
						GROUP BY co.OperID
					) interet on interet.OperID = o.OperID 
					WHERE (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
					
					------------
					--UNION ALL
					------------

					--SELECT
					--	CO.ConventionID,
					--	SignatureDate = NULL,
					--	O.OperDate,
					--	O.OperTypeID,
					--	Cotisation = 0,
					--	Fee = 0,
					--	BenefInsur = 0,
					--	SubscInsur = 0,
					--	TaxOnInsur = 0,
					--	RepCodeRepresentant = '',
					--	RepCodeDirecteur = '',
					--	MontantInteret = CO.ConventionOperAmount
					--FROM Un_ConventionOper CO WITH(NOLOCK) 
					--JOIN #Convention F WITH(NOLOCK) ON F.ConventionID = CO.ConventionID
					--JOIN #tOperTable OT WITH(NOLOCK) ON OT.OperID = CO.OperID
					--JOIN Un_Oper O WITH(NOLOCK) ON O.OperID = OT.OperID
					--LEFT JOIN Un_Cotisation coti ON coti.OperID = O.OperID 
					--WHERE CO.ConventionOperTypeID = 'INC'
					--  AND CO.ConventionOperAmount <> 0
					--  AND coti.OperID IS NULL
					--  AND (O.OperDate < dbo.fn_Mo_DateNoTime(F.EffectDate) AND F.EffectDate >= '2003-01-01')
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
				OrderOfPlanInReport,
				V.RepCodeRepresentant,
				V.RepCodeDirecteur,
				V.UnitID,
				V.SignatureDate
			HAVING SUM(V.Cotisation) <> 0
				OR SUM(V.Fee) <> 0
				OR SUM(V.BenefInsur) <> 0
				OR SUM(V.SubscInsur) <> 0 
				OR SUM(V.TaxOnInsur) <> 0 	
				OR SUM(V.MontantInteret) <> 0		
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
				'Rapport journalier des opérations (Encaissement) pour le type d''opération COU entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_DailyOperCashing_Coupon',
				'EXECUTE RP_UN_DailyOperCashing_Coupon @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @ConventionStateID ='+@ConventionStateID+
				', @bGroupByUser = '+CAST(@bGroupByUser	AS VARCHAR)	
	END	
END