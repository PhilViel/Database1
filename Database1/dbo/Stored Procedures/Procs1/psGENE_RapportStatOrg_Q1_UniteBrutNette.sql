
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q1_UniteBrutNette
Nom du service		:		psGENE_RapportStatOrg_Q1_UniteBrutNette
But					:		Pour le rapport de statistiques orrganisationelles - Q1
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q1_UniteBrutNette '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q1_UniteBrutNette] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

	set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

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

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteUnitésBrutes float
			,QteUnitéNettes float
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

	while @i <= @QtePeriodePrecedent
	begin 

		delete from #GrossANDNetUnits
			

		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @DateFrom, @DateTo, 0, 1

		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,QteUnitésBrutes = round(sum(brut) ,3)
			,QteUnitéNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		from #GrossANDNetUnits gnu

		set @i = @i + 1
	end	 --while

	


	--select * from #Result

	INSERT into #Final values (
		1
		,'Unité Brutes'
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteUnitésBrutes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)

	)


	INSERT into #Final values (
		2
		,'Unité Nettes'
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteUnitéNettes from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)

	)

	SELECT * from #Final

	drop table #GrossANDNetUnits
	drop table #Result

END