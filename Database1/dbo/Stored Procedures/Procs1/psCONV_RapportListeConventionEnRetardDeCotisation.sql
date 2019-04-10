/********************************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc.

Code du service		: psCONV_RapportListeConventionEnRetardDeCotisation
Nom du service		: Rapport des conventions ayant un retard dans les cotisations
But 				: JIRA TI-3562
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

EXECUTE psCONV_RapportListeConventionEnRetardDeCotisation 1


Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2016-08-10		Donald Huppé						Création du service	
		2016-09-26		Donald Huppé						Au lieu de vérifier les cotisation dans les 36 derniers mois,
															On vérifier le nb de cotisation en retard selon le type de modalité
		2016-10-04		Donald Huppé						jira ti-4972
		2018-11-02		Donald Huppé						jira prod-12681 : Ajout de DirecteurREP

*********************************************************************************************************************/

CREATE PROCEDURE [dbo].[psCONV_RapportListeConventionEnRetardDeCotisation] 
(
	@DemarrerRapport int
)
AS
BEGIN


DECLARE @DateA datetime = GETDATE()

	SELECT 
		c.ConventionNo,
		u.UnitID,
		UnitQty = sum(u.UnitQty),
		Épargne = SUM(Épargne),
		Frais = SUM(Frais),
		DateRIEstimé = min(	dbo.FN_UN_EstimatedIntReimbDate (PmtByYearID,PmtQty,BenefAgeOnBegining,InForceDate,IntReimbAge,IntReimbDateAdjust)),
		EstimatedCotisationAndFee = sum(dbo.FN_UN_EstimatedCotisationAndFee(U.InForceDate,@DateA,DAY(c.FirstPmtDate),u.UnitQty,m.PmtRate,m.PmtByYearID,m.PmtQty,u.InForceDate)) ,
		EstimatedFee = sum(dbo.fn_Un_EstimatedFee(dbo.fn_Un_EstimatedCotisationANDFee(
															U.InForceDate, 
															@DateA, 
															DAY(C.FirstPmtDate), 
															U.UnitQty , 
															M.PmtRate, 
															M.PmtByYearID, 
															M.PmtQty, 
															U.InForceDate), 
												U.UnitQty , 
												M.FeeSplitByUnit, 
												M.FeeByUnit)
							)
	INTO #ESTIM
	FROM Un_Convention c
	join Un_Unit u ON c.ConventionID = u.ConventionID
	JOIN Un_Modal m ON u.ModalID = m.ModalID
	JOIN Un_Plan p ON c.PlanID = p.PlanID 
	join (
		select 
			us.unitid,
			uus.startdate,
			us.UnitStateID
		from 
			Un_UnitunitState us
			join (
				select 
				unitid,
				startdate = max(startDate)
				from un_unitunitstate
				where startDate < DATEADD(d,1 ,@DateA)
				group by unitid
				) uus on uus.unitid = us.unitid 
					and uus.startdate = us.startdate 
					--and us.UnitStateID <> 'CPT'
		)uus on uus.unitID = u.UnitID

	left join (
			SELECT
				U.UnitID,
				Épargne = SUM(Ct.Cotisation),
				Frais = SUM(Ct.Fee)
			FROM Un_Unit U 
			join (
				select 
					us.unitid,
					uus.startdate,
					us.UnitStateID
				from 
					Un_UnitunitState us
					join (
						select 
						unitid,
						startdate = max(startDate)
						from un_unitunitstate
						where startDate < DATEADD(d,1 ,@DateA)
						group by unitid
						) uus on uus.unitid = us.unitid 
							and uus.startdate = us.startdate 
							--and us.UnitStateID <> 'CPT'
				)uus on uus.unitID = u.UnitID
			JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
			join un_oper o on ct.operid = o.operid
			where o.operdate <= @DateA
			group by U.UnitID
		)ep on u.UnitID = ep.UnitID

	WHERE 
		C.PlanID <> 4
		AND U.IntReimbDate IS NULL 
		and u.dtFirstDeposit is not null
		--and c.ConventionNo = 'R-20050406005'
	GROUP by c.ConventionNo,u.UnitID


	SELECT DISTINCT 
		C.ConventionID
		,u.UnitID
		,u.UnitQty
		,NomRep = hr.FirstName + ' ' + hr.LastName
		,r.RepCode
		,r.RepID
		,Directeur = hb.FirstName + ' ' + hb.LastName
		,DirecteurREP = hbr.FirstName + ' ' + hbr.LastName
		,modalité = case
			when m.PmtQty = 1 then 'Unique'
			WHEN m.PmtByYearID = 12 then 'Mensuel'
			when m.PmtQty > 1 and m.PmtByYearID = 1 then 'Annuel'
			end
		,Depot = cast(M.PmtRate * (U.UnitQty ) as money)
	INTO #epg
	FROM Un_Convention C
	JOIN Un_Subscriber S on S.SubscriberID = C.SubscriberID
	JOIN Un_Unit U ON C.ConventionID = U.ConventionID
	join (
		select 
			us.unitid,
			uus.startdate,
			us.UnitStateID
		from 
			Un_UnitunitState us
			join (
				select 
				unitid,
				startdate = max(startDate)
				from un_unitunitstate
				where startDate < DATEADD(d,1 ,@DateA)
				group by unitid
				) uus on uus.unitid = us.unitid 
					and uus.startdate = us.startdate 
					and us.UnitStateID <> 'CPT'
		)uus on uus.unitID = u.UnitID
	join Un_Modal m on u.ModalID = m.ModalID
	left JOIN Un_Rep r on u.RepID = r.RepID
	left JOIN Mo_Human hr on r.RepID = hr.HumanID
	--LEFT JOIN (select unitid, QtyReduite = sum(unitqty) from Un_UnitReduction where ReductionDate > @DateA group by unitid ) UR on UR.unitid = u.unitID
	left join (
		SELECT 
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
				U.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM Un_Unit U
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			GROUP BY U.UnitID, U.RepID
			) M
		JOIN Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			M.UnitID
			)bu on bu.UnitID = u.UnitID
	left join Mo_Human hb on bu.BossID = hb.HumanID
	LEFT JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @DateA, 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @DateA, 120), 10)) 
				GROUP BY
						RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @DateA, 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR,@DateA, 120), 10))
			GROUP BY
				RB.RepID
		)BR ON BR.RepID = S.RepID 
	left join Mo_Human hbr on hbr.HumanID = BR.BossID 


	WHERE 
		u.TerminatedDate is null
		and ISNULL(U.dtFirstDeposit,'9999-12-31') < DATEADD(MONTH,-36 ,@DateA)
		--and c.ConventionNo = 'R-20050406005'

	--SELECT
	--	DISTINCT U.ConventionID
	--INTO #ct36
	--FROM Un_Unit U (readuncommitted)
	--JOIN Un_Cotisation Ct (readuncommitted) ON Ct.UnitID = U.UnitID
	--join un_oper o on ct.operid = o.operid
	--left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
	--left join Un_OperCancelation oc2 on o.OperID = oc2.OperID
	--where 
	--	o.operdate >= DATEADD(MONTH,-36, @DateA)
	--	AND O.OpertypeID in ('CPA','PRD','CHQ','RDI','NSF')
	--	and oc1.OperSourceID is NULL
	--	and oc2.OperID is null
	--group by U.ConventionID


	select 
		EndateDu 
		--,v.UnitID
		,SubscriberID
		,NomSouscripteur
		,ConventionNo
		,Épargne = sum(Épargne)
		,frais = sum(frais)
		,EcartCotisation = sum(EcartCotisation)
		,EcartFrais = sum(EcartFrais)
		,unitqty = sum(v.unitqty)
		,modalité
		,Depot
		,NbDepotEnRetard
		,TypeArretPaiement =BreakingTypeID
		,DébutArret = cast(BreakingStartDate as date)
		,RaisonArret = BreakingReason
		,NomRep
		,RepCode
		,Directeur
		,RepSouscripteur
		,DirecteurREP
	into #PreFinal
	from
		(
		select 
			DISTINCT
			EndateDu = CAST( @DateA as DATE)
			,u.UnitID
			,c.SubscriberID
			,NomSouscripteur = hs.FirstName + ' ' + hs.LastName
			,c.ConventionNo
			,css.ConventionStateID
			,EPG.UnitQty
			,Épargne = isnull(Épargne,0)
			,frais = isnull(frais,0)
			,EstimatedCotisationAndFee = ISNULL(EstimatedCotisationAndFee,0)
			,EstimatedCotisation = ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0)
			,EstimatedFee = ISNULL(EstimatedFee,0)
			,EcartCotisation = isnull(Épargne,0) - ( ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0) )
			,EcartFrais =  isnull(frais,0) - ISNULL(EstimatedFee,0)

			,modalité
			,Depot = round(Depot,2)
			,NbDepotEnRetard = cast(
									case when Depot <> 0 then ( isnull(Épargne,0) - ( ISNULL(EstimatedCotisationAndFee,0) - ISNULL(EstimatedFee,0) ) + isnull(frais,0) - ISNULL(EstimatedFee,0)  )
														/ Depot
									else 0

									end
									as int) * -1
			,NomRep
			,RepCode
			,EPG.RepID
			,Directeur
			,br.BreakingTypeID
			,br.BreakingStartDate
			,br.BreakingEndDate
			,br.BreakingReason
			,RepSouscripteur = hr.FirstName + ' '  + hr.LastName
			,DirecteurREP
		from Un_Convention c
		JOIN Un_Subscriber s on c.SubscriberID = s.SubscriberID
		join Mo_Human hr on s.RepID = hr.HumanID
		join Un_Unit u on c.ConventionID = u.ConventionID
		join Mo_Human hs on c.SubscriberID = hs.HumanID
		left join Un_Breaking br on c.ConventionID = br.ConventionID and @DateA BETWEEN br.BreakingStartDate and isnull(br.BreakingEndDate,'9999-12-31')
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
					where startDate < DATEADD(d,1 ,@DateA)
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						--and cs.ConventionStateID = 'FRM'
			) css on c.conventionid = css.conventionid

		JOIN #epg EPG ON EPG.UnitID = u.UnitID 

		LEFT JOIN #ESTIM es on es.UnitID = u.UnitID

		--left join #ct36 CT36 on c.conventionid = CT36.conventionid

		where 
			c.planid <> 4
			--AND CT36.conventionid IS NULL
			--AND c.ConventionNo in ( 'x-20100420048' ,'x-20110603077')
		)v
	GROUP by 

		EndateDu
		,v.UnitID
		,SubscriberID
		,NomSouscripteur
		,ConventionNo
		,modalité
		,Depot
		,NbDepotEnRetard
		,BreakingTypeID
		,BreakingStartDate
		,BreakingEndDate
		,BreakingReason
		,NomRep
		,RepCode
		,Directeur
		,RepSouscripteur
		,DirecteurREP
	HAVING 1=1
		AND	(
				sum(EcartCotisation) < 0
				OR 
				sum(EcartFrais) < 0
			)

		--AND ( 
		--		(modalité = 'Mensuel' and v.NbDepotEnRetard >= 35)
		--		OR 
		--		(modalité = 'Annuel' and v.NbDepotEnRetard >= 3)
		--	)

	ORDER BY ConventionNo


	-- On sort les conv qui ont au moins un gr d'unité avec NbDepotEnRetard qui correspond au critère
	select 
		EndateDu 
		,SubscriberID
		,NomSouscripteur
		,p.ConventionNo
		,Épargne
		,frais
		,EcartCotisation
		,EcartFrais
		,unitqty
		,modalité
		,Depot
		,NbDepotEnRetard
		,TypeArretPaiement
		,DébutArret
		,RaisonArret
		,NomRep
		,RepCode
		,Directeur
		,RepSouscripteur
		,DirecteurREP
	from #PreFinal p
	join (	
		select 
		DISTINCT ConventionNo 
		from #PreFinal 
		where  
				(modalité = 'Mensuel' and NbDepotEnRetard >= 35)
				OR 
				(modalité = 'Annuel' and NbDepotEnRetard >= 3)
		) v1 on v1.ConventionNo = p.ConventionNo
	ORDER BY p.ConventionNo

END