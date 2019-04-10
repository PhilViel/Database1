
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q7_QteUnite_DEBUT_RES
Nom du service		:		psGENE_RapportStatOrg_Q7_QteUnite_DEBUT_RES
But					:		Pour le rapport de statistiques orrganisationelles - Q7
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q7_QteUnite_DEBUT_RES '2016-05-31', 1 '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q7_QteUnite_DEBUT_RES] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteUniteNetteFINPeriodePrec FLOAT
			,QteUniteResilPeriodeDemandee FLOAT
			)

	create table #Final (
		Sort int,
		Quoi varchar(100),
		v0 float,
		v1 float,
		v2 float,
		v3 float,
		v4 float,
		v5 float
		)

	
	--declare	 @EnDateDu datetime = '2016-05-31'
	declare	 @DateFrom datetime
	declare	 @DateTo datetime
	declare @i int = 0
	declare @j int = 0
	

	while @i <= @QtePeriodePrecedent
	begin 

		

		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

	
		insert into #Result
		select 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,QteUniteNetteFINPeriodePrec = sum(QteUniteNetteFINPeriodePrec)
			,QteUniteResilPeriodeDemandee = sum(QteUniteResilPeriodeDemandee)
		from (
			select DISTINCT
				c.ConventionNo
				,u.UnitID
				,QteUniteNetteFINPeriodePrec = u.UnitQty + isnull(ur.QteRes,0)
				,QteUniteResilPeriodeDemandee= isnull(urAfter.QteRes,0)
			from 
				Un_Convention c
				join (
					select 
						Cs.conventionid ,
						ccs.startdate,
						cs.ConventionStateID
					from 
						un_conventionconventionstate cs
						join (
							select 
							conventionid,
							startdate = max(startDate)
							from un_conventionconventionstate
							where startDate < @DateFrom
							group by conventionid
							) ccs on ccs.conventionid = cs.conventionid 
								and ccs.startdate = cs.startdate 
								and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
					) css on C.conventionid = css.conventionid
				join Un_Unit u on c.ConventionID = u.ConventionID
				LEFT join (select UnitID, QteRes = sum(UnitQty) from Un_UnitReduction where ReductionDate >= @DateFrom group by UnitID) ur on u.UnitID = ur.UnitID
				LEFT join (select UnitID, QteRes = sum(UnitQty) from Un_UnitReduction where ReductionDate BETWEEN @DateFrom and @DateTo group by UnitID) urAfter on u.UnitID = urAfter.UnitID
			where 
				u.dtFirstDeposit < @DateFrom
			) V



		set @i = @i + 1
	end	 --while @i

	
--	select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,QteUniteNetteFINPeriodePrec = sum(QteUniteNetteFINPeriodePrec)
			,QteUniteResilPeriodeDemandee = sum(QteUniteResilPeriodeDemandee)
	*/

	INSERT into #Final values (
		1
		,'QteUniteNetteFINPeriodePrec'
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteUniteNetteFINPeriodePrec from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'QteUniteResilPeriodeDemandee'
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteUniteResilPeriodeDemandee from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	
	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'