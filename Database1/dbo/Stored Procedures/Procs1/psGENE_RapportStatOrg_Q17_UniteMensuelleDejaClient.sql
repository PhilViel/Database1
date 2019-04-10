
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q17_UniteMensuelleDejaClient
Nom du service		:		psGENE_RapportStatOrg_Q17_UniteMensuelleDejaClient
But					:		Pour le rapport de statistiques orrganisationelles - Q17 (JIRA TI-6275)
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q17_UniteMensuelleDejaClient '2016-12-31', 5
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2017-01-10					Donald Huppé							Création du Service
						
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q17_UniteMensuelleDejaClient] (
	@EnDateDu datetime
	,@QtePeriodePrecedent int = 0
	)


AS
BEGIN

	set @QtePeriodePrecedent = case when @QtePeriodePrecedent > 5 then 5 ELSE @QtePeriodePrecedent end


/*
i) Nombre d'unités avec premier dépôt dans la période, souscrite pour une combinaison de souscripteur/bénéficiaire 
qui avait déjà au moins un groupe d'unités actif juste avant dans un plan chez nous (i.e. que le souscripteur avait au moins un groupe d'unités actif pour ce bénéficiaire) 
et dont le nouveau groupe d'unité est en option MENSUELLE
 ii) montant souscrit pour ces groupes d'unités
 */

	create table #Result (
			DateFrom datetime
			,DateTo datetime
			,UnitésSouscrites float
			,MontantSouscrit float
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

	declare	 @DateFrom datetime
	declare	 @DateTo datetime
	declare @i int = 0

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
					,UnitésSouscrites = SUM(U.UnitQty +isnull(qtyreduct,0))
					,MontantSouscrit = SUM	(
											CONVERT(money,
												(ROUND( (U.UnitQty +isnull(qtyreduct,0)) * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment
												)
											)
				FROM 
					dbo.Un_Convention C
					JOIN (
						-- LES SOUSC ET BENEF DÉJÀ CLIENT AU DEBUT DE LA PÉRIODE
						SELECT DISTINCT C1.SubscriberID, C1.BeneficiaryID
						FROM Un_Convention C1
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
							) css on C1.conventionid = css.conventionid
						)DEJA ON DEJA.SubscriberID = C.SubscriberID AND DEJA.BeneficiaryID = C.BeneficiaryID
					JOIN un_unit U ON U.ConventionID = C.ConventionID
					LEFT join (select qtyreduct = sum(unitqty), unitid from un_unitreduction group by unitid) r on u.unitid = r.unitid
					JOIN dbo.Un_Modal M ON M.ModalID = U.ModalID
					JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
				WHERE 
					u.dtFirstDeposit BETWEEN @DateFrom AND @DateTo
					AND M.PmtByYearID = 12 -- MENSUEL

		set @i = @i + 1
	end	 --while

	INSERT into #Final values (
		1
		,'Unités Souscrites'
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select UnitésSouscrites from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)

	)


	INSERT into #Final values (
		2
		,'Montant Souscrit'
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 0)
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 1)
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 2)
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 3)
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 4)
		,(select MontantSouscrit from #Result where year(DateFrom) = yeaR(@EnDateDu) - 5)

	)

	SELECT * from #Final


	drop table #Result

END