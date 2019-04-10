
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef_RES_SplitParMois
Nom du service		:		psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef_RES_SplitParMois
But					:		Pour le rapport de statistiques orrganisationelles - Q% : Donner les RES de souscripteur par qté de mois depuis la signature
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef_RES_SplitParMois '2016-12-31', 0 
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2017-05-25					Donald Huppé							Création du Service

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef_RES_SplitParMois] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
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
		v0 float,
		v1 float,
		v2 float,
		v3 float,
		v4 float,
		v5 float,
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
				Du = @DateFrom
				,Au = @DateTo
				,QteSousc_0_1mois = COUNT (DISTINCT QteSousc_0_1mois )
				,QteSousc_1_2mois = COUNT (DISTINCT QteSousc_1_2mois )
				,QteSousc_2_3mois = COUNT (DISTINCT QteSousc_2_3mois )
				,QteSousc_3_4mois = COUNT (DISTINCT QteSousc_3_4mois )
				,QteSousc_4_5mois = COUNT (DISTINCT QteSousc_4_5mois )
				,QteSousc_5_6mois = COUNT (DISTINCT QteSousc_5_6mois )
				,QteSousc_6_7mois = COUNT (DISTINCT QteSousc_6_7mois )
				,QteSousc_7_8mois = COUNT (DISTINCT QteSousc_7_8mois )
				,QteSousc_8_9mois = COUNT (DISTINCT QteSousc_8_9mois )
				,QteSousc_9_10mois = COUNT (DISTINCT QteSousc_9_10mois )
				,QteSousc_10_11mois = COUNT (DISTINCT QteSousc_10_11mois )
				,QteSousc_11_12mois = COUNT (DISTINCT QteSousc_11_12mois )
				,QteSousc_12_18mois = COUNT (DISTINCT QteSousc_12_18mois )
				,QteSousc_18_24mois = COUNT (DISTINCT QteSousc_18_24mois )
				,QteSousc_24_36mois = COUNT (DISTINCT QteSousc_24_36mois )
				,QteSousc_36_48mois = COUNT (DISTINCT QteSousc_36_48mois )
				,QteSousc_48_Plus = COUNT (DISTINCT QteSousc_48_Plus )

		from (

			SELECT 
				c.SubscriberID
				,DateResil 
				,NbGrUnit = COUNT(*)
				,Delai = DATEDIFF(DAY,Resil.DateSignature,Resil.DateResil)
				,NbBenef
				,QteDateSignature
				,QteSousc_0_1mois = case when Resil.DateResil > dateadd(MONTH,0, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,1, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_1_2mois = case when Resil.DateResil > dateadd(MONTH,1, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,2, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_2_3mois = case when Resil.DateResil > dateadd(MONTH,2, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,3, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_3_4mois = case when Resil.DateResil > dateadd(MONTH,3, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,4, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_4_5mois = case when Resil.DateResil > dateadd(MONTH,4, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,5, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_5_6mois = case when Resil.DateResil > dateadd(MONTH,5, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,6, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_6_7mois = case when Resil.DateResil > dateadd(MONTH,6, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,7, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_7_8mois = case when Resil.DateResil > dateadd(MONTH,7, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,8, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_8_9mois = case when Resil.DateResil > dateadd(MONTH,8, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,9, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_9_10mois = case when Resil.DateResil > dateadd(MONTH,9, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,10, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_10_11mois = case when Resil.DateResil > dateadd(MONTH,10, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,11, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_11_12mois = case when Resil.DateResil > dateadd(MONTH,11, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,12, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_12_18mois = case when Resil.DateResil > dateadd(MONTH,12, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,18, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_18_24mois = case when Resil.DateResil > dateadd(MONTH,18, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,24, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_24_36mois = case when Resil.DateResil > dateadd(MONTH,24, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,36, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_36_48mois = case when Resil.DateResil > dateadd(MONTH,36, Resil.DateSignature) and Resil.DateResil <= dateadd(MONTH,48, Resil.DateSignature) then c.SubscriberID else NULL end
				,QteSousc_48_Plus = case when Resil.DateResil > dateadd(MONTH,48, Resil.DateSignature) then c.SubscriberID else NULL end

			FROM un_unit U
			JOIN Un_Convention c on u.ConventionID = c.ConventionID
			JOIN (
				select cn.SubscriberID, nbResil = count(*), DateResil = MAX(terminateddate), DateSignature = MAX(UN.SignatureDate), NbBenef = Count(DISTINCT cn.BeneficiaryID), QteDateSignature = count(DISTINCT un.SignatureDate)
				from un_unit un
				join Un_Convention cn on un.ConventionID = cn.ConventionID
				where terminateddate is not null
				and cn.PlanID <> 4
				group by cn.SubscriberID
				) Resil on c.SubscriberID = Resil.SubscriberID
			where c.PlanID <> 4
			GROUP BY c.SubscriberID, Resil.nbResil,Resil.DateResil,DateSignature,NbBenef,QteDateSignature
			HAVING COUNT(*) = Resil.nbResil
			--ORDER by c.SubscriberID DESC
			)v

		where 
			DateResil BETWEEN @DateFrom and @DateTo


			-- il a un contrat actif avant la période
			and v.SubscriberID in (
				select DISTINCT c.SubscriberID
				from 
					Un_Convention c
					-- la conv est active ;a la fin de l'ann précédente
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
				)

			-- n'a pas de contrat REE à la fin
			and SubscriberID not in (
				select DISTINCT c.SubscriberID
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
								where startDate < DATEADD(d,1 ,@DateTo)
								group by conventionid
								) ccs on ccs.conventionid = cs.conventionid 
									and ccs.startdate = cs.startdate 
									and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
						) css on C.conventionid = css.conventionid


				)




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
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'Mois_2'
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		3
		,'Mois_3'
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		4
		,'Mois_4'
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_4 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'Mois_5'
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_5 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		6
		,'Mois_6'
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_6 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		7
		,'Mois_7'
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_7 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		8
		,'Mois_8'
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_8 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		9
		,'Mois_9'
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_9 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		10
		,'Mois_10'
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_10 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		11
		,'Mois_11'
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_11 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		12
		,'Mois_12'
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_12 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		13
		,'Mois_12_18'
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_12_18 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		14
		,'Mois_18_24'
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_18_24 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		15
		,'Mois_24_36'
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_24_36 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		16
		,'Mois_36_48'
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_36_48 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		17
		,'Mois_48_plus'
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_Mois_48_plus from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	select * from #Final order by sort

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'