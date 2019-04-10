/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q12_DEPOT_EPG_FRAIS
Nom du service		:		psGENE_RapportStatOrg_Q12_DEPOT_EPG_FRAIS
But					:		Pour le rapport de statistiques orrganisationelles - Q12
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q12_DEPOT_EPG_FRAIS '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						2018-09-07					Maxime Martel							JIRA MP-699 Ajout de OpertypeID COU
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q12_DEPOT_EPG_FRAIS] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,Epg FLOAT
			,Frais FLOAT
			,QteSousc INT
			,QteOper INT
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
			,Epg = sum(Epg)
			,Frais = sum(Frais)
			,QteSousc = count(DISTINCT V.SubscriberID)
			,QteOper = count(DISTINCT V.OperID)
		from (
			SELECT 
				c.SubscriberID,
				o.OperID,
				Epg = SUM(CT.Cotisation),
				Frais = sum(CT.Fee)
			FROM Un_Convention c
			join Un_Unit u ON c.ConventionID = u.ConventionID
			JOIN Un_Cotisation CT ON u.UnitID = CT.UnitID
			JOIN Un_Oper o on CT.OperID = o.OperID
			left join un_tio t on t.iTINOperID = o.OperID
			WHERE 
				o.OperDate BETWEEN @DateFrom  and @DateTo
				AND o.OperTypeID IN ('CPA', 'CHQ', 'PRD', 'RDI', 'TIN', 'NSF', 'COU')
				and t.iTIOID is null
			GROUP BY
				c.SubscriberID,
				o.OperID
			) V


		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,Epg FLOAT
			,Frais FLOAT
			,QteSousc INT
			,QteOper INT

	*/

	INSERT into #Final values (
		1
		,'Epg'
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Epg from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'Frais'
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Frais from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		2
		,'QteSousc'
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		2
		,'QteOper'
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteOper from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	
	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'