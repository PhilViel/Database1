/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q13_DEPOT_age
Nom du service		:		psGENE_RapportStatOrg_Q13_DEPOT_age
But					:		Pour le rapport de statistiques orrganisationelles - Q13
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q13_DEPOT_age '2016-05-31', 0
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						2018-09-07					Maxime Martel							JIRA MP-699 Ajout de OpertypeID COU
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q13_DEPOT_age] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)

AS
BEGIN

set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,AgeBenef int
			,QteBenef int
			,TotalDepot float
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

		SELECT 
			c.BeneficiaryID,
			Date1erDepotDansAnnee = min(o.OperDate)
		into #tmpDepot -- drop table #tmpDepot
		FROM Un_Convention C
		JOIN Mo_Human hb on c.BeneficiaryID = hb.HumanID
		JOIN Un_Unit U ON C.ConventionID= U.ConventionID
		JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
		JOIN Un_Oper O ON CT.OperID = O.OperID
		LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
		LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
		WHERE O.OperTypeID IN ('PRD','CPA','CHQ','RDI','COU')
		AND OC1.OperSourceID IS NULL
		AND OC2.OperID IS NULL
		and (ct.Cotisation + ct.Fee) > 0
		and YEAR(o.OperDate) = year(@DateTo)
		--and c.PlanID <> 4
		GROUP by
			--c.SubscriberID,
			c.BeneficiaryID
			--hb.BirthDate
		ORDER by
			--dbo.fn_Mo_Age(hb.BirthDate,min(o.OperDate)),
			--c.SubscriberID,
			c.BeneficiaryID

	
		insert into #Result
			select 

				DateFrom = @DateFrom
				,DateTo = @DateTo
				,AgeBenef = case when AgeBenef < 17 then AgeBenef else 17 end
				,QteBenef = count(distinct BeneficiaryID)
				,TotalDepot = sum(SoustotalSoldeDeposeACetteDate)

			FROM (

				SELECT 
					c.BeneficiaryID,
					--c.ConventionNo,
					AgeBenef = dbo.fn_Mo_Age(hb.BirthDate,Date1erDepotDansAnnee),
					Date1erDepotDansAnnee,
					TotalSoldeDeposeACetteDate = sum(ct.Cotisation + ct.Fee + ct.BenefInsur + ct.SubscInsur + ct.TaxOnInsur)
					,SoustotalSoldeDeposeACetteDate = sum(ct.Cotisation + ct.Fee)
				--into #tmpDepot
				FROM Un_Convention C
				join #tmpDepot d on c.BeneficiaryID = d.BeneficiaryID
				JOIN Mo_Human hb on c.BeneficiaryID = hb.HumanID
				JOIN Un_Unit U ON C.ConventionID= U.ConventionID
				JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
				JOIN Un_Oper O ON CT.OperID = O.OperID
				WHERE o.OperDate BETWEEN @DateFrom and @DateTo
				and O.OperTypeID IN ('PRD','CPA','CHQ','RDI','NSF','COU')
				--and c.PlanID <> 4
				GROUP by
					c.SubscriberID,
					c.BeneficiaryID,
					hb.BirthDate,Date1erDepotDansAnnee

			--GROUP by AgeBenef
			--order by AgeBenef
				
			) V
			group by
				case when AgeBenef < 17 then AgeBenef else 17 end


		drop table #tmpDepot

		set @i = @i + 1
	end	 --while @i

	
	select * from #Result ORDER BY DateTo,AgeBenef



END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'