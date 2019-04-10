
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef
Nom du service		:		psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef
But					:		Pour le rapport de statistiques orrganisationelles - Q5
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef '2016-05-31',1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q5_Flow_Sousc_Benef] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteBenefActifAuDebut INT
			,QteBenefPeriode INT
			,QteBenefResil INT
			,QteBenefFRM_PAE INT
			,QteBenef_FIN INT

			,QteSouscActifAuDebut INT
			,QteSouscPeriode INT
			,QteSouscResil INT
			,QteSouscFRM_PAE INT
			,QteSousc_FIN INT
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
				DateFrom
				,DateTo

				,QteBenefActifAuDebut = SUM(QteBenefActifAuDebut)
				,QteBenefPeriode = SUM(QteBenefPeriode)
				,QteBenefResil =  SUM(QteBenefResil)
				,QteBenefFRM_PAE =  SUM(QteBenefFRM_PAE)
				,QteBenef_FIN =  SUM(QteBenef_FIN)

				,QteSouscActifAuDebut =  SUM(QteSouscActifAuDebut)
				,QteSouscPeriode =  SUM(QteSouscPeriode)
				,QteSouscResil =  SUM(QteSouscResil)
				,QteSouscFRM_PAE =  SUM(QteSouscFRM_PAE)
				,QteSousc_FIN =  SUM(QteSousc_FIN)
		FROM (

	
				select 
					DateFrom = @DateFrom
					,DateTo = @DateTo
					,QteBenefActifAuDebut = sum(qb1)
					,QteBenefPeriode = sum(qb2)
					,QteBenefResil = sum(qb3)
					,QteBenefFRM_PAE = sum(qb4)
					,QteBenef_FIN = sum(qb1) + sum(qb2) - sum(qb3) - sum(qb4)

					,QteSouscActifAuDebut = 0
					,QteSouscPeriode = 0
					,QteSouscResil = 0
					,QteSouscFRM_PAE = 0
					,QteSousc_FIN = 0

				from (

					select 
							qb4 = COUNT( DISTINCT c.BeneficiaryID)
							,qb3 = 0
							,qb2 = 0
							,qb1 = 0
					from Un_Convention c
					join Un_Scholarship s on c.ConventionID = s.ConventionID and s.ScholarshipStatusID = 'PAD'
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
								--where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
								group by conventionid
								) ccs on ccs.conventionid = cs.conventionid 
									and ccs.startdate = cs.startdate 
									and cs.ConventionStateID in ('FRM') -- je veux les convention qui ont cet état
						) css on C.conventionid = css.conventionid
					where css.startdate BETWEEN @DateFrom and @DateTo
					and c.BeneficiaryID NOT in ( -- n'a plus de conv ouverte à la fin
							select  DISTINCT c.BeneficiaryID
							from Un_Convention c
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
	
					UNION all

					select 
							qb4 = 0
							,qb3 = count(DISTINCT c.BeneficiaryID)
							,qb2 = 0
							,qb1 = 0
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

						-- il ya eu une résil ou OUT dans l'année dans la conv
						join Un_Unit u on c.ConventionID = u.ConventionID and year(u.TerminatedDate) = year(@DateTo)
						left join (
							select u.ConventionID, UnitReductionReason = max(urr.UnitReductionReason)
							from Un_UnitReduction ur
							join Un_Unit u on ur.UnitID = u.UnitID
							join Un_UnitReductionReason urr on ur.UnitReductionReasonID = urr.UnitReductionReasonID
							group by u.ConventionID
							)urs on urs.ConventionID = u.ConventionID
						-- la conv est fermée en fin d'année
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
										and cs.ConventionStateID = 'FRM' -- je veux les convention qui ont cet état
							) cssFIN on C.conventionid = cssFIN.conventionid

						-- le benef n'a plus de conv active en fin d'année
						where c.BeneficiaryID not in (


								select DISTINCT c.BeneficiaryID
								from 
									Un_Convention c
									-- la conv est signée dans l'année et a été dans l'état TRA ou REE dans l'année
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

					UNION ALL

					select 

							qb4 = 0
							,qb3 = 0
							,qb2 = COUNT( DISTINCT c.BeneficiaryID)
							,qb1 = 0

					from Un_Convention c
					JOIN un_unit u on c.ConventionID = u.ConventionID
					where u.dtFirstDeposit BETWEEN @DateFrom and @DateTo
					and c.BeneficiaryID not in ( -- N'était pas actif au début
							select  DISTINCT c.BeneficiaryID
							from Un_Convention c
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
										where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C.conventionid = css.conventionid
							)
		
					UNION all

					select 
		
							qb4 = 0
							,qb3 = 0
							,qb2 = 0
							,qb1 = COUNT( DISTINCT c.BeneficiaryID)

					from Un_Convention c
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
								where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
								group by conventionid
								) ccs on ccs.conventionid = cs.conventionid 
									and ccs.startdate = cs.startdate 
									and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
						) css on C.conventionid = css.conventionid
					)v


				UNION ALL

				select 
					DateFrom = @DateFrom
					,DateTo = @DateTo

					,QteBenefActifAuDebut = 0
					,QteBenefPeriode =0
					,QteBenefResil = 0
					,QteBenefFRM_PAE = 0
					,QteBenef_FIN = 0

					,QteSouscActifAuDebut = sum(qs1)
					,QteSouscPeriode = sum(qs2)
					,QteSouscResil = sum(qs3)
					,QteSouscFRM_PAE = sum(qs4)
					,QteSousc_FIN = sum(qs1) + sum(qs2) - sum(qs3) - sum(qs4)
				from (

					select 
							qs4 = COUNT( DISTINCT c.SubscriberID)
							,qs3 = 0
							,qs2 = 0
							,qs1 = 0
					from Un_Convention c
					join Un_Scholarship s on c.ConventionID = s.ConventionID and s.ScholarshipStatusID = 'PAD'
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
								--where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
								group by conventionid
								) ccs on ccs.conventionid = cs.conventionid 
									and ccs.startdate = cs.startdate 
									and cs.ConventionStateID in ('FRM') -- je veux les convention qui ont cet état
						) css on C.conventionid = css.conventionid
					where css.startdate BETWEEN @DateFrom and @DateTo
					and c.SubscriberID NOT in ( -- n'a plus de conv ouverte à la fin
							select  DISTINCT c.SubscriberID
							from Un_Convention c
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
	
					UNION all

					select 
							qs4 = 0
							,qs3 = count(DISTINCT c.SubscriberID)
							,qs2 = 0
							,qs1 = 0
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

						-- il ya eu une résil ou OUT dans l'année dans la conv
						join Un_Unit u on c.ConventionID = u.ConventionID and year(u.TerminatedDate) = year(@DateTo)
						left join (
							select u.ConventionID, UnitReductionReason = max(urr.UnitReductionReason)
							from Un_UnitReduction ur
							join Un_Unit u on ur.UnitID = u.UnitID
							join Un_UnitReductionReason urr on ur.UnitReductionReasonID = urr.UnitReductionReasonID
							group by u.ConventionID
							)urs on urs.ConventionID = u.ConventionID
						-- la conv est fermée en fin d'année
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
										and cs.ConventionStateID = 'FRM' -- je veux les convention qui ont cet état
							) cssFIN on C.conventionid = cssFIN.conventionid

						-- le sousc n'a plus de conv active en fin d'année
						where c.SubscriberID not in (


								select DISTINCT c.SubscriberID
								from 
									Un_Convention c
									-- la conv est signée dans l'année et a été dans l'état TRA ou REE dans l'année
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

					UNION ALL

					select 

							qs4 = 0
							,qs3 = 0
							,qs2 = COUNT( DISTINCT c.SubscriberID)
							,qs1 = 0

					from Un_Convention c
					JOIN un_unit u on c.ConventionID = u.ConventionID
					where u.dtFirstDeposit BETWEEN @DateFrom and @DateTo
					and c.SubscriberID not in ( -- N'était pas actif au début
							select  DISTINCT c.SubscriberID
							from Un_Convention c
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
										where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
										group by conventionid
										) ccs on ccs.conventionid = cs.conventionid 
											and ccs.startdate = cs.startdate 
											and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
								) css on C.conventionid = css.conventionid
							)
		
					UNION all

					select 
		
							qs4 = 0
							,qs3 = 0
							,qs2 = 0
							,qs1 = COUNT( DISTINCT c.SubscriberID)

					from Un_Convention c
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
								where startDate < DATEADD(d,1 ,DATEADD(d,-1 ,@DateFrom))
								group by conventionid
								) ccs on ccs.conventionid = cs.conventionid 
									and ccs.startdate = cs.startdate 
									and cs.ConventionStateID in ('REE','TRA') -- je veux les convention qui ont cet état
						) css on C.conventionid = css.conventionid
					)v
			)T
		GROUP BY DateFrom	,DateTo

		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result ORDER BY DateTo

/*
			,QteSouscActifAuDebut INT
			,QteSouscPeriode INT
			,QteSouscResil INT
			,QteSouscFRM_PAE INT
			,QteSousc_FIN INT

			,QteBenefActifAuDebut INT
			,QteBenefPeriode INT
			,QteBenefResil INT
			,QteBenefFRM_PAE INT
			,QteBenef_FIN INT


			*/
	INSERT into #Final values (
		1
		,'QteSouscActifAuDebut'
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSouscActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		2
		,'QteSouscPeriode'
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSouscPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		3
		,'QteSouscResil'
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSouscResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		4
		,'QteSouscFRM_PAE'
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSouscFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'QteSousc_FIN'
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteSousc_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		6
		,'QteBenefActifAuDebut'
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenefActifAuDebut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		7
		,'QteBenefPeriode'
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenefPeriode from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		8
		,'QteBenefResil'
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenefResil from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		9
		,'QteBenefFRM_PAE'
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenefFRM_PAE from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		10
		,'QteBenef_FIN'
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_FIN from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	SELECT * FROM #Final

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'