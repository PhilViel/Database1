
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q8_QteUnite_RES_DELAI_SIGN
Nom du service		:		psGENE_RapportStatOrg_Q8_QteUnite_RES_DELAI_SIGN
But					:		Pour le rapport de statistiques orrganisationelles - Q8
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q8_QteUnite_RES_DELAI_SIGN '2016-12-31', 0 
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						2017-04-24					Donald Huppé							Correction des plage de mois
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q8_QteUnite_RES_DELAI_SIGN] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,Mois_1 FLOAT
			,Mois_2 FLOAT
			,Mois_3 FLOAT
			,Mois_4 FLOAT
			,Mois_5 FLOAT
			,Mois_6 FLOAT
			,Mois_7 FLOAT
			,Mois_8 FLOAT
			,Mois_9 FLOAT
			,Mois_10 FLOAT
			,Mois_11 FLOAT
			,Mois_12 FLOAT
			,Mois_12_18 FLOAT
			,Mois_18_24 FLOAT
			,Mois_24_36 FLOAT
			,Mois_36_48 FLOAT
			,Mois_48_plus FLOAT

			,QteSousc_mois_1 INT
			,QteSousc_mois_2 INT
			,QteSousc_mois_3 INT
			,QteSousc_mois_4 INT
			,QteSousc_mois_5 INT
			,QteSousc_mois_6 INT
			,QteSousc_mois_7 INT
			,QteSousc_mois_8 INT
			,QteSousc_mois_9 INT
			,QteSousc_mois_10 INT
			,QteSousc_mois_11 INT
			,QteSousc_mois_12 INT
			,QteSousc_mois_12_18 INT
			,QteSousc_mois_18_24 INT
			,QteSousc_mois_24_36 INT
			,QteSousc_mois_36_48 INT
			,QteSousc_Mois_48_plus INT

			)

	create table #Final (
		Sort FLOAT,
		Quoi varchar(100),
		v01 float,
		v02 float,
		v11 float,
		v12 float,
		v21 float,
		v22 float,
		v31 float,
		v32 float,
		v41 float,
		v42 float,
		v51 float,
		v52 float
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
	/*
mois 1
mois 2
mois 3
mois 4
mois 5
mois 6
mois 7
mois 8
mois 9
mois 10
mois 11
mois 12
mois 13  à 18
mois 19 à 24
mois 25 à 36
mois 37 à 48
mois 49 ou plus
	
	*/

		select 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,Mois_1 = sum(QteUniteRES_0_1mois)
			,Mois_2 = sum(QteUniteRES_1_2mois)
			,Mois_3 = sum(QteUniteRES_2_3mois)
			,Mois_4 = sum(QteUniteRES_3_4mois)
			,Mois_5 = sum(QteUniteRES_4_5mois)
			,Mois_6 = sum(QteUniteRES_5_6mois)
			,Mois_7 = sum(QteUniteRES_6_7mois)
			,Mois_8 = sum(QteUniteRES_7_8mois)
			,Mois_9 = sum(QteUniteRES_8_9mois)
			,Mois_10 = sum(QteUniteRES_9_10mois)
			,Mois_11 = sum(QteUniteRES_10_11mois)
			,Mois_12 = sum(QteUniteRES_11_12mois)
			,Mois_12_18 = SUM(QteUniteRES_12_18mois)
			,Mois_18_24 = SUM(QteUniteRES_18_24mois)
			,Mois_24_36 = SUM(QteUniteRES_24_36mois)
			,Mois_36_48 = SUM(QteUniteRES_36_48mois)
			,Mois_48_plus = SUM(QteUniteRES_48_plus)


			,QteSousc_mois_1 = COUNT (DISTINCT QteSousc_0_1mois )
			,QteSousc_mois_2 = COUNT (DISTINCT QteSousc_1_2mois )
			,QteSousc_mois_3 = COUNT (DISTINCT QteSousc_2_3mois )
			,QteSousc_mois_4 = COUNT (DISTINCT QteSousc_3_4mois )
			,QteSousc_mois_5 = COUNT (DISTINCT QteSousc_4_5mois )
			,QteSousc_mois_6 = COUNT (DISTINCT QteSousc_5_6mois )
			,QteSousc_mois_7 = COUNT (DISTINCT QteSousc_6_7mois )
			,QteSousc_mois_8 = COUNT (DISTINCT QteSousc_7_8mois )
			,QteSousc_mois_9 = COUNT (DISTINCT QteSousc_8_9mois )
			,QteSousc_mois_10 = COUNT (DISTINCT QteSousc_9_10mois )
			,QteSousc_mois_11 = COUNT (DISTINCT QteSousc_10_11mois )
			,QteSousc_mois_12 = COUNT (DISTINCT QteSousc_11_12mois )
			,QteSousc_mois_12_18 = COUNT (DISTINCT QteSousc_12_18mois )
			,QteSousc_mois_18_24 = COUNT (DISTINCT QteSousc_18_24mois )
			,QteSousc_mois_24_36 = COUNT (DISTINCT QteSousc_24_36mois )
			,QteSousc_mois_36_48 = COUNT (DISTINCT QteSousc_36_48mois )
			,QteSousc_Mois_48_plus = COUNT (DISTINCT QteSousc_48_plus )

		from (

			select DISTINCT
				ur.UnitReductionID
				,c.ConventionNo, u.UnitID
				,AnneeRes = year(ur.ReductionDate) 
				,QteUniteRES_0_1mois = case when ur.ReductionDate > dateadd(MONTH,0, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,1, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_1_2mois = case when ur.ReductionDate > dateadd(MONTH,1, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,2, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_2_3mois = case when ur.ReductionDate > dateadd(MONTH,2, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,3, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_3_4mois = case when ur.ReductionDate > dateadd(MONTH,3, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,4, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_4_5mois = case when ur.ReductionDate > dateadd(MONTH,4, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,5, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_5_6mois = case when ur.ReductionDate > dateadd(MONTH,5, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,6, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_6_7mois = case when ur.ReductionDate > dateadd(MONTH,6, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,7, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_7_8mois = case when ur.ReductionDate > dateadd(MONTH,7, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,8, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_8_9mois = case when ur.ReductionDate > dateadd(MONTH,8, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,9, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_9_10mois = case when ur.ReductionDate > dateadd(MONTH,9, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,10, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_10_11mois = case when ur.ReductionDate > dateadd(MONTH,10, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,11, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_11_12mois = case when ur.ReductionDate > dateadd(MONTH,11, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,12, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_12_18mois = case when ur.ReductionDate > dateadd(MONTH,12, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,18, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_18_24mois = case when ur.ReductionDate > dateadd(MONTH,18, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,24, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_24_36mois = case when ur.ReductionDate > dateadd(MONTH,24, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,36, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_36_48mois = case when ur.ReductionDate > dateadd(MONTH,36, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,48, u.SignatureDate) then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end
				,QteUniteRES_48_plus =   case when ur.ReductionDate > dateadd(MONTH,48, u.SignatureDate)															then (case when o.OperTypeID <> 'TRI' then ur.UnitQty else ur.UnitQty - 1 end) else 0 end

				,QteSousc_0_1mois = case when ur.ReductionDate > dateadd(MONTH,0, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,1, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_1_2mois = case when ur.ReductionDate > dateadd(MONTH,1, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,2, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_2_3mois = case when ur.ReductionDate > dateadd(MONTH,2, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,3, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_3_4mois = case when ur.ReductionDate > dateadd(MONTH,3, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,4, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_4_5mois = case when ur.ReductionDate > dateadd(MONTH,4, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,5, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_5_6mois = case when ur.ReductionDate > dateadd(MONTH,5, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,6, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_6_7mois = case when ur.ReductionDate > dateadd(MONTH,6, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,7, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_7_8mois = case when ur.ReductionDate > dateadd(MONTH,7, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,8, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_8_9mois = case when ur.ReductionDate > dateadd(MONTH,8, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,9, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_9_10mois = case when ur.ReductionDate > dateadd(MONTH,9, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,10, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_10_11mois = case when ur.ReductionDate > dateadd(MONTH,10, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,11, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_11_12mois = case when ur.ReductionDate > dateadd(MONTH,11, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,12, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_12_18mois = case when ur.ReductionDate > dateadd(MONTH,12, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,18, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_18_24mois = case when ur.ReductionDate > dateadd(MONTH,18, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,24, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_24_36mois = case when ur.ReductionDate > dateadd(MONTH,24, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,36, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_36_48mois = case when ur.ReductionDate > dateadd(MONTH,36, u.SignatureDate) and ur.ReductionDate <= dateadd(MONTH,48, u.SignatureDate) then c.SubscriberID else NULL end
				,QteSousc_48_plus =   case when ur.ReductionDate > dateadd(MONTH,48, u.SignatureDate)															 then c.SubscriberID else NULL end

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
				--year(ur.ReductionDate) BETWEEN 2010 and 2014
				ur.ReductionDate BETWEEN @DateFrom and @DateTo
				and o.OperTypeID in ( 'TRI', 'OUT','RES','RET')
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				and oc1.OperID is NULL
				and oc2.OperSourceID is NULL
			) V




		set @i = @i + 1
	end	 --while @i

	
--	select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,Mois_1 FLOAT
			,Mois_2 FLOAT
			,Mois_3 FLOAT
			,Mois_4 FLOAT
			,Mois_5 FLOAT
			,Mois_6 FLOAT
			,Mois_7 FLOAT
			,Mois_8 FLOAT
			,Mois_9 FLOAT
			,Mois_10 FLOAT
			,Mois_11 FLOAT
			,Mois_12 FLOAT

			,Mois_12_18 FLOAT
			,Mois_18_24 FLOAT
			,Mois_24_36 FLOAT
			,Mois_36_48 FLOAT
			,Mois_48_plus FLOAT
	*/

	INSERT into #Final values (
		1
		,'Mois_1'
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	INSERT into #Final values (
		2
		,'Mois_2'
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	INSERT into #Final values (
		3
		,'Mois_3'
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		4
		,'Mois_4'
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'Mois_5'
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		6
		,'Mois_6'
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		7
		,'Mois_7'
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		8
		,'Mois_8'
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		9
		,'Mois_9'
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		10
		,'Mois_10'
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		11
		,'Mois_11'
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		12
		,'Mois_12'
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		13
		,'Mois_12_18'
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		14
		,'Mois_18_24'
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		15
		,'Mois_24_36'
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		16
		,'Mois_36_48'
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		17
		,'Mois_48_plus'
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'