/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q15_QteSouscRIN_RESOUT
Nom du service		:		psGENE_RapportStatOrg_Q15_QteSouscRIN_RESOUT
But					:		Pour le rapport de statistiques orrganisationelles - Q15
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q15_QteSouscRIN_RESOUT '2016-05-31', 5


Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :

						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-08-04					Donald Huppé							Création du Service

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q15_QteSouscRIN_RESOUT] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
)
AS
BEGIN

    set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteSousc_RIN INT
			,QteSousc_RES_OUT INT
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
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,QteSousc_RIN = sum(QteSousc_RIN )
			,QteSousc_RES_OUT = sum(QteSousc_RES_OUT)

		from (
			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,QteSousc_RIN = COUNT(DISTINCT C.SubscriberID)
				,QteSousc_RES_OUT = 0
			from Un_Unit u 
			join Un_Convention c on u.ConventionID= c.ConventionID
			join Mo_Human hb on c.BeneficiaryID = hb.HumanID
			join Un_Cotisation ct on U.UnitID = CT.UnitID
			join un_oper o on ct.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperSourceID
			WHERE 
				O.OperTypeID = 'RIN'
				AND O.OperDate BETWEEN @DateFrom AND @DateTo
				AND oc1.OperID is NULL
				AND oc2.OperSourceID is NULL

			union ALL

			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,QteSousc_RIN = 0
				,QteSousc_RES_OUT = COUNT(DISTINCT C.SubscriberID)
			from 
				Un_Convention c
				join Un_Unit u on c.ConventionID = u.ConventionID
				join Un_UnitReduction ur on u.UnitID = ur.UnitID
				join Un_UnitReductionCotisation urc on ur.UnitReductionID = urc.UnitReductionID
				join Un_Cotisation ct on urc.CotisationID = ct.CotisationID
				join un_oper o on ct.OperID = o.OperID 
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperSourceID
			where  
				ur.ReductionDate BETWEEN @DateFrom and @DateTo
				and o.OperTypeID in ( 'OUT','RES')
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				and oc1.OperID is NULL
				and oc2.OperSourceID is NULL

		  ) V

		set @i = @i + 1
	end	 --while @i

	INSERT into #Final values (
		1
		,'QteSousc_RIN'
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_RIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'QteSousc_RES_OUT'
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_RES_OUT from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	select * from #Final order by sort

END
