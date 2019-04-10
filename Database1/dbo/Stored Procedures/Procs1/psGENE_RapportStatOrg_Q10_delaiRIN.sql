
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q10_delaiRIN
Nom du service		:		psGENE_RapportStatOrg_Q10_delaiRIN
But					:		Pour le rapport de statistiques orrganisationelles - Q10
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q10_delaiRIN '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q10_delaiRIN] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteSubscriber_0 INT
			,QteSubscriber_1 INT
			,QteSubscriber_2 INT
			,QteSubscriber_3 INT
			,QteSubscriber_4 INT
			,QteSubscriber_5 INT
			,QteSubscriber_6 INT
			,QteSubscriber_7 INT
			,QteSubscriber_8 INT
			,QteSubscriber_9 INT
			,QteSubscriber_10 INT
			,QteSubscriber_11 INT
			,QteSubscriber_12 INT
			,QteSubscriber_13_18 INT
			,QteSubscriber_19_24 INT
			,QteSubscriber_25_36 INT
			,QteSubscriber_37_48 INT
			,QteSubscriber_49_Plus INT
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
			,QteSubscriber_0 = count(DISTINCT SubscriberID_0 )
			,QteSubscriber_1 = count(DISTINCT SubscriberID_1 )
			,QteSubscriber_2 = count(DISTINCT SubscriberID_2 )
			,QteSubscriber_3 = count(DISTINCT SubscriberID_3 )
			,QteSubscriber_4 = count(DISTINCT SubscriberID_4 )
			,QteSubscriber_5 = count(DISTINCT SubscriberID_5 )
			,QteSubscriber_6 = count(DISTINCT SubscriberID_6 )
			,QteSubscriber_7 = count(DISTINCT SubscriberID_7 )
			,QteSubscriber_8 = count(DISTINCT SubscriberID_8 )
			,QteSubscriber_9 = count(DISTINCT SubscriberID_9 )
			,QteSubscriber_10 = count(DISTINCT SubscriberID_10 )
			,QteSubscriber_11 = count(DISTINCT SubscriberID_11)
			,QteSubscriber_12 = count(DISTINCT SubscriberID_12)
			,QteSubscriber_13_18 = count(DISTINCT SubscriberID_13_18 )
			,QteSubscriber_19_24 = count(DISTINCT SubscriberID_19_24 )
			,QteSubscriber_25_36 = count(DISTINCT SubscriberID_25_36 )
			,QteSubscriber_37_48 = count(DISTINCT SubscriberID_37_48 )
			,QteSubscriber_49_Plus = count(DISTINCT SubscriberID_49_Plus )
		from (


			select 
				SubscriberID
				,SubscriberID_0 = case when DelaiRIN = 0 then q.SubscriberID else NULL END
				,SubscriberID_1 = case when DelaiRIN = 1 then q.SubscriberID else NULL END
				,SubscriberID_2 = case when DelaiRIN = 2 then q.SubscriberID else NULL END
				,SubscriberID_3 = case when DelaiRIN = 3 then q.SubscriberID else NULL END
				,SubscriberID_4 = case when DelaiRIN = 4 then q.SubscriberID else NULL END
				,SubscriberID_5 = case when DelaiRIN = 5 then q.SubscriberID else NULL END
				,SubscriberID_6 = case when DelaiRIN = 6 then q.SubscriberID else NULL END
				,SubscriberID_7 = case when DelaiRIN = 7 then q.SubscriberID else NULL END
				,SubscriberID_8 = case when DelaiRIN = 8 then q.SubscriberID else NULL END
				,SubscriberID_9 = case when DelaiRIN = 9 then q.SubscriberID else NULL END
				,SubscriberID_10 = case when DelaiRIN = 10 then q.SubscriberID else NULL END
				,SubscriberID_11 = case when DelaiRIN = 11 then q.SubscriberID else NULL END
				,SubscriberID_12 = case when DelaiRIN = 12 then q.SubscriberID else NULL END
				,SubscriberID_13_18 = case when DelaiRIN BETWEEN 13 and 18 then q.SubscriberID else NULL END
				,SubscriberID_19_24 = case when DelaiRIN BETWEEN 19 and 24 then q.SubscriberID else NULL END
				,SubscriberID_25_36 = case when DelaiRIN BETWEEN 25 and 36 then q.SubscriberID else NULL END
				,SubscriberID_37_48 = case when DelaiRIN BETWEEN 37 and 48 then q.SubscriberID else NULL END
				,SubscriberID_49_Plus = case when DelaiRIN >= 49 then q.SubscriberID else NULL END

			from (

				SELECT 
					C.SubscriberID
					,C.ConventionNo
					,DateRIN = min( o.OperDate)
					,rin.DateRIEstimé
					,rio.DateRIO
					,DelaiRIN = case 
									WHEN rio.iID_Convention_Destination is null THEN DATEDIFF(MONTH,rin.DateRIEstimé,min( o.OperDate))
									ELSE DATEDIFF(MONTH,rio.DateRIO,min( o.OperDate))

								end
									
				FROM Un_Convention C
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
				LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
				left JOIN (
					select c.ConventionID,
						DateRIEstimé = min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust))
					from Un_Convention c
					join Un_Unit u ON c.ConventionID = u.ConventionID
					JOIN Un_Modal m ON u.ModalID = m.ModalID
					JOIN Un_Plan p ON c.PlanID = p.PlanID
					WHERE ISNULL(u.IntReimbDate,'9999-12-31') <> '9999-12-31'
					group by c.ConventionID 
					)rin on rin.ConventionID = c.ConventionID
				LEFT JOIN (
					select r.iID_Convention_Destination,DateRIO = min(o.OperDate)
					from tblOPER_OperationsRIO r
					JOIN Un_Oper o on r.iID_Oper_RIO = o.OperID
					where r.bRIO_Annulee = 0 and r.bRIO_QuiAnnule = 0
					GROUP BY r.iID_Convention_Destination
					)rio on rio.iID_Convention_Destination = c.ConventionID

				WHERE O.OperTypeID = 'RIN'
					AND OC1.OperSourceID IS NULL
					AND OC2.OperID IS NULL
					AND O.OperDate BETWEEN @DateFrom and @DateTo -- @DateFrom AND @DateTo
				GROUP BY
					C.SubscriberID
					,C.ConventionNo
					,rin.DateRIEstimé
					, rio.iID_Convention_Destination
					,rio.DateRIO
				)q





			) V



		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,QteSubscriber_0 INT
			,QteSubscriber_1 INT
			,QteSubscriber_2 INT
			,QteSubscriber_3 INT
			,QteSubscriber_4 INT
			,QteSubscriber_5 INT
			,QteSubscriber_6 INT
			,QteSubscriber_7 INT
			,QteSubscriber_8 INT
			,QteSubscriber_9 INT
			,QteSubscriber_10 INT
			,QteSubscriber_11 INT
			,QteSubscriber_12 INT
			,QteSubscriber_13_18 INT
			,QteSubscriber_19_24 INT
			,QteSubscriber_25_36 INT
			,QteSubscriber_37_48 INT
			,QteSubscriber_49_Plus INT
	*/

	INSERT into #Final values (
		1
		,'QteSubscriber_0'
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_0 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	INSERT into #Final values (
		2
		,'QteSubscriber_1'
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		3
		,'QteSubscriber_2'
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		4
		,'QteSubscriber_3'
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'QteSubscriber_4'
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		6
		,'QteSubscriber_5'
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		7
		,'QteSubscriber_6'
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		8
		,'QteSubscriber_7'
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		9
		,'QteSubscriber_8'
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		10
		,'QteSubscriber_9'
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		11
		,'QteSubscriber_10'
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		12
		,'QteSubscriber_11'
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		13
		,'QteSubscriber_12'
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		14
		,'QteSubscriber_13_18'
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_13_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		15
		,'QteSubscriber_19_24'
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_19_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		16
		,'QteSubscriber_25_36'
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_25_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		17
		,'QteSubscriber_37_48'
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_37_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		18
		,'QteSubscriber_49_Plus'
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSubscriber_49_Plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	
	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'


