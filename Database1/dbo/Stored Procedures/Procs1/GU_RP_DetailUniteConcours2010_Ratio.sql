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
Nom                 :	GU_RP_DetailUniteConcours2010
Description         :	Pour le rapport SSRS "DetailUniteConcours2010"
Valeurs de retours  :	Dataset 
Note                :	2010-01-26	Donald Huppé			Créaton
						2010-02-10	Donald Huppé			on va chercher toutes les données et on filtre par repid à la fin.
																		Car bug quand on demande un repid qui est un boss dans SL_UN_RepGrossANDNetUnits
						2010-04-13	Donald Huppé			Ajout du bénéficiaire
						2010-05-02	Donald Huppé			Mettre un left join sur hb car le bossid peu être 0
						2010-06-29	Donald Huppé			Ajout des informations SignatureDate et DateCodage pour le concours "Doubblez votre été"
						2010-10-04	Donald Huppé			Ajout de age du bénef et données du concours "vers le prochain niveau"
						2013-12-16	Pierre-Luc Simard	Ajustement des majorations
						2013-12-17	Pierre-Luc Simard	Retrait de la majoration des Reeeflex de 1.35
                        2018-11-12  Pierre-Luc Simard   N'est plus utilisée
select *
from mo_human h
join un_rep r on h.humanid = r.repid
where h.lastname = 'marchand'

drop proc GU_RP_DetailUniteConcours2010_Ratio

exec GU_RP_DetailUniteConcours2010_Ratio '2014-08-01', '2014-10-01', NULL, NULL, 149497, 'R'
*********************************************************************************************************************/
CREATE procedure [dbo].[GU_RP_DetailUniteConcours2010_Ratio] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@StartDateMaj DATETIME = NULL,
	@EndDateMaj DATETIME = NULL,
	@RepID INTEGER,
	@BossOrRep varchar(1) -- B ou R
	) 

as
BEGIN

SELECT 1/0

/*
--set @StartDateMaj = isnull(@StartDateMaj,'1950-01-01')
--set @EndDateMaj = isnull(@EndDateMaj,'4000-01-01')

if @StartDateMaj is null and @EndDateMaj is NOT Null
	begin
	SET @StartDateMaj = '1901-01-01'
	end

if @StartDateMaj is NOT null and @EndDateMaj is Null
	begin
	SET @EndDateMaj = '4000-01-01'
	end

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
		Reinscriptions24 FLOAT
		
		,RetraitsOri FLOAT,
		ReinscriptionsOri FLOAT,
		Retraits24Ori FLOAT,
		Reinscriptions24Ori FLOAT,

		RetraitsFeeSumByUnit FLOAT,
		ReinscriptionsFeeSumByUnit FLOAT,
		Retraits24FeeSumByUnit FLOAT,
		Reinscriptions24FeeSumByUnit FLOAT		
		) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_AvantApresRatio NULL, @StartDate, @EndDate, 0 , 1 -- on va chercher toutes les données et on filtre par repid à la fin

	select 
		--UnitID_Ori,
		GNU.repid,
		GNU.bossid,
		c.conventionno,
		GNU.UnitID,
		RepName = HR.firstname + ' ' + HR.lastname,
		BossName = HB.firstname + ' ' + HB.lastname,
		SName =  Hs.firstname + ' ' + Hs.lastname,
		HR.firstname,
		HR.lastname,
		sFirstName = hs.firstname,
		sLastName = hs.lastname,
		bName = hben.firstname + ' ' + hben.lastname,

		BrutInd = case when c.planid = 4 then Brut else 0 end,
		RetraitsInd = case when c.planid = 4 then Retraits else 0 end,
		ReinscriptionsInd = case when c.planid = 4 then Reinscriptions else 0 end,

		BrutUniv = case when c.planid = 8 then Brut else 0 end,
		RetraitsUniv = case when c.planid = 8 then Retraits else 0 end,
		ReinscriptionsUniv = case when c.planid = 8 then Reinscriptions else 0 end,

		BrutRFlex = case when c.planid  in (10,12) then Brut else 0 end,
		RetraitsRFlex = case when c.planid  in (10,12) then Retraits else 0 end,
		ReinscriptionsRFlex = case when c.planid  in (10,12) then Reinscriptions else 0 end,

		EstMajore = '',
		u.dtfirstdeposit,
		u.SignatureDate,
		u.TerminatedDate,
		DateCodage = SD.StartDate,

		NetMajore = (Brut - Retraits + Reinscriptions)  
		,BenBirthdate = dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit)
		,UniteVersProchNiv =  (Brut - Retraits + Reinscriptions) 
							* case 
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 0 and 1 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 1
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 2 and 3 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 1.5
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 4 and 5 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 2
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 6 and 7 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 3
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 8 and 9 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 4
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 10 and 11 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 5
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 12 and 13 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 6
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 14 and 15 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 7
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) = 16 and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 8
				/*GLPI 4425*/	when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) in (16,17) and c.conventionno like 'I%' and U.dtfirstdeposit between '2013-01-14' and '2013-03-24' then 8
								else 1
								end

		,RetraitsIndOri = case when c.planid = 4 then RetraitsOri else 0 end,
		ReinscriptionsIndOri = case when c.planid = 4 then ReinscriptionsOri else 0 end,
		RetraitsIndFeeSumByUnit  = case when c.planid = 4 then gnu.RetraitsFeeSumByUnit else 0 end,
		ReinscriptionsIndFeeSumByUnit  = case when c.planid = 4 then gnu.ReinscriptionsFeeSumByUnit else 0 end,

		RetraitsUnivOri = case when c.planid = 8 then RetraitsOri else 0 end,
		ReinscriptionsUnivOri = case when c.planid = 8 then ReinscriptionsOri else 0 end,
		RetraitsUnivFeeSumByUnit  = case when c.planid = 8 then gnu.RetraitsFeeSumByUnit else 0 end,
		ReinscriptionsUnivFeeSumByUnit  = case when c.planid = 8 then gnu.ReinscriptionsFeeSumByUnit else 0 end,

		RetraitsRFlexOri = case when c.planid  in (10,12) then RetraitsOri else 0 end,
		ReinscriptionsRFlexOri = case when c.planid  in (10,12) then ReinscriptionsOri else 0 end,
		RetraitsRFlexFeeSumByUnit  = case when c.planid in (10,12) then gnu.RetraitsFeeSumByUnit else 0 end,
		ReinscriptionsRFlexFeeSumByUnit  = case when c.planid in (10,12) then gnu.ReinscriptionsFeeSumByUnit else 0 end
		,UnitReductionReason, bReduitTauxConservationRep

	from #GrossANDNetUnits GNU
	JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
	JOIN dbo.Mo_Human hr on GNU.repid = hr.humanid
	left JOIN dbo.Mo_Human hb on GNU.BossId = hb.humanid -- left join sur hb car le bossid peut être 0 -- cas de divorce (InforceDate est avant l'embauche du Rep)
	JOIN dbo.Un_Convention c on u.conventionID = c.conventionID
	JOIN dbo.Mo_Human hs on c.subscriberid = hs.humanid
	JOIN dbo.Mo_Human hben on c.beneficiaryid = hben.humanid
	left join (
		select 
			unitid,
			startDate = min(startDate) 
		from Un_UnitUnitState
		group by unitid
		) sd on sd.unitid = U.unitid
	left join (
		select ur1.UnitID, urr.UnitReductionReason, urr.bReduitTauxConservationRep
		from (
			select UnitID,max_UnitReductionID =  max(UnitReductionID)
			from Un_UnitReduction ur3
			join Un_UnitReductionReason urr2 on ur3.UnitReductionReasonID = urr2.UnitReductionReasonID
			where urr2.bReduitTauxConservationRep = 1
			group by UnitID
			)r
		join Un_UnitReduction ur1 on r.max_UnitReductionID = ur1.UnitReductionID
		join Un_UnitReductionReason urr on ur1.UnitReductionReasonID = urr.UnitReductionReasonID
		)ur2 on GNU.unitid = ur2.UnitID
	where ( (@BossOrRep = 'R' and GNU.repid = @RepID) or ( @BossOrRep = 'B' and GNU.bossid = @RepID))
		and (Brut <> 0 or Retraits <> 0 or Reinscriptions <> 0)
	order by u.dtfirstdeposit
*/
END