/****************************************************************************************************
Copyrights (c) 2015 Gestion Universitas inc
Nom                 :	psREPR_RapportDetailCalculTauxConservation
Description         :	Pour le rapport SSRS "RapportDetailCalculTauxConservation" : permet de démontrer le calcul du taux de conservation
Valeurs de retours  :	Dataset 
Note                :	2015-03-25	Donald Huppé			Créaton

select *
from mo_human h
join un_rep r on h.humanid = r.repid
where h.lastname like '%laroc%'

exec psREPR_RapportDetailCalculTauxConservation '2015-03-22', 476221
*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportDetailCalculTauxConservation] 
	(
	@EnDateDu DATETIME, 
	@RepID INTEGER
	) 

as
BEGIN

	--set @EnDateDu = '2015-02-08'
	--set @RepID = 149665

DECLARE 
	@DateFrom datetime,
	@DateFromRepTreatment datetime,
	@DateToRepTreatment datetime,
	@DateDebutRatio datetime = '2014-10-06'

	-- Le début du calcul part d'il ya 24 mois plus un jour
	set @DateFrom = dateadd(DAY,1, DATEADD(MONTH, -24, @EnDateDu))
	
	-- La date du traitement où débute le calcul
	SELECT @DateFromRepTreatment = RepTreatmentDateFrom
	FROM (
		SELECT rt.RepTreatmentID, rt.RepTreatmentDate, RepTreatmentID0 = rt0.RepTreatmentID, RepTreatmentDateFrom = dateadd( DAY,1, rt0.RepTreatmentDate)
		from Un_RepTreatment rt
		join (
			select rt.RepTreatmentID, RepTreatmentID0 = max(rt0.RepTreatmentID)
			from Un_RepTreatment rt
			left join Un_RepTreatment rt0 on rt.RepTreatmentID > rt0.RepTreatmentID
			group by rt.RepTreatmentID
			) lrt on rt.RepTreatmentID = lrt.RepTreatmentID
		join Un_RepTreatment rt0 on rt0.RepTreatmentID = lrt.RepTreatmentID0
		)V
	WHERE dateadd(DAY,1, DATEADD(MONTH, -24, @EnDateDu)) BETWEEN RepTreatmentDateFrom AND RepTreatmentDate

	-- La date du traitement où se termine le calcul
	SELECT @DateToRepTreatment = RepTreatmentDate
	FROM (
		SELECT rt.RepTreatmentID, rt.RepTreatmentDate, RepTreatmentID0 = rt0.RepTreatmentID, RepTreatmentDateFrom = dateadd( DAY,1, rt0.RepTreatmentDate)
		from Un_RepTreatment rt
		join (
			select rt.RepTreatmentID, RepTreatmentID0 = max(rt0.RepTreatmentID)
			from Un_RepTreatment rt
			left join Un_RepTreatment rt0 on rt.RepTreatmentID > rt0.RepTreatmentID
			group by rt.RepTreatmentID
			) lrt on rt.RepTreatmentID = lrt.RepTreatmentID
		join Un_RepTreatment rt0 on rt0.RepTreatmentID = lrt.RepTreatmentID0
		)V
	WHERE @EnDateDu BETWEEN RepTreatmentDateFrom AND RepTreatmentDate

	--SELECT @DateFrom
	--select @DateToRepTreatment
	--RETURN

	create table #GrossANDNetUnits (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 

	create table #GrossANDNetUnitsSplit (
		UnitID INTEGER,
		RepID INTEGER,
		BossID INTEGER,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT
			) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateFromRepTreatment, @DateToRepTreatment, 0 , 1

	insert into #GrossANDNetUnitsSplit
		SELECT
			UnitID,
			RepID,
			BossID,
			Brut,
			Retraits = 0,
			Reinscriptions = 0
		from #GrossANDNetUnits
		where Brut <> 0
		UNION ALL
		SELECT
			UnitID,
			RepID,
			BossID,
			Brut = 0,
			Retraits,
			Reinscriptions = 0
		from #GrossANDNetUnits
		where Retraits <> 0
		UNION ALL
		SELECT
			UnitID,
			RepID,
			BossID,
			Brut = 0,
			Retraits =0,
			Reinscriptions
		from #GrossANDNetUnits
		where Reinscriptions <> 0

	select 
		GNU.repid,
		c.conventionno,
		GNU.UnitID,
		RepName = HR.firstname + ' ' + HR.lastname,
		BossName = HB.firstname + ' ' + HB.lastname,
		SName =  Hs.firstname + ' ' + Hs.lastname,
		bName = hben.firstname + ' ' + hben.lastname,
		rtt.RepTreatmentID,
		rtt.RepTreatmentDateFrom,
		rtt.RepTreatmentDate,
		DateDeDebutDuCalcul = @DateFrom,
		DateTransaction = isnull(ur1.ReductionDate,u.dtfirstdeposit),
		FaitPartieDuCalcul = case when isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN @DateFrom AND @EnDateDu THEN 1 else 0 end,

		Brut = Brut,
		Retraits = Retraits,
		Reinscriptions = Reinscriptions,
		Net = GNU.Brut - GNU.Retraits + GNU.Reinscriptions,

		BrutCalcul = Brut * case when isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN @DateFrom AND @EnDateDu THEN 1 else 0 end,
		RetraitsCalcul = Retraits * case when isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN @DateFrom AND @EnDateDu THEN 1 else 0 end,
		ReinscriptionsCalcul = Reinscriptions * case when isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN @DateFrom AND @EnDateDu THEN 1 else 0 end,
		NetCalcul = (GNU.Brut - GNU.Retraits + GNU.Reinscriptions) * case when isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN @DateFrom AND @EnDateDu THEN 1 else 0 end,

		u.dtfirstdeposit,
		ur1.ReductionDate,
		u.SignatureDate,
		u.TerminatedDate,
		DateCodage = SD.StartDate
		,DateDuEstDateTraitement = isnull((select DISTINCT 1 from Un_RepTreatment where RepTreatmentDate = @EnDateDu),0)
	from #GrossANDNetUnitsSplit GNU
	JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
	JOIN dbo.mo_human hr on GNU.repid = hr.humanid
	left JOIN dbo.mo_human hb on GNU.BossId = hb.humanid 
	JOIN dbo.Un_Convention c on u.conventionID = c.conventionID
	JOIN dbo.mo_human hs on c.subscriberid = hs.humanid
	JOIN dbo.mo_human hben on c.beneficiaryid = hben.humanid
	left join (
		SELECT 
			U.UnitID,
			UnitQtyRes = UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END,
			ReductionDate = max(ur.ReductionDate)

		FROM Un_UnitReduction UR 
		JOIN dbo.Un_Unit U  ON U.UnitID = UR.UnitID
		JOIN Un_Rep R on U.RepID = R.RepID
		JOIN Un_Modal M  ON M.ModalID = U.ModalID	
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo
		LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo
		WHERE UR.FeeSumByUnit < M.FeeByUnit
			AND (isnull(URR.bReduitTauxConservationRep,1) = 1) 
		group BY
			U.UnitID,
			UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
		) ur1 on u.unitid = ur1.UnitID and gnu.Retraits = ur1.UnitQtyRes
	left join (
		select 
			unitid,
			startDate = min(startDate) 
		from Un_UnitUnitState
		group by unitid
		) sd on sd.unitid = U.unitid
	left join (
		SELECT rt.RepTreatmentID, rt.RepTreatmentDate, RepTreatmentID0 = rt0.RepTreatmentID, RepTreatmentDateFrom = dateadd( DAY,1, rt0.RepTreatmentDate)
		from Un_RepTreatment rt
		join (
			select rt.RepTreatmentID, RepTreatmentID0 = max(rt0.RepTreatmentID)
			from Un_RepTreatment rt
			left join Un_RepTreatment rt0 on rt.RepTreatmentID > rt0.RepTreatmentID
			group by rt.RepTreatmentID
			) lrt on rt.RepTreatmentID = lrt.RepTreatmentID
		join Un_RepTreatment rt0 on rt0.RepTreatmentID = lrt.RepTreatmentID0
		)rtt on isnull(ur1.ReductionDate,u.dtfirstdeposit) BETWEEN rtt.RepTreatmentDateFrom and rtt.RepTreatmentDate

	where 
		GNU.repid = @RepID 
		and (Brut <> 0 or Retraits <> 0 or Reinscriptions <> 0)
	order by isnull(ur1.ReductionDate,u.dtfirstdeposit)

END


