/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepScholarshipLevelSalesTotal
Description         :	Procédure stockée du rapport : Ventes des représentants et agences par niveau de scolarité (Total)
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-08	Bruno Lapointe		Optimisation.
										2008-05-09	JJL						Supprimer OrderBy
										2010-02-08	Donald Huppé			Inscrire Reeeflex 2010 pour le différencier de Reeeflex 9demande de I Biron) 
										2010-05-14	Donald Huppé			Comme S.ScholarshipLevelID n'est plus utilisé, alors :
																						Prendre les niveau de scolarité du souscripteur parent dans tblCONV_ProfilSouscripteur
																						Si le souscripteur est <> de parent (ex : Grand-Parent), alors c'est inconnu.
										2014-09-12	Pierre-Luc Simard	Récupérer uniquement le dernier profil souscripteur
                                        2018-11-08  Pierre-Luc Simard   Utilisation du nom de plan complet
																	
exec RP_UN_RepScholarshipLevelSalesTotal 1,'2010-01-01','2010-05-14',0										
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepScholarshipLevelSalesTotal](	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@RepID INTEGER ) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE 
		@UnitQtyTotal MoPct,
		@CountUnitTotal MoPct,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	-- unité brute de la période
	SELECT
		U.UnitID,
		UnitQty = U.UnitQty + ISNULL(UR.UnitQty,0) 
	INTO #UnitBrut
	FROM dbo.Un_Unit U
	LEFT JOIN (	
		SELECT
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	WHERE U.dtFirstDeposit >= @StartDate
		AND U.dtFirstDeposit < @EndDate+1

	-- Résiliation de la période
	SELECT
		UR.UnitID,
		UnitQty = SUM(UR.UnitQty)
	INTO #Reduction
	FROM Un_UnitReduction UR
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE UR.FeeSumByUnit < M.FeeByUnit 
		AND UR.ReductionDate >= @StartDate
		AND UR.ReductionDate < @EndDate + 1
	GROUP BY UR.UnitID

	-- Unit Net de la période
	SELECT
		U.UnitID,
		UnitQty = ISNULL(UB.UnitQty,0) - ISNULL(R.UnitQty,0)
	INTO #UnitNet
	FROM (
		SELECT UnitID
		FROM #UnitBrut
		-----
		UNION
		-----
		SELECT UnitID
		FROM #Reduction
		) U
	LEFT JOIN #UnitBrut UB ON U.UnitID = UB.UnitID
	LEFT JOIN #Reduction R ON R.UnitID = U.UnitID
	WHERE ISNULL(UB.UnitQty,0) - ISNULL(R.UnitQty,0) <> 0

	-- Détail des unités
	SELECT
		UN.UnitID,
		UN.UnitQty,
		U.ModalID,
		U.ConventionID
	INTO #Unit
	FROM #UnitNet UN
	JOIN dbo.Un_Unit U ON UN.UnitID = U.UnitID
/*
	-- Totaux détaillés par scolarité et régime
	SELECT
		M.PlanID,
		-- Détail pour secondaire
		SECUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'SEC' THEN U.UnitQty ELSE 0 END),
		SECCountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'SEC' THEN 1 ELSE 0 END),
		-- Détail pour colégiale
		COLUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'COL' THEN U.UnitQty ELSE 0 END),
		COLCountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'COL' THEN 1 ELSE 0 END) ,
		-- Détail pour universitaire
		UNIUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'UNI' THEN U.UnitQty ELSE 0 END),
		UNICountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'UNI' THEN 1 ELSE 0 END) ,
		-- Détail pour inconnu
		UNKUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK') THEN U.UnitQty ELSE 0 END),
		UNKCountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK') THEN 1 ELSE 0 END),
		-- Détail pour aucun
		NDIUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') THEN U.UnitQty ELSE 0 END),
		NDICountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') THEN 1 ELSE 0 END),
		-- Détail total
		TOTUnitQty = SUM(U.UnitQty),
		TOTCountUnit = SUM(1)
	INTO #UnitDtl
	FROM #Unit U
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	LEFT JOIN Un_RepBossHist BH ON S.RepID = BH.RepID AND @RepID > 0
	WHERE ISNULL(S.RepID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), S.RepID),0) -- selon le rep
		OR ISNULL(BH.BossID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), BH.BossID),0) -- selon le directeur
	GROUP BY M.PlanID
*/	

	-- Totaux détaillés par scolarité et régime
	SELECT
		M.PlanID,
		-- Détail pour secondaire
		SECUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'SEC') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 3) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 3) THEN U.UnitQty ELSE 0 END),
		SECCountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'SEC') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 3) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 3) THEN 1 ELSE 0 END),
		-- Détail pour colégiale
		COLUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'COL') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 4) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 4) THEN U.UnitQty ELSE 0 END),
		COLCountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'COL') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 4) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 4) THEN 1 ELSE 0 END),
		-- Détail pour universitaire
		UNIUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNI') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 5) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 5) THEN U.UnitQty ELSE 0 END),
		UNICountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNI') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 5) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 5) THEN 1 ELSE 0 END) ,
		-- Détail pour inconnu
		UNKUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK' and tiRelationshipTypeID <> 1) OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 1) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 1) THEN U.UnitQty ELSE 0 END) ,
		UNKCountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK' and tiRelationshipTypeID <> 1) OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 1) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 1) THEN 1 ELSE 0 END) ,
		-- Détail pour aucun
		NDIUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 2) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 2) THEN U.UnitQty ELSE 0 END),
		NDICountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') OR (tiRelationshipTypeID = 1 and sexid = 'M' and iIDNiveauEtudePere = 2) OR (tiRelationshipTypeID = 1 and sexid = 'F' and iIDNiveauEtudeMere = 2) THEN 1 ELSE 0 END),
		-- Détail total
		TOTUnitQty = SUM(U.UnitQty),
		TOTCountUnit = SUM(1) 
	INTO #UnitDtl
	FROM #Unit U
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN dbo.Mo_Human H on S.SubscriberID = H.Humanid
	JOIN tblCONV_ProfilSouscripteur PS ON PS.iID_Souscripteur = C.SubscriberID AND PS.DateProfilInvestisseur = (
		SELECT	
			MAX(PSM.DateProfilInvestisseur)
		FROM tblCONV_ProfilSouscripteur PSM
		WHERE PSM.iID_Souscripteur = PS.iID_Souscripteur
			AND PSM.DateProfilInvestisseur <= GETDATE()
		)

	LEFT JOIN Un_RepBossHist BH ON S.RepID = BH.RepID AND @RepID > 0
	WHERE ISNULL(S.RepID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), S.RepID),0) -- selon le rep
		OR ISNULL(BH.BossID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), BH.BossID),0) -- selon le directeur
	GROUP BY M.PlanID

	SELECT 
		@UnitQtyTotal = SUM(TOTUnitQty), 
		@CountUnitTotal = SUM(TOTCountUnit)
	FROM #UnitDtl
	
	-- Résultat du rapport
	SELECT
		OrderBy = 1,
		P.PlanID,
        PlanDesc = P.NomPlan,
		-- nombre d'unité
		U.UNKUnitQty,
		U.SECUnitQty,
		U.COLUnitQty,
		U.UNIUnitQty,
		U.NDIUnitQty,
		U.TOTUnitQty,
		-- nombre de groupe d'unité
		U.UNKCountUnit,
		U.SECCountUnit,
		U.COLCountUnit,
		U.UNICountUnit,
		U.NDICountUnit,
		U.TOTCountUnit,
		-- pourcentage du nombre d'unité scolarité inconnu par rapport au total
		UNKUnitQtyPct = CASE WHEN U.TOTUnitQty <> 0 THEN U.UNKUnitQty / U.TOTUnitQty * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du secondaire par rapport au total
		NDIUnitQtyPct = CASE WHEN U.TOTUnitQty <> 0 THEN U.NDIUnitQty / U.TOTUnitQty * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du secondaire par rapport au total
		SECUnitQtyPct = CASE WHEN U.TOTUnitQty <> 0 THEN U.SECUnitQty / U.TOTUnitQty * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du colégial par rapport au total
		COLUnitQtyPct = CASE WHEN U.TOTUnitQty <> 0 THEN U.COLUnitQty / U.TOTUnitQty * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité de l'université par rapport au total
		UNIUnitQtyPct = CASE WHEN U.TOTUnitQty <> 0 THEN U.UNIUnitQty / U.TOTUnitQty * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du régime par rapport au total représentant
		TOTUnitQtyPct = CASE WHEN @UnitQtyTotal <> 0 THEN U.TOTUnitQty / @UnitQtyTotal * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité scolarité inconnu par rapport au total
		UNKCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CONVERT(decimal, U.UNKCountUnit)/ U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité sans scolarité par rapport au total
		NDICountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CONVERT(decimal, U.NDICountUnit)/ U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du secondaire par rapport au total
		SECCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CONVERT(decimal, U.SECCountUnit) / U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du colégial par rapport au total
		COLCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CONVERT(decimal, U.COLCountUnit) / U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité de l'université par rapport au total
		UNICountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CONVERT(decimal, U.UNICountUnit) / U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du régime par rapport au total représentant
		TOTCountUnitPct = CASE WHEN @CountUnitTotal <> 0 THEN CONVERT(decimal, U.TOTCountUnit) / @CountUnitTotal * 100 ELSE 0 END
	FROM #UnitDtl U
	JOIN Un_Plan P ON P.PlanID = U.PlanID
	-----
	UNION
	-----
	SELECT
		OrderBy = 2 ,
		0,
		'Total des régimes',
		-- nombre d'unité
		SUM(U.UNKUnitQty),
		SUM(U.SECUnitQty),
		SUM(U.COLUnitQty),
		SUM(U.UNIUnitQty),
		SUM(U.NDIUnitQty),
		SUM(U.TOTUnitQty),
		-- nombre de groupe d'unité
		SUM(U.UNKCountUnit),
		SUM(U.SECCountUnit),
		SUM(U.COLCountUnit),
		SUM(U.UNICountUnit),
		SUM(U.NDICountUnit),
		SUM(U.TOTCountUnit),
		-- pourcentage du nombre d'unité scolarité inconnu par rapport au total
		UNKUnitQtyPct = CASE WHEN SUM(U.TOTUnitQty) <> 0 THEN SUM(U.UNKUnitQty) / SUM(U.TOTUnitQty) * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du secondaire par rapport au total
		NDIUnitQtyPct = CASE WHEN SUM(U.TOTUnitQty) <> 0 THEN SUM(U.NDIUnitQty) / SUM(U.TOTUnitQty) * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du secondaire par rapport au total
		SECUnitQtyPct = CASE WHEN SUM(U.TOTUnitQty) <> 0 THEN SUM(U.SECUnitQty) / SUM(U.TOTUnitQty) * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du colégial par rapport au total
		COLUnitQtyPct = CASE WHEN SUM(U.TOTUnitQty) <> 0 THEN SUM(U.COLUnitQty) / SUM(U.TOTUnitQty) * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité de l'université par rapport au total
		UNIUnitQtyPct = CASE WHEN SUM(U.TOTUnitQty) <> 0 THEN SUM(U.UNIUnitQty) / SUM(U.TOTUnitQty) * 100 ELSE 0 END,
		-- pourcentage du nombre d'unité du régime par rapport au total représentant
		TOTUnitQtyPct = CASE WHEN @UnitQtyTotal <> 0 THEN SUM(U.TOTUnitQty) / @UnitQtyTotal * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité scolarité inconnu par rapport au total
		UNKCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CONVERT(decimal, SUM(U.UNKCountUnit))/ SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité sans scolarité par rapport au total
		NDICountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CONVERT(decimal, SUM(U.NDICountUnit))/ SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du secondaire par rapport au total
		SECCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CONVERT(decimal, SUM(U.SECCountUnit)) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du colégial par rapport au total
		COLCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CONVERT(decimal, SUM(U.COLCountUnit)) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité de l'université par rapport au total
		UNICountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CONVERT(decimal, SUM(U.UNICountUnit)) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du régime par rapport au total représentant
		TOTCountUnitPct = CASE WHEN @CountUnitTotal <> 0 THEN CONVERT(decimal, SUM(U.TOTCountUnit)) / @CountUnitTotal * 100 ELSE 0 END
	FROM #UnitDtl U
	ORDER BY 
		OrderBy, --P.OrderBy, 2008-05-09, JJL, Supprimer OrderBy
		P.NomPlan
	
	DROP TABLE #UnitBrut
	DROP TABLE #Reduction
	DROP TABLE #UnitNet
	DROP TABLE #Unit
	DROP TABLE #UnitDtl
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Ventes des représentants et agences par niveau de scolarité (Total)',
				'RP_UN_RepScholarshipLevelSalesTotal',
				'EXECUTE RP_UN_RepScholarshipLevelSalesTotal @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @RepID = '+CAST(@RepID AS VARCHAR)

	-- FIN DES TRAITEMENTS
	RETURN 0
END

/*  Sequence de test - par: JJL - 09-05-2008
	exec [dbo].[RP_UN_RepScholarshipLevelSalesTotal]
	@ConnectID = 1, -- ID de connexion de l'usager
	@StartDate = '2008-01-01', -- Date de début de l'interval
	@EndDate ='2008-05-31', -- Date de fin de l'interval
	@RepID = 149653 -- ID unique du représentant, 0 pour tous, 149653 pour Claude Cossette
*/