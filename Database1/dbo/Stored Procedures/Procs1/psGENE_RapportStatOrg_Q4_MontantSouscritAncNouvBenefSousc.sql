
/****************************************************************************************************
Code de service		:		psGENE_RapportStatOrg_Q4_MontantSouscritAncNouvBenefSousc
Nom du service		:		psGENE_RapportStatOrg_Q4_MontantSouscritAncNouvBenefSousc
But					:		Pour le rapport de statistiques orrganisationelles - Q4
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						N/A

Exemple d'appel:
						exec psGENE_RapportStatOrg_Q4_MontantSouscritAncNouvBenefSousc '2016-05-31', 1
                

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					-----------------------------


Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2016-06-14					Donald Huppé							Création du Service
						
 ****************************************************************************************************/


CREATE PROCEDURE [dbo].[psGENE_RapportStatOrg_Q4_MontantSouscritAncNouvBenefSousc] (
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
			,AgeBenef INT
			,QteNouvBenef INT
			,QteAncienBenef INT
			,MntSouscritNouvBenef FLOAT
			,MntSouscritAncienBenef FLOAT
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


		--print	'DateFrom = ' + cast( @DateFrom as varchar(30))
		--PRINT	'DateTo = ' + cast( @DateTo as varchar(30))

		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @DateFrom, @DateTo, 0, 1
		DELETE FROM #GrossANDNetUnits WHERE BRUT <= 0

		insert into #Result
		SELECT 
			DateFrom = @DateFrom
			,DateTo = @DateTo
			,AgeBenef = case when AgeBenef < 17 then AgeBenef else 17 end
			,QteNouvBenef = COUNT(DISTINCT QteNouvBenef )
			,QteAncienBenef = COUNT(DISTINCT QteAncienBenef )
			,MntSouscritNouvBenef = sum(MntSouscritNouvBenef )
			,MntSouscritAncienBenef = sum(MntSouscritAncienBenef )

		from (
			

			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,gnu.unitID
				,AgeBenef = dbo.fn_Mo_Age(isnull(hb.BirthDate,hbc.BirthDate),u.dtFirstDeposit)
				,QteNouvBenef = case WHEN b1.BeneficiaryID is null then c.BeneficiaryID else null end
				,MntSouscritNouvBenef = sum(case when b1.BeneficiaryID is null then  (ROUND( brut * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment else 0 end )
				,QteAncienBenef = case WHEN b1.BeneficiaryID is not null then c.BeneficiaryID else null end
				,MntSouscritAncienBenef = sum(case when b1.BeneficiaryID is not null then  (ROUND( brut * M.PmtRate,2) * M.PmtQty) + U.SubscribeAmountAjustment else 0 end )


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
				)b1 ON b1.BeneficiaryID = bh.iID_Nouveau_Beneficiaire
			LEFT JOIN (
					select umh.UnitID, ModalID = max(umh.ModalID )
					from Un_UnitModalHistory umh
					join Un_Unit u on umh.UnitID = u.UnitID
					join Un_Convention c on u.ConventionID = c.ConventionID --and c.SubscriberID = 575993 
					where umh.StartDate = (
										select max(StartDate)
										from Un_UnitModalHistory umh2
										where umh.UnitID = umh2.UnitID
										and cast(umh2.StartDate as date) <= cast(u.dtFirstDeposit as date)
										)
					GROUP BY umh.UnitID
					) mh on u.UnitID = mh.UnitID
			left join ( -- les rares cas ou il N'y a pas de modalité en date du 1er depot, on prend la 1ere modalité dans l'historique
					select umh.UnitID, ModalID = min(umh.ModalID )
					from Un_UnitModalHistory umh
					GROUP by umh.UnitID
					)FirstModal on u.UnitID = FirstModal.UnitID
			left join Un_Modal M on m.ModalID = isnull(mh.ModalID,FirstModal.ModalID)
			where c.PlanID <> 4
			GROUP by gnu.unitID,b1.BeneficiaryID,c.BeneficiaryID,hb.BirthDate,u.dtFirstDeposit,hbc.BirthDate

			UNION ALL
			
			SELECT 
				DateFrom = @DateFrom
				,DateTo = @DateTo
				,u.unitID
				,AgeBenef = dbo.fn_Mo_Age(isnull(hb.BirthDate,hbc.BirthDate),u.dtFirstDeposit)
				,QteNouvBenef = case WHEN b1.BeneficiaryID is null then c.BeneficiaryID else null end
				,MntSouscritNouvBenef = sum(case when b1.BeneficiaryID is null then ct.Cotisation else 0 end )
				,QteAncienBenef = case WHEN b1.BeneficiaryID is not null then c.BeneficiaryID else null end
				,MntSouscritAncienBenef = sum(case when b1.BeneficiaryID is not null then ct.Cotisation else 0 end )
			FROM Un_Convention C
			JOIN Un_Unit U ON C.ConventionID= U.ConventionID
			JOIN Un_Cotisation CT ON U.UnitID = CT.UnitID
			JOIN Un_Oper O ON CT.OperID = O.OperID
			LEFT JOIN Un_OperCancelation OC1 ON O.OperID = OC1.OperSourceID
			LEFT JOIN Un_OperCancelation OC2 ON O.OperID = OC2.OperID
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
				)b1 ON b1.BeneficiaryID = bh.iID_Nouveau_Beneficiaire


			WHERE c.PlanID = 4
			--AND C.ConventionNo = ''
			AND OC1.OperSourceID IS NULL
			AND OC2.OperID IS NULL
			and u.dtFirstDeposit BETWEEN @DateFrom AND @DateTo

			GROUP BY u.unitID,hb.BirthDate,hbc.BirthDate,u.dtFirstDeposit
			,b1.BeneficiaryID,c.BeneficiaryID

			)v
		GROUP BY case when AgeBenef < 17 then AgeBenef else 17 end
		ORDER BY 
			DateTo
			,case when AgeBenef < 17 then AgeBenef else 17 end


		set @i = @i + 1
	end	 --while @i

	
	select * from #Result ORDER BY DateTo,AgeBenef

	
	drop table #GrossANDNetUnits
	drop table #Result

END

-- exec psGENE_StatOrg_Q2_BrutParAge '2016-05-31'