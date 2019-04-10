/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepConcoursUnitBenef (RP_UN_RepGrossANDNetUnits)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants
Valeurs de retours  :	Dataset 
Note                :	2009-02-13	Donald Huppé	Créaton (à partir de RP_UN_RepGrossANDNetUnits)
						2009-02-26	Donald Huppé	Modification pour ne pas afficher les ventre des rep qui ne sont plus actif à la fin du concours 
													et ajout de la date du permis du Rep (GLPI 1487)
						2009-03-19	Donald Huppé	Correction du nb de nouveaux bénéficiaires est maintenant basé sur dtFirstDeposit au leiu de inforceDate
						2009-04-02	Donald Huppé	Correction de bug :		Dans le calcul de #NewSales, mettre ">=" au lieu de ">". 
																			Enlever la clause where de la sum(brut) <> 0
						2009-04-07	Donald Huppé	Correction du calcul des TFR : reculer au début de l'année pour faire comme RP_UN_RepGrossANDNetUnits
													En attente de reculer de 24 mois comme il se devrait
						2009-04-17	Donald Huppé	Afficher les rep inactif malgré la demande GLPI 1487 car les directeurs comparent ce rapport avec le bulletin et les chiffres ne balancent pas sinon.
						2009-04-20	Donald Huppé	Enlever les Rep inactifs à la demande de Patricia.  Ils ne compareront plus les rapports
						2009-05-11	Donald Huppé	Correction du calcul du nb de départ de bénéficiaire.  On vérifie maintenant si les frais sont couverts et que la raison réduit le taux de conservation
						2009-05-20	Donald Huppé	Modification pour utiliser RP_UN_RepGrossANDNetUnits_Raw
						2009-10-02	Donald Huppé	Mise en production
						2009-11-02	Donald Huppé	Ajout des rep qui n'ont pas de vente dans la plage demandée.  Dans ce cas, on leur met 0 patrout
						2011-08-24	Donald Huppé	correction de la fonction qui donne le directeur du rep en date du jour (gestion des dates avec heures)
						2012-01-18	Donald Huppé	GLPI 6687 : ajout de la date de naissance du rep et son niveau en date de fin
						2012-05-15	Donald Huppé	Faire un left join sur le directeur du rep. Car il peut ne pas y avoir de directeur
						2014-01-08	Donald Huppé	Refaire la sp avec #GrossANDNetUnits par unit. pour faire la glpi 10807 pour ajouter le champ UniteNetteConcourAgeBenef
						2014-04-02	Donald Huppé	glpi 10687
						2014-06-04	Donald Huppé	suivi glpi 10687 : valider que la résil est dans un délai de 60 jours
						2015-01-27	Donald Huppé	Correction suite au projet Corpo, dans le calcul du nombre de bénéficiaires
						2015-10-21	Donald Huppé	glpi 15889 : ajout du montant des cotisations pour la période : Cotis_Periode
						2015-11-23	Donald Huppé	glpi 16173 : modifier la date de signature par la date de début des opérations financières pour déterminer les montants de cotisation
						2015-12-09	Donald Huppé	JIRA J. Gendron et S. Robinson : Saisir une plage de date pour la date de vigueur des gr. d'unité pour le calcul des cotisations
						2016-11-30	Donald Huppé	Clarifier paramêtre d'appel de SL_UN_RepGrossANDNetUnits
						2016-12-05	Donald Huppé	Ajout des cotisation des convention T
						2018-01-04	Donald Huppé	Ajout raison résil 44
						2018-04-18	Donald Huppé	ajustement du calcul des cotisation basé sur dtFirstDeposit et quelques ajustements pour faire pareil comme le nouveau bulletin
						2018-04-19	Donald Huppé	Pour le directeur du rep, on le calcul en date de @EndDate et non Getdate()
						2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU

 exec GU_RP_VentesExcelRepConcoursUnitBenef 1, '2017-01-01', '2017-01-08' ,0, 0

*********************************************************************************************************************/



CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepConcoursUnitBenef] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER, -- ID du représentant : 0 pour tous
	@Actif BIT -- Actifs à la fin du coucours uniquement
	,@StartDateInforceCotisation DATETIME = NULL
	,@EndDateInforceCotisation DATETIME = NULL
	)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER

	SET NOCOUNT ON -- Pour que ça fonctionne avec Access

	--set @StartDate = '2015-01-01'
	--set @EndDate = '2015-01-02'

	--set ARITHABORT on

	SET @dtBegin = GETDATE()

	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
		BossID INT,
		dtFirstDeposit DATETIME )

	INSERT INTO #UniteConvT
	SELECT * FROM fntREPR_ObtenirUniteConvT(1)


/*
	create table #GrossANDNetUnits (
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut_4 FLOAT, Brut_8 FLOAT, Brut_10 FLOAT,
		Retraits_4 FLOAT, Retraits_8 FLOAT,	Retraits_10 FLOAT,
		Reinscriptions_4 FLOAT,	Reinscriptions_8 FLOAT,	Reinscriptions_10 FLOAT,
		Net_4 FLOAT, Net_8 FLOAT, Net_10 FLOAT,
		Brut24_4 FLOAT, Brut24_8 FLOAT, Brut24_10 FLOAT,
		Retraits24_4 FLOAT, Retraits24_8 FLOAT,	Retraits24_10 FLOAT,
		Reinscriptions24_4 FLOAT, Reinscriptions24_8 FLOAT,	Reinscriptions24_10 FLOAT,
		Net24_4 FLOAT, Net24_8 FLOAT, Net24_10 FLOAT)

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, @RepID, 0
*/

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

	create table #GrossANDNetUnitsRes60Jrs (
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

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits --NULL, @StartDate, @EndDate, @RepID , 1 -- on va chercher toutes les données et on filtre par repid à la fin
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = @RepID, --@RepID, -- ID du représentant
		@ByUnit = 1
	
	-- Les données des Rep avec la res "60 jours - 2014" qui affecte le taux de conservation
	INSERT #GrossANDNetUnitsRes60Jrs
	EXEC SL_UN_RepGrossANDNetUnits_Res60JrsAffecteCons --NULL, @StartDate, @EndDate, @RepID , 1 -- on va chercher toutes les données et on filtre par repid à la fin
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = @RepID, --@RepID, -- ID du représentant
		@ByUnit = 1

	select
		t.RepID,
		ConsPctRes60JrsAffecte =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100, 2)
					END	
	into #tblConsRes60Jrs
	from #GrossANDNetUnitsRes60Jrs t
	group by t.RepID

	select 
		RepID = isnull(lrc.RepID,u.RepID),
		QteUniteRES60 = SUM(ur.UnitQty),
		QteSouscRes60 = COUNT(DISTINCT c.SubscriberID),
		QteBenefRes60 = COUNT(DISTINCT c.BeneficiaryID)
	into #tblQteRes
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
	join Un_UnitReduction ur on u.UnitID = ur.UnitID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo

	where (UR.UnitReductionReasonID in ( 37,44) AND DATEDIFF(d,U.SignatureDate,UR.ReductionDate) <= 60)
	and ur.ReductionDate between @StartDate and @EndDate
	group by isnull(lrc.RepID,u.RepID)
	
	-- Table de tous les reps actifs actuel
	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	into #AllRep
	FROM Un_RepBossHist RB
	JOIN un_rep r on r.repid = rb.repid
	JOIN (
		SELECT
			RepID,
			RepBossPct = MAX(RepBossPct)
		FROM Un_RepBossHist RB
		WHERE RepRoleID = 'DIR'
			AND StartDate IS NOT NULL
			AND (StartDate <= @EndDate)
			AND (EndDate IS NULL OR EndDate >= @EndDate)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @EndDate)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDate)
		AND isnull(r.BusinessEnd,'3000-01-01') >= @EndDate
	GROUP BY
		RB.RepID

	-- Va chercher le nombre de nouveaux bénéficiaires entre deux dates pour chaque représentant
	SELECT 
		Repid = isnull(lrc.RepID,u.RepID),
		NbBenef = COUNT(NB.BeneficiaryID)
	INTO #tRepNewBeneficiary
	FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			WHERE U.terminatedDate is null or U.terminatedDate > @EndDate -- permet d'aditionner les bénéficaire qui sont de retour suite à une résiliation
			GROUP BY C.BeneficiaryID
			HAVING MIN(U.dtFirstDeposit) BETWEEN @StartDate AND @EndDate -- doit être prendant cette période
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo

	GROUP BY isnull(lrc.RepID,u.RepID)

	-- Va chercher le nombre de départs de bénéficiaires entre deux dates pour chaque représentant

	SELECT 
		Repid = isnull(lrc.RepID,u.RepID),
		NbOldBenef = COUNT(NB.BeneficiaryID)
	INTO #tRepOldBeneficiary
	FROM ( 
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit), -- Premier "Premier Dépôt"
				MaxterminatedDate = Max(U.terminatedDate) -- Dernière résiliation
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			JOIN (
				SELECT 
					C.BeneficiaryID,
					BenefNbUnit.nbUnit,
					NbResil = count(*) -- nombre de résiliation avec frais non couverts pour chaque bénéf.
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
				left JOIN ( -- La somme des résil de frais qui affectent le taux de conservation
					SELECT 
						unitid, FeeSumByUnit = sum(FeeSumByUnit) 
					FROM Un_UnitReduction UR
					LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
					where (URR.bReduitTauxConservationRep = 1 OR URR.bReduitTauxConservationRep IS NULL) 
					GROUP BY unitid	
						) UR ON U.unitID = UR.unitID
				JOIN UN_MODAL M on u.ModalID = M.ModalID
				JOIN ( -- nb total de gr d'unité pour chaque bénéf.
					SELECT  
						C.BeneficiaryID,
						nbUnit = count(*)
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
					GROUP BY BeneficiaryID
					) BenefNbUnit on BenefNbUnit.BeneficiaryID = C.BeneficiaryID
				WHERE U.terminatedDate is not null -- Résilié...
				-- ...avec frais non couverts. S'il n'y en a pas(car left join), alors UR.FeeSumByUnit est null.  
				-- Et Null est plus grand que M.FeeByUnit.  Alors ce n'est pas une résiliation qui affecte (car la clause where est alors fausse), 
				-- donc la résiliation ne compte pas.
				AND UR.FeeSumByUnit < M.FeeByUnit
				GROUP BY C.BeneficiaryID,BenefNbUnit.nbUnit
				HAVING COUNT(*) = BenefNbUnit.nbUnit  -- Nb de résil = nb total de gr d'unité : Donc toutes les unitées sont résiliées
				) OldBenef on OldBenef.BeneficiaryID = C.BeneficiaryID
			GROUP BY C.BeneficiaryID
			HAVING MIN(U.dtFirstDeposit) < @StartDate -- Premier "premier dépôt" doit être avant le concours.  sinon, si pendant le concours, ce cas est géré par le cas précédent
				and Max(U.terminatedDate) between @StartDate AND @EndDate -- dernière résiliation pendant le concours
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo

	GROUP BY isnull(lrc.RepID,u.RepID)


	SELECT 
		V.RepID
		,Cotis_Periode = SUM(V.Cotis_Periode)
	INTO #Cotis_Periode
	from (
		select 
			u.RepID
			,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
		from 
			dbo.Un_Convention c
			join dbo.un_unit u on c.ConventionID = u.ConventionID
			join dbo.un_cotisation ct on ct.UnitID = u.UnitID
			join dbo.un_oper o on ct.OperID = o.OperID
			left join dbo.Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join dbo.Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			left join #UniteConvT T on u.UnitID = T.UnitID
		where 1=1
			and T.UnitID is NULL

			-- Si on saisit une plage de date de vigueur, on la prend, sinon c'est la plage de date habituelle
			AND (
						(
							((@StartDateInforceCotisation IS NOT NULL AND @EndDateInforceCotisation IS NOT NULL)	AND u.dtFirstDeposit BETWEEN @StartDateInforceCotisation AND @EndDateInforceCotisation)
							OR
							((@StartDateInforceCotisation IS     NULL  OR @EndDateInforceCotisation IS     NULL)	AND u.dtFirstDeposit BETWEEN @StartDate AND @EndDate)
						)

						OR c.planid = 4.
				)
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			AND o.OperDate BETWEEN @StartDate and @EndDate
			AND o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET', 'COU')
			AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			u.RepID

		UNION ALL

		-- cont T
		select 
			T.RepID
			,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
		from 
			Un_Convention c
			JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
			join #UniteConvT T on u.UnitID = T.UnitID
			join un_cotisation ct on ct.UnitID = u.UnitID
			join un_oper o on ct.OperID = o.OperID
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
		where 1=1

			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			and o.OperDate BETWEEN @StartDate and @EndDate
			and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
			and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			T.RepID
		)V
	GROUP BY V.RepID

	--- Résultat final

	select  
		t.RepID,
		Rep.RepCode,
		HRep.firstName,
		HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		BusinessEnd = Rep.BusinessEnd,
		HREP.BirthDate,

		DirFirstName = HDir.FirstName,
		DirLastName = HDir.LastName,

		NbBenef = isnull(NbBenef,0), -- Nouveau Bénéf
		NbOldBenef = isnull(NbOldBenef,0), -- Départ bénéf
		NbBenefNet = isnull(NbBenef,0) - isnull(NbOldBenef,0), -- Nouveau bénéf net

		--NbUniteBrutUniv = sum(Brut_8), -- select * from tblCONV_RegroupementsRegimes
		--NbUniteNetUniv = sum(Net_8),

		--NbUniteBrutRFlex = sum(Brut_10),
		--NbUniteNetRFlex = sum(Net_10),

		--NbUniteBrutInd = sum(Brut_4),
		--NbUniteNetInd = sum(Net_4),

		NbUniteBrutUniv = sum(case WHEN rr.vcCode_Regroupement = 'UNI' THEN t.Brut else 0 END),
		NbUniteNetUniv = sum(case WHEN rr.vcCode_Regroupement = 'UNI' THEN t.Brut - t.Retraits + t.Reinscriptions else 0 END),

		NbUniteBrutRFlex = sum(case WHEN rr.vcCode_Regroupement = 'REF' THEN t.Brut else 0 END),
		NbUniteNetRFlex = sum(case WHEN rr.vcCode_Regroupement = 'REF' THEN t.Brut - t.Retraits + t.Reinscriptions else 0 END),

		NbUniteBrutInd = sum(case WHEN rr.vcCode_Regroupement = 'IND' THEN t.Brut else 0 END),
		NbUniteNetInd = sum(case WHEN rr.vcCode_Regroupement = 'IND' THEN t.Brut - t.Retraits + t.Reinscriptions else 0 END),

		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100, 2)
					END,
					
		UniteNetteConcourAgeBenef =  SUM((t.Brut - t.Retraits + t.Reinscriptions) 
							* case 
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 0 and 1 and U.dtfirstdeposit between @StartDate and @EndDate then 1
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 2 and 3 and U.dtfirstdeposit between @StartDate and @EndDate then 1.5
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 4 and 5 and U.dtfirstdeposit between @StartDate and @EndDate then 2
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 6 and 7 and U.dtfirstdeposit between @StartDate and @EndDate then 3
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 8 and 9 and U.dtfirstdeposit between @StartDate and @EndDate then 4
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 10 and 11 and U.dtfirstdeposit between @StartDate and @EndDate then 5
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 12 and 13 and U.dtfirstdeposit between @StartDate and @EndDate then 6
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 14 and 15 and U.dtfirstdeposit between @StartDate and @EndDate then 7
								when dbo.fn_Mo_Age (hben.BirthDate, U.dtfirstdeposit) between 16 and 17 and U.dtfirstdeposit between @StartDate and @EndDate then 8
								else 1
								END)
		,r60.ConsPctRes60JrsAffecte
		,QteUniteRES60 = ISNULL(Q60.QteUniteRES60,0)
		,QteSouscRes60 = isnull(Q60.QteSouscRes60,0)
		,QteBenefRes60 = isnull(Q60.QteBenefRes60,0)
		,Cotis_Periode = isnull(Cotis_Periode,0)		
			/*
		bénéficiaire entre 0 et 1 an > 1 unité = 1 unité
		bénéficiaire entre 2 et 3 ans > 1 unité = 1,5 unités
		bénéficiaire entre 4 et 5 ans > 1 unité = 2 unités
		bénéficiaire entre 6 et 7 ans > 1 unité = 3 unités
		bénéficiaire entre 8 et 9 ans > 1 unité = 4 unités
		bénéficiaire entre 10 et 11 ans > 1 unité = 5 unités
		bénéficiaire entre 12 et 13 ans > 1 unité = 6 unités
		bénéficiaire entre 14 et 15 ans > 1 unité = 7 unités
		bénéficiaire entre 16 et 17 ans > 1 unité = 8 unités

			*/
					
	into #TMPResult
	from 
		#GrossANDNetUnits t

		JOIN dbo.Un_Unit u on t.unitid = u.UnitID
		JOIN dbo.Un_Convention c ON u.ConventionID = c.ConventionID
		JOIN dbo.Mo_Human hben ON c.BeneficiaryID = hben.HumanID
		join Un_Plan p ON c.PlanID = p.PlanID
		join tblCONV_RegroupementsRegimes rr ON p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime

		join Un_Rep Rep on t.repid = Rep.repid
		JOIN dbo.Mo_Human HREP on t.repid = HREP.humanid

		left join #tRepNewBeneficiary NB on t.repid = nb.repid
		left join #tRepOldBeneficiary OB on t.repid = ob.repid

		left join ( --2012-05-15
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
						AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)
						AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)) 
					GROUP BY
							RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
				WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)
					AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10))
				GROUP BY
					RB.RepID
		) RepDIR on t.repID = RepDIR.RepID
		left join Un_Rep DIR on RepDIR.BossID = DIR.RepId --2012-05-15
		left JOIN dbo.Mo_Human HDIR on DIR.repid = HDIR.humanid --2012-05-15
		left join #tblConsRes60Jrs r60 ON r60.repid = t.RepID
		left JOIN #tblQteRes Q60 ON Q60.repid = t.RepID
		left join #Cotis_Periode CP on CP.RepID = t.RepID

	where (isnull(rep.BusinessEnd,'3000-01-01') > @EndDate -- exclure les rep rendu inactif avant la fin du concours (GLPI 1487)
		OR @Actif = 0)
		-- and (ISNULL(BrutUniv,0) + ISNULL(BrutRFLEX,0) + ISNULL(BrutInd,0)) <> 0 -- à enlever car cause un débalancement avec RP_UN_RepGrossANDNetUnits
		
	group by
		t.RepID,
		Rep.RepCode,
		HRep.firstName,
		HRep.LastName,
		Rep.BusinessStart,
		Rep.BusinessEnd,
		HREP.BirthDate,
		HDir.FirstName,
		HDir.LastName,
		isnull(NbBenef,0), -- Nouveau Bénéf
		isnull(NbOldBenef,0), -- Départ bénéf
		isnull(NbBenef,0) - isnull(NbOldBenef,0) -- Nouveau bénéf net
		,r60.ConsPctRes60JrsAffecte
		,Q60.QteUniteRES60
		,Q60.QteSouscRes60
		,Q60.QteBenefRes60
		,Cotis_Periode
	order by

		HRep.LastName,
		HRep.firstName

	select
		RepID,
		RepCode,
		firstName,
		LastName,
		BusinessStart,
		BusinessEnd,
		
		BirthDate,

		DirFirstName,
		DirLastName,

		NbBenef, -- Nouveau Bénéf
		NbOldBenef, -- Départ bénéf
		NbBenefNet, -- Nouveau bénéf net

		NbUniteBrutUniv, -- select * from un_plan
		NbUniteNetUniv,

		NbUniteBrutRFlex,
		NbUniteNetRFlex,

		NbUniteBrutInd,
		NbUniteNetInd,

		ConsPct

		,UniteNetteConcourAgeBenef
		
		,ConsPctRes60JrsAffecte
		,QteUniteRES60
		,QteSouscRes60
		,QteBenefRes60		
		,Cotis_Periode
		
	into #Final

	from #TMPResult

	UNION

	select

		AR.RepID,
		Rep.RepCode,
		HREP.firstName,
		HREP.LastName,
		REP.BusinessStart,
		REP.BusinessEnd,
		
		HREP.BirthDate,

		DirFirstName = HDIR.firstName,
		DirLastName = HDIR.Lastname,

		NbBenef = 0, -- Nouveau Bénéf
		NbOldBenef = 0, -- Départ bénéf
		NbBenefNet = 0, -- Nouveau bénéf net

		NbUniteBrutUniv = 0, -- select * from un_plan
		NbUniteNetUniv = 0,

		NbUniteBrutRFlex = 0,
		NbUniteNetRFlex = 0,

		NbUniteBrutInd = 0,
		NbUniteNetInd = 0,

		ConsPct = 0
	
		,UniteNetteConcourAgeBenef = 0
		
		,ConsPctRes60JrsAffecte = 0
		,QteUniteRES60 = 0
		,QteSouscRes60 = 0
		,QteBenefRes60 = 0	
		,Cotis_Periode = 0
		
	from 
		#AllRep AR
		join Un_Rep Rep on AR.repid = Rep.repid
		JOIN dbo.Mo_Human HREP on Rep.repid = HREP.humanid
 		join Un_Rep DIR on AR.BossID = DIR.RepId
		JOIN dbo.Mo_Human HDIR on DIR.repid = HDIR.humanid
	where AR.repid not in (select repid from #TMPResult)

	order by

		LastName,
		firstName

	SELECT 
		F.RepID,
		F.RepCode,
		F.firstName,
		F.LastName,
		F.BusinessStart,
		F.BusinessEnd,

		F.DirFirstName,
		F.DirLastName,

		F.NbBenef, -- Nouveau Bénéf
		F.NbOldBenef, -- Départ bénéf
		F.NbBenefNet, -- Nouveau bénéf net

		F.NbUniteBrutUniv, -- select * from un_plan
		F.NbUniteNetUniv,

		F.NbUniteBrutRFlex,
		F.NbUniteNetRFlex,

		F.NbUniteBrutInd,
		F.NbUniteNetInd,

		F.ConsPct,
		
		F.BirthDate,
		RRole.LevelDesc,
		
		F.UniteNetteConcourAgeBenef
		
		,F.ConsPctRes60JrsAffecte
		,F.QteUniteRES60
		,F.QteSouscRes60
		,F.QteBenefRes60	
		,F.Cotis_Periode	
		
	from #Final F
	
	left join (
		SELECT
			R.Repid,
			Ro.RepRoleDesc,
			L.LevelDesc
		FROM Un_Rep R
		JOIN Un_RepLevelHist H ON R.RepID = H.RepID and @EndDate between H.startdate and isnull(H.enddate,'3000-01-01')
		JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
		JOIN Un_RepRole Ro ON Ro.RepRoleID = L.RepRoleID
		where Ro.reproleid = 'REP' and (r.businessEnd is null or r.businessEnd >= @EndDate)
	) RRole on F.repid = RRole.repid	


--set ARITHABORT off

END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_VentesExcelRepConcoursUnitBenef] TO [Rapport]
    AS [dbo];

