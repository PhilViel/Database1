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
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Stats_Coupon 
Description         :	SSRS - Rapport Statistique de vente de Coupon "UNI-CAU-Coupon d'ajout d'unités"
Valeurs de retours  :	Dataset 
Note                :	2009-08-19	Donald Huppé			Création
						2010-01-19	Donald Huppé			Modification pour prendre la qté d'unité originale (avant résilisation) 
																		dans le calcul du PRD (Mensuel, annuel, Uniqu)
						2010-02-16	Donald Huppé			Regrouper NbUnite et NbCoupon par régime 		
						2013-07-08	Maxime Martel		    Ajout du nombre de souscripteurs			
                        2018-10-29  Pierre-Luc Simard       N'est plus utilisé

exec GU_RP_Stats_Coupon '2009-01-01', '2010-02-28'  

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_Stats_Coupon] (
	@StartDate DATETIME,
	@EndDate DATETIME)
AS
BEGIN

SELECT 1/0
/*
select
	Agence,
	DATEADD(MONTH,DATEDIFF(MONTH,0,dtFirstDeposit),0) as "dtFirstDeposit",
	Regime,
	NbUniteUniv = case when planid = 8 then sum(unitQty) else 0 end,
	NbUniteRflex = case when planid = 10 then sum(unitQty) else 0 end,
	NbUniteRflex10 = case when planid = 12 then sum(unitQty) else 0 end,
	NbUnite = sum(unitQty),

	NbCouponUniv = case when planid = 8 then count(distinct UnitID) else 0 end,
	NbCouponRflex = case when planid = 10 then count(distinct UnitID) else 0 end,
	NbCouponRflex10 = case when planid = 12 then count(distinct UnitID) else 0 end,
	NbCoupon = count(distinct UnitID),
	Mensuel = isnull(sum(Mensuel),0),
	Annuel = isnull(sum(Annuel),0),
	Uniqu = isnull(sum(Uniqu),0),

	Mensuel_univ = isnull(sum(Mensuel_univ),0),
	Annuel_univ = isnull(sum(Annuel_univ),0),
	Uniqu_univ = isnull(sum(Uniqu_univ),0),
	
	Mensuel_Rflex = isnull(sum(Mensuel_Rflex),0),
	Annuel_Rflex = isnull(sum(Annuel_Rflex),0),
	Uniqu_Rflex = isnull(sum(Uniqu_Rflex),0),

	Mensuel_Rflex2010 = isnull(sum(Mensuel_Rflex2010),0),
	Annuel_Rflex2010 = isnull(sum(Annuel_Rflex2010),0),
	Uniqu_Rflex2010 = isnull(sum(Uniqu_Rflex2010),0),
	
	--NbSouscUniv = case when planid = 8 then count(distinct SubscriberID) else 0 end,
	--NbSouscRflex = case when planid = 10 then count(distinct SubscriberID) else 0 end,
	--NbSouscRflex10 = case when planid = 12 then count(distinct SubscriberID) else 0 end,
	NbSousc = (select count(distinct SubscriberID)
				from 
					un_unit u
					JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
				where
					u.dtFirstDeposit between @StartDate and @EndDate
					and u.salesourceid = 48 and c.PlanID = 8),

	NbSouscReeeflex = (select count(distinct SubscriberID)
				from 
					un_unit u
					JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
				where
					u.dtFirstDeposit between @StartDate and @EndDate
					and u.salesourceid = 48 and c.PlanID = 10),

	NbSouscReeeflex10 = (select count(distinct SubscriberID)
				from 
					un_unit u
					JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
				where
					u.dtFirstDeposit between @StartDate and @EndDate
					and u.salesourceid = 48 and c.PlanID = 12)
from
	(
	select 
		c.planid,
		Regime = case when c.planid = 12 then 'Reeeflex 2010' else p.plandesc end,
		C.conventionno,
		C.SubscriberID,
		u.dtFirstDeposit,
		u.UnitID,
		unitQty = (u.unitQty + isnull(UR.UnitQty,0)),

		-- On met un espace devant le nom de l'agence pour que "Autres" arrive à la fin quand on met en ordre alphabétique
		Agence = case when RB.BossID in (436381,149489,440176,415878,298925,149521,149593,149469,149602) then ' ' + BH.lastname  else 'Autres'  end,
		
		Mensuel = case when m.PmtByYearID = 12 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Annuel = case when m.PmtByYearID = 1 and m.pmtqty > 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Uniqu = case when m.PmtByYearID = 1 and m.pmtqty = 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		
		Mensuel_univ = case when rr.iID_Regroupement_Regime = 1 and m.PmtByYearID = 12 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Annuel_univ = case when rr.iID_Regroupement_Regime = 1 and m.PmtByYearID = 1 and m.pmtqty > 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Uniqu_univ = case when rr.iID_Regroupement_Regime = 1 and m.PmtByYearID = 1 and m.pmtqty = 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,

		--Mensuel_Rflex = case when rr.iID_Regroupement_Regime = 2 and m.PmtByYearID = 12 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		--Annuel_Rflex = case when rr.iID_Regroupement_Regime = 2 and m.PmtByYearID = 1 and m.pmtqty > 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		--Uniqu_Rflex = case when rr.iID_Regroupement_Regime = 2 and m.PmtByYearID = 1 and m.pmtqty = 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,

		Mensuel_Rflex = case when c.PlanID = 10 and m.PmtByYearID = 12 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Annuel_Rflex = case when c.PlanID = 10 and m.PmtByYearID = 1 and m.pmtqty > 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Uniqu_Rflex = case when c.PlanID = 10 and m.PmtByYearID = 1 and m.pmtqty = 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,

		Mensuel_Rflex2010 = case when c.PlanID = 12 and m.PmtByYearID = 12 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Annuel_Rflex2010 = case when c.PlanID = 12 and m.PmtByYearID = 1 and m.pmtqty > 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,
		Uniqu_Rflex2010 = case when c.PlanID = 12 and m.PmtByYearID = 1 and m.pmtqty = 1 then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end,

		Autre = case when m.PmtByYearID not in (1,12) then m.PmtRate * (u.unitQty + isnull(UR.UnitQty,0)) else 0 end
	from 
		un_unit u
		JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
		join un_plan p on c.planid = p.planid
		join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime -- select * from tblCONV_RegroupementsRegimes
		join un_modal m on u.modalid = m.modalid
		LEFT JOIN (
			SELECT
				RB.RepID,
				BossID = MAX(BossID)
			FROM Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM Un_RepBossHist RB
				WHERE RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND StartDate < = @EndDate
					AND ISNULL(EndDate, @EndDate) >= @EndDate
				GROUP BY RepID
			   ) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
			  AND RB.StartDate IS NOT NULL
			  AND RB.StartDate < = @EndDate
			  AND ISNULL(RB.EndDate, @EndDate) > = @EndDate
			GROUP BY RB.RepID
			) RB ON RB.RepID = U.RepID
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			GROUP BY UR.UnitID
			) UR ON UR.UnitID = U.UnitID
		left JOIN dbo.mo_human BH on BH.HumanID = RB.BossID
		left JOIN dbo.mo_human RH on RH.HumanID = U.RepID
	where
		u.dtFirstDeposit between @StartDate and @EndDate
		and u.salesourceid = 48
	) V
group by
	Agence,
	planid,
	Regime,
	DATEADD(MONTH,DATEDIFF(MONTH,0,dtFirstDeposit),0)
*/
End