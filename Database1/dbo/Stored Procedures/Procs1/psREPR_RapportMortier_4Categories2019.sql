/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psREPR_RapportMortier_4Categories2019
Description         :	4 catégorie supplémentaire intégré dans le Rapport "Mortier". anciennement dans le rapport des 4 catégorie (psREPR_RapportConcours4Categories2015)
Valeurs de retours  :	Dataset 
Note                :	2018-07-31	Donald Huppé	Création (à partir de psREPR_RapportMortier_4Categories2018)
						2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU

exec psREPR_RapportMortier_4Categories2019 '2018-01-01', '2018-07-31', 32

drop proc psREPR_RapportMortier_4Categories2019

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportMortier_4Categories2019] (
	@StartDate DATETIME, -- Date de début de l'année 10 qui est l'année du concours
	@EndDate DATETIME, -- Date de fin de l'année 10 qui est l'année du concours
	@Ratio int

	)
AS
BEGIN

set arithabort on

--set @StartDate = '2014-10-06'
--set @EndDate = '2015-02-19'

	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER,
		@Actif BIT = 1,
		@RepID INTEGER = 0

	DECLARE @YearStart INT -- l'année de départ de la 1ere année
	DECLARE @DateYear1_From DATETIME
	DECLARE @DateYear1_To DATETIME
	DECLARE @DateYear2_From DATETIME
	DECLARE @DateYear2_To DATETIME
	DECLARE @DateYear3_From DATETIME
	DECLARE @DateYear3_To DATETIME
	DECLARE @DateYear4_From DATETIME
	DECLARE @DateYear4_To DATETIME
	DECLARE @DateYear5_From DATETIME
	DECLARE @DateYear5_To DATETIME
	DECLARE @DateYear6_From DATETIME
	DECLARE @DateYear6_To DATETIME
	DECLARE @DateYear7_From DATETIME
	DECLARE @DateYear7_To DATETIME
	DECLARE @DateYear8_From DATETIME
	DECLARE @DateYear8_To DATETIME
	DECLARE @DateYear9_From DATETIME
	DECLARE @DateYear9_To DATETIME
	
	--jira ti-5468
	SET @YearStart = YEAR(@StartDate) - 9

	SET @DateYear1_From = CAST(@YearStart AS VARCHAR(4)) + '-01-01'
	SET @DateYear1_To = CAST(@YearStart  AS VARCHAR(4)) + '-12-31'

	SET @DateYear2_From = CAST(@YearStart + 1 AS VARCHAR(4)) + '-01-01'
	SET @DateYear2_To = CAST(@YearStart + 1 AS VARCHAR(4)) + '-12-31'

	SET @DateYear3_From = CAST(@YearStart + 2 AS VARCHAR(4)) +'-01-01'
	SET @DateYear3_To = CAST(@YearStart + 2 AS VARCHAR(4)) + '-12-31'

	SET @DateYear4_From = CAST(@YearStart + 3 AS VARCHAR(4)) + '-01-01'
	SET @DateYear4_To = CAST(@YearStart + 3 AS VARCHAR(4)) + '-12-31'

	SET @DateYear5_From = CAST(@YearStart + 4 AS VARCHAR(4)) + '-01-01'
	SET @DateYear5_To = CAST(@YearStart + 4 AS VARCHAR(4)) + '-12-31'

	SET @DateYear6_From = CAST(@YearStart + 5 AS VARCHAR(4)) + '-01-01'
	SET @DateYear6_To = CAST(@YearStart + 5 AS VARCHAR(4)) + '-12-31'

	SET @DateYear7_From = CAST(@YearStart + 6 AS VARCHAR(4)) + '-01-01'
	SET @DateYear7_To = CAST(@YearStart + 6 AS VARCHAR(4)) + '-12-31'

	SET @DateYear8_From = CAST(@YearStart + 7 AS VARCHAR(4)) + '-01-01'
	SET @DateYear8_To = CAST(@YearStart + 7 AS VARCHAR(4)) + '-12-31'

	SET @DateYear9_From = CAST(@YearStart + 8 AS VARCHAR(4)) + '-01-01'
	SET @DateYear9_To = CAST(@YearStart + 8 AS VARCHAR(4)) + '-12-31'


	SET NOCOUNT ON -- Pour que ça fonctionne avec Access

	SET @dtBegin = GETDATE()


	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
		BossID INT,
		dtFirstDeposit DATETIME )

	INSERT INTO #UniteConvT
	SELECT * FROM fntREPR_ObtenirUniteConvT(1)

	create table #GrossANDNetUnitsByUnits (
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
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnitsCons from #GrossANDNetUnits
	select * into #GrossANDNetUnits_Concours from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear1_From, -- Date de début
		@EndDate = @DateYear1_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_1 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear2_From, -- Date de début
		@EndDate = @DateYear2_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_2 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear3_From, -- Date de début
		@EndDate = @DateYear3_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_3 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear4_From, -- Date de début
		@EndDate = @DateYear4_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_4 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear5_From, -- Date de début
		@EndDate = @DateYear5_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_5 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear6_From, -- Date de début
		@EndDate = @DateYear6_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_6 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear7_From, -- Date de début
		@EndDate = @DateYear7_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_7 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear8_From, -- Date de début
		@EndDate = @DateYear8_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_8 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @DateYear9_From, -- Date de début
		@EndDate = @DateYear9_To, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_9 from #GrossANDNetUnits

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = @RepID, -- ID du représentant
		@ByUnit = 0 

	select * into #GrossANDNetUnits_10 from #GrossANDNetUnits


	-- Les données des Rep
	INSERT #GrossANDNetUnitsByUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL,
		@StartDate = @StartDate,
		@EndDate = @EndDate,
		@RepID = 0,
		@ByUnit = 1 


	-- Table des ajout d'unités
	SELECT 
		gnu.RepID,
		QteAjoutBrut = 0,
		QteAjoutResil = 0,
		QteAjoutNet = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
	into #tAjoutUnite
	from #GrossANDNetUnitsByUnits gnu
	left join (
		select
			conventionid,
			FirstUnitID = min(unitid)
		FROM dbo.Un_Unit 
		group by conventionid
		) FU on gnu.unitid = FU.FirstUnitID
	join Un_Unit u on u.UnitID = gnu.UnitID
	join Un_Convention c on c.ConventionID = u.ConventionID
	join un_rep r on r.RepID = gnu.RepID
	join Mo_Human hr on r.RepID = hr.HumanID
	where 
		fu.FirstUnitID is null 
		OR C.ConventionNo LIKE 'T%'
	group by gnu.RepID
	HAVING round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3) > 0

/*
		-- Table des ajout d'unités
	select
		v.RepID,
		QteAjoutBrut = sum(QteAjoutBrut),
		QteAjoutResil = sum(QteAjoutResil),
		QteAjoutNet = sum(QteAjoutNet)
	into #tAjoutUnite
	from (
		select 
			RepID,
			QteAjoutBrut = sum(u.unitqty + isnull(URAll.unitqty,0)),
			QteAjoutResil = sum(isnull(URBeforeDate.unitqty,0)),
			QteAjoutNet = sum(u.unitqty + isnull(URAfterDate.unitqty,0))
		--into #tAjoutUnite
		from 
		un_unit u
		left join (
			select
				conventionid,
				FirstUnitID = min(unitid)
			FROM dbo.Un_Unit 
			group by conventionid
			) FU on u.unitid = FU.FirstUnitID
		LEFT JOIN (SELECT unitid, unitQty = SUM(unitQty) FROM un_unitreduction GROUP BY unitid) URAll ON u.unitid = URAll.unitid
		LEFT JOIN (SELECT unitid, unitQty = SUM(unitQty) FROM un_unitreduction where ReductionDate > @EndDate GROUP BY unitid) URAfterDate ON u.unitid = URAfterDate.unitid
		LEFT JOIN (SELECT unitid, unitQty = SUM(unitQty) FROM un_unitreduction where ReductionDate <= @EndDate GROUP BY unitid) URBeforeDate ON u.unitid = URBeforeDate.unitid
		where U.dtFirstDeposit BETWEEN @StartDate AND @EndDate
		and FU.FirstUnitID is null
		group by Repid
	
		union all	

		-- T seulement (pas les I BEC)
		
		SELECT 
			T.RepID,
			QteAjoutBrut = sum(u.unitqty + isnull(URAll.unitqty,0)),
			QteAjoutResil = 0,
			QteAjoutNet = sum(u.unitqty + isnull(URAll.unitqty,0))
		FROM #UniteConvT T
		JOIN Un_Unit U ON T.UnitID = U.UnitID
		JOIN Un_Convention C ON U.ConventionID = C.ConventionID
		LEFT JOIN (SELECT unitid, unitQty = SUM(unitQty) FROM un_unitreduction GROUP BY unitid) URAll ON u.unitid = URAll.unitid
		WHERE 
			C.ConventionNo LIKE 'T%'
			AND T.dtFirstDeposit BETWEEN @StartDate AND @EndDate
		GROUP BY T.RepID
	)v
	group by v.RepID
*/

	select 
		RepID,
		NbResilComplete = count(*)
	into #tResilComplet
	FROM dbo.Un_Subscriber s
	join (
		select 
			c2.SubscriberID
			--LastTerminated = max(terminatedDate),
			--CN.NbGrUnite,
			--NbGrUnitResil = count(*)
		from 
			un_unit un
			JOIN dbo.Un_Convention c2 on c2.conventionid = un.conventionid
			JOIN dbo.Un_Subscriber s2 on s2.subscriberID = c2.subscriberID
			join (
				select c.SubscriberID, NbGrUnite = count(*)
				FROM dbo.Un_Unit u1
				JOIN dbo.Un_Convention c on c.conventionid = u1.conventionid
				group by c.SubscriberID
				) CN on c2.SubscriberID = CN.SubscriberID
		where un.TerminatedDate is not null
		group by c2.SubscriberID,CN.NbGrUnite
		having count(*) = CN.NbGrUnite
		and max(terminatedDate) between @StartDate AND @EndDate
		--order by max(terminatedDate)
		) SR on s.subscriberID = SR.subscriberID
	group by RepID
	
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

	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	update RD set RD.BossID = LA.BossID
	from #AllRep RD
	join tblREPR_LienAgenceRepresentantConcours LA ON RD.RepID = LA.RepID
	where LA.BossID = 671417

	-- Va chercher le nombre de nouveaux bénéficiaires entre deux dates pour chaque représentant
	SELECT 
		U.RepID,
		NbBenef = COUNT(NB.BeneficiaryID),
		NbBenef_2a10 = COUNT(case when GroupAgeBenef = 2 then NB.BeneficiaryID else NULL end)
	INTO #tRepNewBeneficiary
	FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			GroupAgeBenef,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				GroupAgeBenef = case when CAST((DATEDIFF(DAY, hb.BirthDate, MIN(U.dtFirstDeposit)) / 365.25) AS INTEGER) between 2 and 10 then 2 else 0 end,
				MindtFirstDeposit = MIN(U.dtFirstDeposit)
			FROM dbo.Un_Convention C
			JOIN dbo.mo_human hb on c.beneficiaryid = hb.humanid
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			WHERE U.terminatedDate is null or U.terminatedDate > @EndDate -- permet d'aditionner les bénéficaire qui sont de retour suite à une résiliation
			GROUP BY C.BeneficiaryID,hb.BirthDate
			HAVING MIN(U.dtFirstDeposit) BETWEEN @StartDate AND @EndDate -- doit être prendant cette période
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID,GroupAgeBenef
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	--select * from #tRepNewBeneficiary order by repid
	--return

	-- Va chercher le nombre de départs de bénéficiaires entre deux dates pour chaque représentant

	SELECT 
		U.RepID,
		NbDepartBenef = COUNT(NB.BeneficiaryID),
		NbDepartBenef_2a10 = COUNT(case when GroupAgeBenef = 2 then NB.BeneficiaryID else NULL end)
	INTO #tRepOldBeneficiary
	FROM ( 
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			GroupAgeBenef,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				GroupAgeBenef = case when CAST((DATEDIFF(DAY, hb.BirthDate, MIN(U.dtFirstDeposit)) / 365.25) AS INTEGER) between 2 and 10 then 2 else 0 end,
				MindtFirstDeposit = MIN(U.dtFirstDeposit), -- Premier "Premier Dépôt"
				MaxterminatedDate = Max(U.terminatedDate) -- Dernière résiliation
			FROM dbo.Un_Convention C
			JOIN dbo.mo_human hb on c.beneficiaryid = hb.humanid
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
			GROUP BY C.BeneficiaryID,hb.BirthDate
			HAVING MIN(U.dtFirstDeposit) < @StartDate -- Premier "premier dépôt" doit être avant le concours.  sinon, si pendant le concours, ce cas est géré par le cas précédent
				and Max(U.terminatedDate) between @StartDate AND @EndDate -- dernière résiliation pendant le concours
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID,GroupAgeBenef
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	--select * from #tRepOldBeneficiary
	--return

	-- Va chercher le nombre de nouveaux souscripteurs entre deux dates pour chaque représentant
	SELECT 
		U.RepID,
		NbSousc = COUNT(NB.SubscriberID),
		NbGrParent = COUNT(case when GrParent = 1 then NB.SubscriberID else NULL end)
	INTO #tRepNewSubscriber
	FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.SubscriberID,
			GrParent = case when tiRelationshipTypeID = 2 then 1 else 0 end,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.SubscriberID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			WHERE U.terminatedDate is null or U.terminatedDate > @EndDate -- permet d'aditionner les bénéficaire qui sont de retour suite à une résiliation
			GROUP BY C.SubscriberID
			HAVING MIN(U.dtFirstDeposit) BETWEEN @StartDate AND @EndDate -- doit être prendant cette période
			) NB 
		JOIN dbo.Un_Convention C ON C.SubscriberID = NB.SubscriberID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.SubscriberID,case when tiRelationshipTypeID = 2 then 1 else 0 end
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	-- Va chercher le nombre de départs de souscripteurs entre deux dates pour chaque représentant

	SELECT 
		U.RepID,
		NbDepartSousc = COUNT(NB.SubscriberID),
		NbDepartGrParent = COUNT(case when GrParent = 1 then NB.SubscriberID else NULL end)
	INTO #tRepOldSubscriber
	FROM ( 
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.SubscriberID,
			GrParent = case when tiRelationshipTypeID = 2 then 1 else 0 end,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.SubscriberID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit), -- Premier "Premier Dépôt"
				MaxterminatedDate = Max(U.terminatedDate) -- Dernière résiliation
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			JOIN (
				SELECT 
					C.SubscriberID,
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
						C.SubscriberID,
						nbUnit = count(*)
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
					GROUP BY SubscriberID
					) BenefNbUnit on BenefNbUnit.SubscriberID = C.SubscriberID
				WHERE U.terminatedDate is not null -- Résilié...
				-- ...avec frais non couverts. S'il n'y en a pas(car left join), alors UR.FeeSumByUnit est null.  
				-- Et Null est plus grand que M.FeeByUnit.  Alors ce n'est pas une résiliation qui affecte (car la clause where est alors fausse), 
				-- donc la résiliation ne compte pas.
				AND UR.FeeSumByUnit < M.FeeByUnit
				GROUP BY C.SubscriberID,BenefNbUnit.nbUnit
				HAVING COUNT(*) = BenefNbUnit.nbUnit  -- Nb de résil = nb total de gr d'unité : Donc toutes les unitées sont résiliées
				) OldBenef on OldBenef.SubscriberID = C.SubscriberID
			GROUP BY C.SubscriberID
			HAVING MIN(U.dtFirstDeposit) < @StartDate -- Premier "premier dépôt" doit être avant le concours.  sinon, si pendant le concours, ce cas est géré par le cas précédent
				and Max(U.terminatedDate) between @StartDate AND @EndDate -- dernière résiliation pendant le concours
			) NB 
		JOIN dbo.Un_Convention C ON C.SubscriberID = NB.SubscriberID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.SubscriberID, case when tiRelationshipTypeID = 2 then 1 else 0 end
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	--Create table #GrossANDNetUnitsOriTIN (
	--		UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier NewSale, terminated et ReUsed ensemble.
	--		UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original.
	--		RepID INTEGER,
	--		Recrue INTEGER,
	--		BossID INTEGER,
	--		RepTreatmentID INTEGER,
	--		RepTreatmentDate DATETIME,
	--		Brut FLOAT,
	--		Retraits FLOAT,
	--		Reinscriptions FLOAT,
	--		Brut24 FLOAT,
	--		Retraits24 FLOAT,
	--		Reinscriptions24 FLOAT) 

	SELECT 
		V.RepID
		,Cotis_Periode = SUM(V.Cotis_Periode)
	INTO #Cotis
	from (
		select 
			u.RepID
			,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
		from 
			Un_Convention c
			JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
			join un_cotisation ct on ct.UnitID = u.UnitID
			join un_oper o on ct.OperID = o.OperID
			left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
			left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			left join #UniteConvT T on u.UnitID = T.UnitID
		where 1=1
			and T.UnitID is NULL

			--u.InForceDate BETWEEN @StartDate and @EndDate
			and (
				u.dtFirstDeposit BETWEEN @StartDate and @EndDate
					OR
				c.planid = 4
				)
			
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			and o.OperDate BETWEEN @StartDate and @EndDate
			and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
			and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			u.RepID

		UNION ALL

		-- conv T
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
			--u.SignatureDate BETWEEN @StartDate and @EndDate
			------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
			and o.OperDate BETWEEN @StartDate and @EndDate
			and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
			and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
			and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
			-----------------------------------------------------------------------------------------------------------
		group by 
			T.RepID
		)V
	WHERE V.RepID <> 149876 -- siège social
	GROUP BY V.RepID


	--- Résultat final

	select  
		t.RepID,
		Rep.RepCode,
		HRep.firstName,
		HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		BusinessEnd = Rep.BusinessEnd,

		DirFirstName = HDir.FirstName,
		DirLastName = HDir.LastName,

		QteAjoutUniteBrut = isnull(AU.QteAjoutBrut,0),
		QteAjoutUniteResil = isnull(AU.QteAjoutResil,0),
		QteAjoutUniteNet = isnull(AU.QteAjoutNet,0),
		
		NbBenef = isnull(NbBenef,0), -- Nouveau Bénéf
		NbDepartBenef = isnull(NbDepartBenef,0), -- Départ bénéf
		NbBenefNet = isnull(NbBenef,0) - isnull(NbDepartBenef,0), -- Nouveau bénéf net

		NbBenef_2A10 = isnull(NbBenef_2A10,0), -- Nouveau Bénéf
		NbDepartBenef_2A10 = isnull(NbDepartBenef_2A10,0), -- Départ bénéf
		NbBenefNet_2A10 = isnull(NbBenef_2A10,0) - isnull(NbDepartBenef_2A10,0), -- Nouveau bénéf net

		NbSousc = isnull(NbSousc,0), -- Nouveau Bénéf
		NbDepartSousc = isnull(NbDepartSousc,0), -- Départ bénéf
		NbSouscNet = isnull(NbSousc,0) - isnull(NbDepartSousc,0), -- Nouveau bénéf net

		NbGrParent = isnull(NbGrParent,0), -- Nouveau Bénéf
		NbDepartGrParent = isnull(NbDepartGrParent,0), -- Départ bénéf
		NbGrParentNet = isnull(NbGrParent,0) - isnull(NbDepartGrParent,0), -- Nouveau bénéf net

		Reinscriptions = sum(Reinscriptions_4 + Reinscriptions_8 + Reinscriptions_10),

		NbResilComplete = isnull(RC.NbResilComplete,0),

		--QteUniteTransertIN = isnull(TIN.UnitQtyTIN,0),
		--NbContratTransertIN = isnull(TIN.NbContratIN,0),
		--MontantSouscritTIN = isnull(TIN.MontantSouscritTIN,0),

		ConsPct =	CASE
						WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
						ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END,

		Brut01 = isnull(n01.Brut01,0),
		Net01 = isnull(n01.Net01,0),
		
		Brut02 = isnull(n02.Brut02,0),
		Net02 = isnull(n02.Net02,0),
		
		Brut03 = isnull(n03.Brut03,0),
		Net03 = isnull(n03.Net03,0),
		
		Brut04 = isnull(n04.Brut04,0),
		Net04 = isnull(n04.Net04,0),

		Brut05 = isnull(n05.Brut05,0),
		Net05 = isnull(n05.Net05,0),
		
		Brut06 = isnull(n06.Brut06,0),
		Net06 = isnull(n06.Net06,0),
		
		Brut07 = isnull(n07.Brut07,0),
		Net07 = isnull(n07.Net07,0),
		
		Brut08 = isnull(n08.Brut08,0),
		Net08 = isnull(n08.Net08,0),
		
		Brut09 = isnull(n09.Brut09,0),
		Net09 = isnull(n09.Net09,0),
		
		Brut10 = isnull(n10.Brut10,0),
		Net10 = isnull(n10.Net10,0),

		ct.Cotis_Periode
		
		--,Brut1011 = isnull(n1011.Brut1011,0),
		--Retraits1011 = isnull(n1011.Retraits1011,0),
		--Net1011 = isnull(n1011.Net1011,0)
		
	into #TMPResult
	from 
		#GrossANDNetUnitsCons t
		left join #tRepNewBeneficiary NB on t.repid = nb.repid
		left join #tRepOldBeneficiary OB on t.repid = ob.repid
		left join #tRepNewSubscriber NS on t.repid = ns.repid
		left join #tRepOldSubscriber OS on t.repid = os.repid
		left join #Cotis ct on ct.repid = t.repid
		--left join #tTIN TIN on t.repid = TIN.RepID
		--left join #tMntSouscrit MS on t.repid = MS.Repid
		left join #tAjoutUnite AU on t.repid = AU.RepID
		left join #tResilComplet RC on t.RepID = RC.RepID
		join Un_Rep Rep on t.repid = Rep.repid
		JOIN dbo.Mo_human HREP on t.repid = HREP.humanid
		join #AllRep RepDIR on t.repID = RepDIR.RepID
		join Un_Rep DIR on RepDIR.BossID = DIR.RepId
		JOIN dbo.Mo_human HDIR on DIR.repid = HDIR.humanid

		left join (
			select 	repid, net01 = sum(net_4 + net_8 + net_10), brut01 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_1 group by repid
			) n01 on t.repid = n01.repid
		left join (
			select 	repid, net02 = sum(net_4 + net_8 + net_10), brut02 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_2 group by repid
			) n02 on t.repid = n02.repid
		left join (
			select 	repid, net03 = sum(net_4 + net_8 + net_10), brut03 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_3 group by repid
			) n03 on t.repid = n03.repid
		left join (
			select 	repid, net04 = sum(net_4 + net_8 + net_10), brut04 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_4 group by repid
			) n04 on t.repid = n04.repid

		left join (
			select 	repid, net05 = sum(net_4 + net_8 + net_10), brut05 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_5 group by repid
			) n05 on t.repid = n05.repid
		left join (
			select 	repid, net06 = sum(net_4 + net_8 + net_10), brut06 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_6 group by repid
			) n06 on t.repid = n06.repid
		left join (
			select repid, net07 = sum(net_4 + net_8 + net_10), brut07 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_7 group by repid
			) n07 on t.repid = n07.repid
		left join (
			select repid, net08 = sum(net_4 + net_8 + net_10), brut08 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_8 group by repid
			) n08 on t.repid = n08.repid
		left join (
			select repid, net09 = sum(net_4 + net_8 + net_10), brut09 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_9 group by repid
			) n09 on t.repid = n09.repid
		left join (
			select repid, net10 = sum(net_4 + net_8 + net_10), brut10 = sum(brut_4 + brut_8 + brut_10) from #GrossANDNetUnits_10 group by repid
			) n10 on t.repid = n10.repid
		left join (
			select repid, brut1011 = sum(brut_4 + brut_8 + brut_10), Retraits1011 = sum(Retraits_4 + Retraits_8 + Retraits_10), net1011 = sum(net_4 + net_8 + net_10) from #GrossANDNetUnits_Concours group by repid
			) n1011 on t.repid = n1011.repid
			
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
		HDir.FirstName,
		HDir.LastName,
		
		isnull(AU.QteAjoutBrut,0),
		isnull(AU.QteAjoutResil,0),
		isnull(AU.QteAjoutNet,0),

		isnull(NbBenef,0), -- Nouveau Bénéf
		isnull(NbDepartBenef,0), -- Départ bénéf
		isnull(NbBenef,0) - isnull(NbDepartBenef,0), -- Nouveau bénéf net
		isnull(NbBenef_2A10,0), -- Nouveau Bénéf
		isnull(NbDepartBenef_2A10,0), -- Départ bénéf
		isnull(NbBenef_2A10,0) - isnull(NbDepartBenef_2A10,0), -- Nouveau bénéf net
		
		isnull(NbSousc,0), -- Nouveau Bénéf
		isnull(NbDepartSousc,0), -- Départ bénéf
		isnull(NbSousc,0) - isnull(NbDepartSousc,0), -- Nouveau bénéf net
		isnull(NbGrParent,0), -- Nouveau Bénéf
		isnull(NbDepartGrParent,0), -- Départ bénéf
		isnull(NbGrParent,0) - isnull(NbDepartGrParent,0), -- Nouveau bénéf net
		
		isnull(RC.NbResilComplete,0),

		isnull(n01.Net01,0),
		isnull(n02.Net02,0),
		isnull(n03.Net03,0),
		isnull(n04.Net04,0),
		
		isnull(n05.Net05,0),
		isnull(n06.Net06,0),
		isnull(n07.Net07,0),
		isnull(n08.Net08,0),
		isnull(n09.Net09,0),
		isnull(n10.Net10,0),
		
		isnull(n01.Brut01,0),
		
		isnull(n02.Brut02,0),
		
		isnull(n03.Brut03,0),
		
		isnull(n04.Brut04,0),

		isnull(n05.Brut05,0),
		
		isnull(n06.Brut06,0),
		
		isnull(n07.Brut07,0),
		
		isnull(n08.Brut08,0),
	
		isnull(n09.Brut09,0),
	
		isnull(n10.Brut10,0)
		,ct.Cotis_Periode
		
	order by

		HRep.LastName,
		HRep.firstName

	SELECT 
		RepCode,
		firstName,
		LastName,
		BusinessStart,

		DirFirstName = replace(DirFirstName,'Agence',''),
		DirLastName,

		NbBenef, -- Nouveau Bénéf
		NbDepartBenef, -- Départ bénéf
		NbBenefNet, -- Nouveau bénéf net

		QteAjoutUniteBrut,
		QteAjoutUniteResil,
		QteAjoutUniteNet,

		Net01,
		Net02,
		Net03,
		Net04,
		Net05,
		Net06,
		Net07,
		Net08,
		Net09,
		Net10,
		
		--jira ti-5468
		CONSTANCE = CASE WHEN BusinessStart < dateadd(YEAR,-9,@StartDate)/*jira ti-5468*/ /*'2004-10-01'*/ and (Net01>0 AND Net02 >0 AND Net03 >0 AND Net04>0 AND Net05>0 AND Net06>0 AND Net07>0 AND Net08>0 AND Net09>0 AND Net10>0)
						THEN  (Net01+ Net02 + Net03 + Net04+ Net05+ Net06+ Net07+ Net08+ Net09+ Net10) / 10
						ELSE 0
						END,
		Cotis_Periode
		
	FROM (

		select
			RepCode,
			firstName,
			LastName,
			BusinessStart,

			DirFirstName,
			DirLastName,

			NbBenef, -- Nouveau Bénéf
			NbDepartBenef, -- Départ bénéf
			NbBenefNet, -- Nouveau bénéf net

			QteAjoutUniteBrut,
			QteAjoutUniteResil,
			QteAjoutUniteNet,

			Net01,
			Net02,
			Net03,
			Net04,
			Net05,
			Net06,
			Net07,
			Net08,
			Net09,
			Net10 = Net10 * 52 / @Ratio,
			Cotis_Periode

		from #TMPResult t
		--left JOIN #TMPMntSouscrit ms ON t.repid = ms.repid

		UNION

		select

			Rep.RepCode,
			HREP.firstName,
			HREP.LastName,
			REP.BusinessStart,

			DirFirstName = HDIR.firstName,
			DirLastName = HDIR.Lastname,

			NbBenef = 0, -- Nouveau Bénéf
			NbDepartBenef = 0, -- Départ bénéf
			NbBenefNet = 0, -- Nouveau bénéf net

			QteAjoutUniteBrut = 0,
			QteAjoutUniteResil = 0,
			QteAjoutUniteNet = 0,

			Net01 =0,
			Net02 =0,
			Net03 =0,
			Net04 =0,
			Net05 =0,
			Net06 =0,
			Net07 =0,
			Net08 =0,
			Net09 =0,
			Net10 =0,
			Cotis_Periode = 0
			
		from 
			#AllRep AR
			join Un_Rep Rep on AR.repid = Rep.repid
			JOIN dbo.Mo_human HREP on Rep.repid = HREP.humanid
 			join Un_Rep DIR on AR.BossID = DIR.RepId
			JOIN dbo.Mo_human HDIR on DIR.repid = HDIR.humanid
		where AR.repid not in (select repid from #TMPResult)
		) v
	WHERE
		-- jira ti-9148 : (retirer les directeur adjoints -- Steve Blais #7805 et Chantal Jobin #7186
		v.RepCode NOT IN (
				6158	,	--	149497	Carole Marchand
				6987	,	--	422223	Line Durivage
				7186	,	--	466100	Chantal Jobin
				7361	,	--	500292	Myriam Derome
				7805	,	--	629154	Steve Blais
				7862	,	--	655109	Anne LeBlanc-Levesque
				7923	,	--	676177	Amélie Rancourt-Fortin
				70067		--	702402	Véronic Bénard
				)
	order by
		RepCode,
		LastName,
		firstName

set arithabort off

END