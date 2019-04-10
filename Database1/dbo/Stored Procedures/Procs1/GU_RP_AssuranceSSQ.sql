/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc
Nom                 :	GU_RP_AssuranceSSQ 
Description         :	SSRS - Rapport de souscription d'assurance pour SSQ
Valeurs de retours  :	Dataset 
Note                :	2010-07-06	Donald Huppé	Création

exec GU_RP_AssuranceSSQ '2009-01-01', '2010-02-28'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_AssuranceSSQ] (
	@StartDate DATETIME,
	@EndDate DATETIME)
AS

BEGIN

--declare @StartDate datetime
--declare @EndDate datetime

--set @StartDate = '2010-06-01'
--set @EndDate = '2010-06-30'

	select 
		--c.conventionno,
		p.plandesc,
		c.yearqualif,
		--c.conventionno,
		UnitQtyNewModal = sum(case when CotNewModPositif = 1 then UnitQtyNewModal else 0 end),
		--UnitQtyNewModal = sum(UnitQtyNewModal),
		--UnitQtyOldModal = sum(case when CotOldModPositif = 1 then UnitQtyOldModal else 0 end),
		fSubscInsurOldModal = SUM(fSubscInsurOldModal),
		fBenefInsurOldModal = SUM(fBenefInsurOldModal),
		fTaxOnInsurOldModal = SUM(fTaxOnInsurOldModal), 

		fSubscInsurNewModal = SUM(fSubscInsurNewModal), 
		fBenefInsurNewModal = SUM(fBenefInsurNewModal),
		fTaxOnInsurNewModal = SUM(fTaxOnInsurNewModal)
	--into Tmp1New
	from (
		SELECT
			u.unitid,
			fSubscInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.SubscInsur else 0 end),
			fBenefInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.BenefInsur else 0 end),
			fTaxOnInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.TaxOnInsur else 0 end), 
			fSubscInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.SubscInsur else 0 end), 
			fBenefInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.BenefInsur else 0 end),
			fTaxOnInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.TaxOnInsur else 0 end),

			CotOldModPositif = case when 
							SUM(case when m.modaldate < '2009-12-08' then Ct.SubscInsur else 0 end) > 0
							OR SUM(case when m.modaldate < '2009-12-08' then Ct.BenefInsur else 0 end) > 0
							OR SUM(case when m.modaldate < '2009-12-08' then Ct.TaxOnInsur else 0 end) > 0 
							Then 1
						else 0
						end,
			CotNewModPositif = case when 
							SUM(case when m.modaldate >= '2009-12-08' then Ct.SubscInsur else 0 end) > 0
							OR SUM(case when m.modaldate >= '2009-12-08' then Ct.BenefInsur else 0 end) > 0
							OR SUM(case when m.modaldate >= '2009-12-08' then Ct.TaxOnInsur else 0 end) > 0 
							Then 1
						else 0
						end
						
		--into #tmpCot
		FROM dbo.Un_Unit U
		JOIN un_modal m on u.modalid = m.modalid
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		WHERE Ct.OperID IN (
			SELECT O.OperID
			FROM Un_Oper O
			JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
			WHERE O.OperDate BETWEEN @StartDate AND @EndDate -- Opération de la période sélectionnée.
				AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
					OR O.OperTypeID = 'TRA' -- Inclus les TRA
					)
			)
		group by u.unitid
		having
			SUM(case when m.modaldate < '2009-12-08' then Ct.SubscInsur else 0 end) <> 0
			OR SUM(case when m.modaldate < '2009-12-08' then Ct.BenefInsur else 0 end) <> 0
			OR SUM(case when m.modaldate < '2009-12-08' then Ct.TaxOnInsur else 0 end) <> 0 

			OR SUM(case when m.modaldate >= '2009-12-08' then Ct.SubscInsur else 0 end) <> 0
			OR SUM(case when m.modaldate >= '2009-12-08' then Ct.BenefInsur else 0 end) <> 0
			OR SUM(case when m.modaldate >= '2009-12-08' then Ct.TaxOnInsur else 0 end) <> 0
		) tc
	JOIN dbo.Un_Unit u on tc.unitid = u.unitid
	JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
	JOIN un_plan p on c.planid = p.planid
	JOIN (
		SELECT
			u2.unitid,
			UnitQtyNewModal = sum(case when m.modaldate >= '2009-12-08' then U2.UnitQty+ISNULL(UR.UnitQty, 0) else 0 end),
			UnitQtyOldModal = sum(case when m.modaldate < '2009-12-08' then U2.UnitQty+ISNULL(UR.UnitQty, 0) else 0 end) 
		FROM dbo.Un_Unit U2
		JOIN dbo.Un_Convention c on u2.conventionid = c.conventionid
		JOIN un_modal m on u2.modalid = m.modalid
		LEFT JOIN (
			SELECT
				UnitID,
				UnitQty = SUM(UnitQty)
			FROM Un_UnitReduction
			WHERE ReductionDate > @EndDate
			GROUP BY UnitID
			) UR ON UR.UnitID = U2.UnitID	
		where u2.dtfirstdeposit <= @EndDate	
		group by u2.unitid
	)  U1 on u1.unitid = tc.unitid
	--where p.plandesc = 'reeeflex' and c.yearqualif = 2016
	group by
		--c.conventionno,
		p.plandesc,
		c.yearqualif
	order by
		--c.conventionno,
		p.plandesc,
		c.yearqualif

END

/*
	SELECT
		u.unitid,
		fSubscInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.SubscInsur else 0 end),
		fBenefInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.BenefInsur else 0 end),
		fTaxOnInsurOldModal = SUM(case when m.modaldate < '2009-12-08' then Ct.TaxOnInsur else 0 end), 

		fSubscInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.SubscInsur else 0 end), 
		fBenefInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.BenefInsur else 0 end),
		fTaxOnInsurNewModal = SUM(case when m.modaldate >= '2009-12-08' then Ct.TaxOnInsur else 0 end)
	into #tmpCot
	FROM dbo.Un_Unit U
	JOIN un_modal m on u.modalid = m.modalid
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	WHERE Ct.OperID IN (
		SELECT O.OperID
		FROM Un_Oper O
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
		WHERE O.OperDate BETWEEN '2010-04-01' AND '2010-04-30' -- Opération de la période sélectionnée.
			AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
				OR O.OperTypeID = 'TRA' -- Inclus les TRA
				)
		)
	group by u.unitid

	select 
		p.plandesc,
		c.yearqualif,

		UnitQtyNewModal = sum(UnitQtyNewModal),
		UnitQtyOldModal = sum(UnitQtyOldModal),
		fSubscInsurOldModal = SUM(fSubscInsurOldModal),
		fBenefInsurOldModal = SUM(fBenefInsurOldModal),
		fTaxOnInsurOldModal = SUM(fTaxOnInsurOldModal), 

		fSubscInsurNewModal = SUM(fSubscInsurNewModal), 
		fBenefInsurNewModal = SUM(fBenefInsurNewModal),
		fTaxOnInsurNewModal = SUM(fTaxOnInsurNewModal)
	from #tmpCot tc
	JOIN dbo.Un_Unit u on tc.unitid = u.unitid
	JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
	JOIN un_plan p on c.planid = p.planid
	JOIN (
		SELECT
			u.unitid,
			UnitQtyNewModal = sum(case when m.modaldate >= '2009-12-08' then U.UnitQty+ISNULL(UR.UnitQty, 0) else 0 end),
			UnitQtyOldModal = sum(case when m.modaldate < '2009-12-08' then U.UnitQty+ISNULL(UR.UnitQty, 0) else 0 end) 
		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
		JOIN un_modal m on u.modalid = m.modalid
		LEFT JOIN (
			SELECT
				UnitID,
				UnitQty = SUM(UnitQty)
			FROM Un_UnitReduction
			WHERE ReductionDate > '2010-04-30'
			GROUP BY UnitID
			) UR ON UR.UnitID = U.UnitID	
		where u.dtfirstdeposit <= '2010-04-30'	
		group by u.unitid
	)  U1 on u1.unitid = tc.unitid
	group by
		p.plandesc,
		c.yearqualif
	order by
		p.plandesc,
		c.yearqualif

	drop table #tmpCot

*/

/*

	SELECT
		UnitQtyNewModal = sum(case when m.modaldate >= '2009-12-08' then U.UnitQty+ISNULL(UR.UnitQty, 0) else 0 end) 
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
	join un_modal m on u.modalid = m.modalid
	LEFT JOIN (
		SELECT
			UnitID,
			UnitQty = SUM(UnitQty)
		FROM Un_UnitReduction
		WHERE ReductionDate > '2010-04-30' -- Résiliation d'unités faites après la date de fin de période.
		GROUP BY UnitID
		) UR ON UR.UnitID = U.UnitID		
		
	where u.conventionid in (
	
		select u1.conventionid /*unitid*/ from 
		Un_Cotisation Ct 
		JOIN dbo.Un_Unit u1 on ct.unitid = u1.unitid
		WHERE Ct.OperID IN (
			SELECT O.OperID
			FROM Un_Oper O
			JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
			WHERE O.OperDate BETWEEN '2010-04-01' AND '2010-04-30' -- Opération de la période sélectionnée.
				and (Cotisation <> 0 or fee <> 0 or SubscInsur <> 0 or BenefInsur <> 0 or TaxOnInsur <> 0) 
				AND ( OT.TotalZero = 0  OR O.OperTypeID = 'TRA'  )
					)
		group by U1.conventionid
		having sum(Cotisation) <> 0 or sum(fee) <> 0 or sum(SubscInsur) <> 0 or sum(BenefInsur) <> 0 or sum(TaxOnInsur) <> 0 
		
		)
	--and  u.dtfirstdeposit <= '2010-04-30'
	
	select * from (
		select 
			u.conventionid,	
			oldmodal = sum(case when m.modaldate >= '2009-12-08' then 1 else 0 end), 
			newmodal = sum(case when m.modaldate < '2009-12-08' then 1 else 0 end)
		FROM dbo.Un_Unit U
		join un_modal m on u.modalid = m.modalid
		--JOIN dbo.Un_Convention c on u.conventionid = c.conventionid
		where u.dtfirstdeposit <= '2010-04-30'
		group by u.conventionid
	)v
	where oldmodal > 0 and newmodal > 0
*/


