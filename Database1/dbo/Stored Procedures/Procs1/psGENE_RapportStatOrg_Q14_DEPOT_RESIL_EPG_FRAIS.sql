/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q14_DEPOT_RESIL_EPG_FRAIS
Nom du service		:		psGENE_RapportStatOrg_Q14_DEPOT_RESIL_EPG_FRAIS
But					:		Pour le rapport de statistiques orrganisationelles - Q14
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q14_DEPOT_RESIL_EPG_FRAIS '2016-05-31', 5
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-20					Donald Huppé							Création du Service
						2018-09-07					Maxime Martel							JIRA MP-699 Ajout de OpertypeID COU
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q14_DEPOT_RESIL_EPG_FRAIS] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime,
			Regime VARCHAR (50),
			DepotEpg1erDepotAvant MONEY,
			DepotFrais1erDepotAvant MONEY,
			DepotEpg1erDepotPendant MONEY,
			DepotFrais1erDepotPendant MONEY,

			RESEpg1erDepotAvant MONEY,
			RESFrais1erDepotAvant MONEY,
			RESEpg1erDepotPendant MONEY,
			RESFrais1erDepotPendant MONEY
			)

	create table #Final (
		Sort int,
		Quoi varchar(100),
		v01 float,
		v02 float,
		v03 float,
		v11 float,
		v12 float,
		v13 float,
		v21 float,
		v22 float,
		v23 float,
		v31 float,
		v32 float,
		v33 float,
		v41 float,
		v42 float,
		v43 float,
		v51 float,
		v52 float,
		v53 float
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
			DateFrom = @DateFrom,
			DateTo = @DateTo,
			Regime,
			DepotEpg1erDepotAvant = SUM(DepotEpg1erDepotAvant),
			DepotFrais1erDepotAvant = sum(DepotFrais1erDepotAvant),
			DepotEpg1erDepotPendant = SUM(DepotEpg1erDepotPendant),
			DepotFrais1erDepotPendant = sum(DepotFrais1erDepotPendant),

			RESEpg1erDepotAvant = SUM(RESEpg1erDepotAvant),
			RESFrais1erDepotAvant = SUM(RESFrais1erDepotAvant),
			RESEpg1erDepotPendant = SUM(RESEpg1erDepotPendant),
			RESFrais1erDepotPendant = SUM(RESFrais1erDepotPendant)

		from (
			SELECT 
				Regime = rr.vcDescription,
				DepotEpg1erDepotAvant = SUM(case when u.dtFirstDeposit < @DateFrom then CT.Cotisation else 0 end),
				DepotFrais1erDepotAvant = sum(case when u.dtFirstDeposit < @DateFrom then CT.Fee else 0 end),
				DepotEpg1erDepotPendant = SUM(case when u.dtFirstDeposit BETWEEN @DateFrom  and @DateTo then CT.Cotisation else 0 end),
				DepotFrais1erDepotPendant = sum(case when u.dtFirstDeposit BETWEEN @DateFrom  and @DateTo then CT.Fee else 0 end),

				RESEpg1erDepotAvant = 0,
				RESFrais1erDepotAvant = 0,
				RESEpg1erDepotPendant = 0,
				RESFrais1erDepotPendant = 0

			FROM Un_Convention c
			join un_plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			join Un_Unit u ON c.ConventionID = u.ConventionID
			JOIN Un_Cotisation CT ON u.UnitID = CT.UnitID
			JOIN Un_Oper o on CT.OperID = o.OperID
			left join un_tio t on t.iTINOperID = o.OperID
			WHERE 
				o.OperDate BETWEEN @DateFrom  and @DateTo
				AND o.OperTypeID IN ('CPA', 'CHQ', 'PRD', 'RDI', 'TIN', 'NSF', 'COU')
				and t.iTIOID is null
			GROUP BY
				rr.vcDescription

			UNION ALL	

			SELECT 
				Regime = rr.vcDescription,
				DepotEpg1erDepotAvant = 0,
				DepotFrais1erDepotAvant = 0,
				DepotEpg1erDepotPendant = 0,
				DepotFrais1erDepotPendant = 0,

				RESEpg1erDepotAvant = SUM(case when u.dtFirstDeposit < @DateFrom then CT.Cotisation else 0 end),
				RESFrais1erDepotAvant = sum(case when u.dtFirstDeposit < @DateFrom then CT.Fee else 0 end),
				RESEpg1erDepotPendant = SUM(case when u.dtFirstDeposit BETWEEN @DateFrom  and @DateTo then CT.Cotisation else 0 end),
				RESFrais1erDepotPendant = sum(case when u.dtFirstDeposit BETWEEN @DateFrom  and @DateTo then CT.Fee else 0 end)

			FROM Un_Convention c
			join un_plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			join Un_Unit u ON c.ConventionID = u.ConventionID
			JOIN Un_Cotisation CT ON u.UnitID = CT.UnitID
			JOIN Un_Oper o on CT.OperID = o.OperID
			left join un_tio t on t.iOUTOperID = o.OperID
			WHERE 
				o.OperDate BETWEEN @DateFrom  and @DateTo
				AND o.OperTypeID IN ('OUT', 'RES', 'RET')
				and t.iTIOID is null
			GROUP BY
				rr.vcDescription
			) V
		GROUP BY
			Regime

		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result 

	/*
			DepotEpg1erDepotAvant MONEY,
			DepotFrais1erDepotAvant MONEY,
			DepotEpg1erDepotPendant MONEY,
			DepotFrais1erDepotPendant MONEY,

			RESEpg1erDepotAvant MONEY,
			RESFrais1erDepotAvant MONEY,
			RESEpg1erDepotPendant MONEY,
			RESFrais1erDepotPendant MONEY

	*/

	--RETURN

	INSERT into #Final values (
		1
		,'DepotEpg1erDepotAvant'
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		2
		,'DepotFrais1erDepotAvant'
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		3
		,'DepotEpg1erDepotPendant'
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select DepotEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		4
		,'DepotFrais1erDepotPendant'
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select DepotFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		5
		,'RESEpg1erDepotAvant'
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		6
		,'RESFrais1erDepotAvant'
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotAvant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		7
		,'RESEpg1erDepotPendant'
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select RESEpg1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)

	INSERT into #Final values (
		8
		,'RESFrais1erDepotPendant'
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 AND REGIME = 'Individuel')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Reeeflex')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Universitas')
		,(select RESFrais1erDepotPendant from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 AND REGIME = 'Individuel')
		)


	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'