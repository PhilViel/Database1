
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q9_ADM_PAE
Nom du service		:		psGENE_RapportStatOrg_Q9_ADM_PAE
But					:		Pour le rapport de statistiques orrganisationelles - Q9
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						 exec psGENE_RapportStatOrg_Q9_ADM_PAE '2016-05-31', 1 
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q9_ADM_PAE] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,QteBenef_ADM1 INT	
			,QteBenef_ADM2 INT
			,QteBenef_ADM3 INT
			,QteBenef_PAD1 INT
			,QteBenef_PAD2 INT
			,QteBenef_PAD3 INT
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
			,QteBenef_ADM1 = COUNT(DISTINCT BeneficiaryID_ADM1)	
			,QteBenef_ADM2 = COUNT(DISTINCT BeneficiaryID_ADM2)	
			,QteBenef_ADM3 = COUNT(DISTINCT BeneficiaryID_ADM3)	
			,QteBenef_PAD1 = COUNT(DISTINCT BeneficiaryID_PAD1)	
			,QteBenef_PAD2 = COUNT(DISTINCT BeneficiaryID_PAD2)	
			,QteBenef_PAD3 = COUNT(DISTINCT BeneficiaryID_PAD3)	
		FROM (


			select DISTINCT
				BeneficiaryID_ADM1 = c.BeneficiaryID
				,BeneficiaryID_ADM2 = NULL
				,BeneficiaryID_ADM3 = NULL

				,BeneficiaryID_PAD1 = NULL
				,BeneficiaryID_PAD2 = NULL
				,BeneficiaryID_PAD3 = NULL

			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
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
						where startDate < DATEADD(d,1 ,@DateFrom)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			left join Un_Scholarship s on c.ConventionID = s.ConventionID and s.ScholarshipNo = 1
			left join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			left join Un_Oper o on sp.OperID = o.OperID and o.OperDate <= @DateFrom
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			where c.YearQualif <> 0
				and c.PlanID <> 4
				and cast(cast(c.YearQualif as VARCHAR(4)) + '-07-01' as date) <= @DateFrom
				AND rr.vcCode_Regroupement in ( 'REF','UNI')
				AND oc1.OperSourceID is NULL
				AND oc2.OperID is null
				AND o.OperID is null -- le PAe n'est pas fait à cette date

			UNION ALL

			select DISTINCT
				BeneficiaryID_ADM1 = null
				,BeneficiaryID_ADM2 = c.BeneficiaryID
				,BeneficiaryID_ADM3 = NULL

				,BeneficiaryID_PAD1 = NULL
				,BeneficiaryID_PAD2 = NULL
				,BeneficiaryID_PAD3 = NULL

			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
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
						where startDate < DATEADD(d,1 ,@DateFrom)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			join Un_Scholarship s on c.ConventionID = s.ConventionID and s.ScholarshipNo = 1
			join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			join Un_Oper o on sp.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			left JOIN (
				select DISTINCT s.ConventionID
				from Un_Scholarship s
				join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
				join Un_Oper o on sp.OperID = o.OperID 
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
				where s.ScholarshipNo = 2
			
					and o.OperDate <= @DateFrom
			
					AND oc1.OperSourceID is NULL
					AND oc2.OperID is null
				)s2 on s2.ConventionID = c.ConventionID

			where c.YearQualif <> 0
				and c.PlanID <> 4
				and o.OperDate <= @DateFrom
				AND rr.vcCode_Regroupement in ( 'REF','UNI')
				AND oc1.OperSourceID is NULL
				AND oc2.OperID is null
				and s2.ConventionID is null -- n'a pas eu son PAE 2

	
			UNION ALL

			select DISTINCT
				BeneficiaryID_ADM1 = NULL
				,BeneficiaryID_ADM2 = NULL
				,BeneficiaryID_ADM3 = c.BeneficiaryID

				,BeneficiaryID_PAD1 = NULL
				,BeneficiaryID_PAD2 = NULL
				,BeneficiaryID_PAD3 = NULL

			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
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
						where startDate < DATEADD(d,1 ,@DateFrom)
						group by conventionid
						) ccs on ccs.conventionid = cs.conventionid 
							and ccs.startdate = cs.startdate 
							and cs.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
				) css on C.conventionid = css.conventionid
			join Un_Scholarship s on c.ConventionID = s.ConventionID and s.ScholarshipNo = 2
			join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			join Un_Oper o on sp.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			left JOIN (
				select DISTINCT s.ConventionID
				from Un_Scholarship s
				join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
				join Un_Oper o on sp.OperID = o.OperID 
				left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
				left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
				where s.ScholarshipNo = 3
			
					and o.OperDate <= @DateFrom
			
					AND oc1.OperSourceID is NULL
					AND oc2.OperID is null
				)s3 on s3.ConventionID = c.ConventionID

			where c.YearQualif <> 0
				and c.PlanID <> 4
				and o.OperDate <= @DateFrom
				AND rr.vcCode_Regroupement in ( 'REF','UNI')
				AND oc1.OperSourceID is NULL
				AND oc2.OperID is null
				and s3.ConventionID is null -- n'a pas eu son PAE 2

			UNION ALL

			select DISTINCT
				BeneficiaryID_ADM1 = NULL
				,BeneficiaryID_ADM2 = NULL
				,BeneficiaryID_ADM3 = NULL

				,BeneficiaryID_PAD1 = c.BeneficiaryID
				,BeneficiaryID_PAD2 = NULL
				,BeneficiaryID_PAD3 = NULL
			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			left join Un_Scholarship s on c.ConventionID = s.ConventionID
			left join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			left join Un_Oper o on sp.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			where rr.vcCode_Regroupement in ( 'REF','UNI')
				AND S.ScholarshipNo = 1
				and o.OperDate BETWEEN @DateFrom and @DateTo
				and oc1.OperSourceID is NULL
				and oc2.OperID is null

			UNION ALL

			select DISTINCT
				BeneficiaryID_ADM1 = NULL
				,BeneficiaryID_ADM2 = NULL
				,BeneficiaryID_ADM3 = NULL

				,BeneficiaryID_PAD1 = NULL
				,BeneficiaryID_PAD2 = c.BeneficiaryID
				,BeneficiaryID_PAD3 = NULL
			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			left join Un_Scholarship s on c.ConventionID = s.ConventionID
			left join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			left join Un_Oper o on sp.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			where rr.vcCode_Regroupement in ( 'REF','UNI')
				AND S.ScholarshipNo = 2
				and o.OperDate BETWEEN @DateFrom and @DateTo
				and oc1.OperSourceID is NULL
				and oc2.OperID is null

			UNION ALL

			select DISTINCT
				BeneficiaryID_ADM1 = NULL
				,BeneficiaryID_ADM2 = NULL
				,BeneficiaryID_ADM3 = NULL

				,BeneficiaryID_PAD1 = NULL
				,BeneficiaryID_PAD2 = NULL
				,BeneficiaryID_PAD3 = c.BeneficiaryID
			from Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
			left join Un_Scholarship s on c.ConventionID = s.ConventionID
			left join Un_ScholarshipPmt sp on s.ScholarshipID = sp.ScholarshipID
			left join Un_Oper o on sp.OperID = o.OperID 
			left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
			left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
			where  rr.vcCode_Regroupement in ( 'REF','UNI')
				AND S.ScholarshipNo = 3
				and o.OperDate BETWEEN @DateFrom and @DateTo
				and oc1.OperSourceID is NULL
				and oc2.OperID is null
		) V

		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result --ORDER BY DateTo,AgeBenef

	/*
			,QteBenef_ADM1 INT	
			,QteBenef_ADM2 INT
			,QteBenef_ADM3 INT
			,QteBenef_PAD1 INT
			,QteBenef_PAD2 INT
			,QteBenef_PAD3 INT
	*/

	INSERT into #Final values (
		1
		,'QteBenef_ADM1'
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_ADM1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		2
		,'QteBenef_ADM2'
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_ADM2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		3
		,'QteBenef_ADM3'
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_ADM3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		4
		,'QteBenef_PAD1'
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_PAD1 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		5
		,'QteBenef_PAD2'
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_PAD2 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)
	INSERT into #Final values (
		6
		,'QteBenef_PAD3'
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteBenef_PAD3 from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)	
	select * from #Final order by sort

END

