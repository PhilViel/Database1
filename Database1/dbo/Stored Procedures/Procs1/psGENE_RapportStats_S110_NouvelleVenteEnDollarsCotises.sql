/********************************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc.

Code du service		: psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises
Nom du service		: Nouvelles ventes en dollars cotisés
But 				: JIRA PROD-9566 : Obtenir les Nouvelles ventes en dollars cotisés 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						

Exemple d’appel		:	EXECUTE psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises '2018-01-01', '2018-01-31', 0, 436381
						EXECUTE psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises '2018-01-01', '2018-01-31', 149573, 0
						EXECUTE psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises '2018-01-01', '2018-01-31', 0, 0, 'V'
						EXECUTE psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises '2018-01-01', '2018-01-31', 0, 0, 'S'


							149593,--	5852--Martin Mercier
							149489,--	6070-- Clément Blais
							149521,--	6262--Michel Maheu
							436381	--	7036--Sophie Babeux
					

Historique des modifications:
		Date			Programmeur			Description									Référence
		------------	------------------- -----------------------------------------	------------
		2018-05-23		Donald Huppé		Création du service				
		2018-08-13		Donald Huppé		Correction de l'entête de la sp
		2018-09-07		Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
		2018-12-21		Donald Huppé		jira prod-13114 : ajout du paramètre @TypeREP
*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStats_S110_NouvelleVenteEnDollarsCotises]
    (
		@dtStartDate datetime
		,@dtEndDate datetime
		,@RepID INT	= 0
		,@BossID INT = 0
		,@TypeREP VARCHAR(30) = V -- V Rep de la vente), S (Rep du souscripteur)
    )
AS 
BEGIN

 	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	INTO #BossRepActuel
	FROM Un_RepBossHist RB
	JOIN (
		SELECT
			RepID,
			RepBossPct = MAX(RepBossPct)
		FROM Un_RepBossHist RB
		WHERE RepRoleID = 'DIR'
			AND StartDate IS NOT NULL
			AND (StartDate <= @dtEndDate)
			AND (EndDate IS NULL OR EndDate >= @dtEndDate)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @dtEndDate)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @dtEndDate)
	GROUP BY
		RB.RepID	


	SELECT UnitID,	RepID,	BossID,	dtFirstDeposit 
	INTO #Unit_T
	FROM fntREPR_ObtenirUniteConvT (1)


	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		WHERE OperDate BETWEEN @dtStartDate AND @dtEndDate
				AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI TIN NSF COU', 1) > 0

	select 

		V.RepID
		,r.RepCode
		,Representant = hr.FirstName + ' ' + hr.LastName
		,BR.BossID
		,Directeur = isnull(HB.FirstName + ' ' + HB.LastName ,'ND')
		,CotisationNouvelleVente  = SUM(CotisationNouvelleVente)
		,CotisationAncienneVente  = SUM(CotisationAncienneVente)
		--,Regime
		--,ConventionNo
		--,UnitID

	from (

		select 
			RepID = CASE WHEN @TypeREP = 'V' THEN  u.RepID ELSE s.RepID END --u.RepID
			,CotisationNouvelleVente  = SUM(CASE WHEN u.dtFirstDeposit BETWEEN	@dtStartDate AND @dtEndDate OR c.PlanID = 4		THEN ct.Cotisation + ct.Fee ELSE 0 END)
			,CotisationAncienneVente  = SUM(CASE WHEN u.dtFirstDeposit <		@dtStartDate			   AND c.PlanID != 4	THEN ct.Cotisation + ct.Fee ELSE 0 END)
			,Regime = rr.vcDescription
			,c.ConventionNo
			,u.UnitID


		from 
			un_cotisation ct
			join un_oper o on ct.OperID = o.OperID
			join #tOperTable ot on ot.OperID = o.OperID
			join Un_Unit u on u.UnitID = ct.UnitID
			join Un_Convention c on c.ConventionID = u.ConventionID
			join Un_Subscriber s on s.SubscriberID = c.SubscriberID
			join Un_Plan P on p.PlanID = c.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			left join #Unit_T t on t.unitid = u.UnitID
		where 1=1
			and t.unitid is null
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			rr.vcDescription
			,c.ConventionNo
			,u.UnitID
			,CASE WHEN @TypeREP = 'V' THEN  u.RepID ELSE s.RepID END
			--,u.RepID



		UNION ALL

		-- contrat T et I BEC

		select 
			RepID = CASE WHEN @TypeREP = 'V' THEN  t.RepID ELSE s.RepID END
			,CotisationNouvelleVente = SUM(ct.Cotisation + ct.Fee)
			,CotisationAncienneVente = 0
			,Regime = rr.vcDescription
			,c.ConventionNo
			,u.UnitID

		from 
			un_cotisation ct --on ct.UnitID = u.UnitID
			join un_oper o on ct.OperID = o.OperID
			join #tOperTable ot on ot.OperID = o.OperID
			join Un_Unit u on u.UnitID = ct.UnitID
			join #Unit_T t on t.unitid = u.UnitID
			join Un_Convention c on c.ConventionID = u.ConventionID
			join Un_Subscriber s on s.SubscriberID = c.SubscriberID
			join Un_Plan P on p.PlanID = c.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			left join (
				select u1.ConventionID, MinUnitID =  min(u1.UnitID), Date1erDepotConv = min(u1.dtFirstDeposit)
				from Un_Unit u1
				GROUP BY u1.ConventionID
				) mu on  mu.ConventionID = u.ConventionID --and mu.MinUnitID = u.UnitID
							
		where 1=1
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------

						

		group by 
			rr.vcDescription
			,c.ConventionNo
			,u.UnitID
			--,t.RepID
			,CASE WHEN @TypeREP = 'V' THEN  t.RepID ELSE s.RepID END


	) V
	JOIN Un_Rep r on r.RepID = V.RepID
	join Mo_Human hr on hr.HumanID = r.RepID

	LEFT JOIN #BossRepActuel BR ON BR.RepID = V.RepID
	LEFT JOIN Mo_Human HB ON HB.HumanID = BR.BossID
	
	WHERE
			( V.RepID =		@RepID	OR	@RepID = 0 )
		AND ( BR.BossID =	@BossID OR  @BossID = 0)	

	GROUP BY

		V.RepID
		,BR.BossID
		,hr.FirstName 
		,hr.LastName
		,r.RepCode
		,HB.FirstName
		,HB.LastName 

		--,Regime
		--,ConventionNo
		--,UnitID
	


	

END