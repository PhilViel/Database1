
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q2_UniteBruteParAge
Nom du service		:		psGENE_RapportStatOrg_Q2_UniteBruteParAge
But					:		Pour le rapport de statistiques orrganisationelles - Q2
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q2_UniteBruteParAge '2016-05-31',0
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q2_UniteBruteParAge] (
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
			,Age int
			,QteBenef int
			,Brut float
			)

	create table #Final (
		Sort int,
		Quoi varchar(100),
		v01 int,
		v02 float,
		v11 int,
		v12 float,
		v21 int,
		v22 float,
		v31 int,
		v32 float,
		v41 int,
		v42 float,
		v51 int,
		v52 float
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


		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,Age = case when age < 17 then age else 17 END
			,QteBenef = count(DISTINCT v.BeneficiaryID)
			,Brut = round(sum(brut) ,3)
		from (
			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,Age = dbo.fn_Mo_Age(isnull(hb.BirthDate,hbc.BirthDate),u.SignatureDate)
				,BeneficiaryID = hb.HumanID
				,Brut = sum(brut)
		

			from #GrossANDNetUnits gnu
			join Un_Unit u on gnu.UnitID = u.UnitID
			join Un_Convention c on u.ConventionID= c.ConventionID
			join Mo_Human hbc on c.BeneficiaryID = hbc.HumanID
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

			group by dbo.fn_Mo_Age(isnull(hb.BirthDate,hbc.BirthDate),u.SignatureDate),hb.HumanID
			HAVING sum(brut) <> 0
			)v
		group by case when age < 17 then age else 17 END


		set @i = @i + 1
	end	 --while @i

	

	--select * from #Result


	while @j <= 17
	begin 	

		INSERT into #Final values (
			@j
			,case when @j < 17 then cast(@j as VARCHAR) else '17+' end
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0 and age = @j)
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1 and age = @j)
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2 and age = @j)
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3 and age = @j)
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4 and age = @j)
			
			,(select QteBenef from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 and age = @j)
			,(select brut from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5 and age = @j)

		)
		set @j = @j + 1
	end --while @j 




	SELECT * from #Final order by sort

	drop table #GrossANDNetUnits
	drop table #Result

END

