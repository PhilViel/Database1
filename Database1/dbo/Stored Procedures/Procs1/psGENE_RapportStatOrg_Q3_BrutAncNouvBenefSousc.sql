
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q3_BrutAncNouvBenefSousc
Nom du service		:		psGENE_RapportStatOrg_Q3_BrutAncNouvBenefSousc
But					:		Pour le rapport de statistiques orrganisationelles - Q3
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q3_BrutAncNouvBenefSousc '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q3_BrutAncNouvBenefSousc] (
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
			,QteAncienBenef  int
			,BrutAncienBenef  float
			,QteNouvBenef  int
			,BrutNouvBenef  float
			,QteAncienSousc  int
			,BrutAncienSousc  float
			,QteNouvSousc  int
			,BrutNouvSousc  float
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

		delete from #GrossANDNetUnits
			

		set @DateFrom = cast(year(@EnDateDu)-@i as VARCHAR(4))+ '-01-01'
		set @DateTo = cast(year(@EnDateDu)-@i as VARCHAR(4)) + '-12-31'

		if @i = 0
			set @DateTo  = @EnDateDu

		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @DateFrom, @DateTo, 0, 1
		DELETE FROM #GrossANDNetUnits WHERE BRUT <= 0

		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,QteAncienBenef = count(DISTINCT QteAncienBenef )
			,BrutAncienBenef = sum(BrutAncienBenef)
			,QteNouvBenef = count(DISTINCT QteNouvBenef )
			,BrutNouvBenef = sum(BrutNouvBenef)
			,QteAncienSousc = count(DISTINCT QteAncienSousc )
			,BrutAncienSousc = sum(BrutAncienSousc)
			,QteNouvSousc = count(DISTINCT QteNouvSousc )
			,BrutNouvSousc = sum(BrutNouvSousc)

		from (

			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,gnu.unitID
				,QteNouvBenef = case WHEN b1.BeneficiaryID is null then bh.iID_Nouveau_Beneficiaire else null end
				,BrutNouvBenef = sum(case when b1.BeneficiaryID is null then  brut else 0 end )
				,QteAncienBenef = case WHEN b1.BeneficiaryID is not null then bh.iID_Nouveau_Beneficiaire else null end
				,BrutAncienBenef = sum(case when b1.BeneficiaryID is not null then  brut else 0 end )
				,QteNouvSousc = case WHEN s1.SubscriberID is null then c.SubscriberID else null end
				,BrutNouvSousc = sum(case when s1.SubscriberID is null then  brut else 0 end )
				,QteAncienSousc = case WHEN s1.SubscriberID is not null then c.SubscriberID else null end
				,BrutAncienSousc = sum(case when s1.SubscriberID is not null then  brut else 0 end )

			from #GrossANDNetUnits gnu
			join Un_Unit u on gnu.UnitID = u.UnitID
			join Un_Convention c on u.ConventionID= c.ConventionID

			left join (
						select cbAvant.iID_Convention, cbAvant.iID_Nouveau_Beneficiaire, DateDu = cbAvant.dtDate_Changement_Beneficiaire, DateAu = isnull(CBapres.dtDate_Changement_Beneficiaire,'9999-12-31')
						from (
							select cb.iID_Convention, cb.iID_Changement_Beneficiaire, MIN_iID_Changement_Beneficiaire = min(CB2.iID_Changement_Beneficiaire)
							from tblCONV_ChangementsBeneficiaire CB
							left join tblCONV_ChangementsBeneficiaire CB2 on cb.iID_Convention = CB2.iID_Convention and CB2.iID_Changement_Beneficiaire > cb.iID_Changement_Beneficiaire
							GROUP by cb.iID_Convention, cb.iID_Changement_Beneficiaire
							)t
						JOIN tblCONV_ChangementsBeneficiaire cbAvant on t.iID_Changement_Beneficiaire = cbAvant.iID_Changement_Beneficiaire
						LEFT JOIN tblCONV_ChangementsBeneficiaire CBapres on t.MIN_iID_Changement_Beneficiaire = CBapres.iID_Changement_Beneficiaire
						--order by cbAvant.iID_Convention
				)bh on bh.iID_Convention = c.ConventionID and u.dtFirstDeposit >= bh.DateDu and u.dtFirstDeposit < bh.DateAu
			left join Mo_Human hb on hb.HumanID = bh.iID_Nouveau_Beneficiaire

			LEFT JOIN (
				select DISTINCT c.BeneficiaryID
				FROM Un_Convention c
				--join Un_Unit u ON c.ConventionID = u.ConventionID
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
				--where u.dtFirstDeposit < @DateFrom
				)b1 ON  b1.BeneficiaryID = bh.iID_Nouveau_Beneficiaire 

			LEFT JOIN (
				select DISTINCT c.SubscriberID
				FROM Un_Convention c
				--join Un_Unit u ON c.ConventionID = u.ConventionID
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
				--where u.dtFirstDeposit < @DateFrom
				)s1 ON c.SubscriberID = s1.SubscriberID
			--where gnu.brut > 0
			--and c.PlanID <> 4
			GROUP by gnu.unitID,b1.BeneficiaryID,c.BeneficiaryID,s1.SubscriberID , c.SubscriberID,bh.iID_Nouveau_Beneficiaire

			)v



		set @i = @i + 1
	end	 --while @i

	
	--select * from #Result
	

	INSERT into #Final values (
		1
		,'QteAncienBenef'
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	INSERT into #Final values (
		2
		,'BrutAncienBenef'
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select BrutAncienBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)


	INSERT into #Final values (
		3
		,'QteNouvBenef'
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	
	INSERT into #Final values (
		4
		,'BrutNouvBenef'
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select BrutNouvBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)



	INSERT into #Final values (
		5
		,'QteAncienSousc'
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		6
		,'BrutAncienSousc'
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select BrutAncienSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)



	INSERT into #Final values (
		7
		,'QteNouvSousc'
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select QteNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)

	INSERT into #Final values (
		8
		,'BrutNouvSousc'
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select BrutNouvSousc from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)
		)





	SELECT * from #Final order by sort
	
	drop table #GrossANDNetUnits
	drop table #Result

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'