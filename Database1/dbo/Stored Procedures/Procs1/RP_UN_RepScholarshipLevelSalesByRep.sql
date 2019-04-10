/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepScholarshipLevelSalesByRep
Description         :	Procédure stockée du rapport : Ventes des représentants et agences par niveau de scolarité
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-08	Bruno Lapointe		Optimisation.
										2010-02-08	Donald Huppé			Inscrire Reeeflex 2010 pour le différencier de Reeeflex 9demande de I Biron) 
										2010-05-14	Donald Huppé			Comme S.ScholarshipLevelID n'est plus utilisé, alors :
																						Prendre les niveau de scolarité du souscripteur parent dans tblCONV_ProfilSouscripteur
																						Si le souscripteur est <> de parent (ex : Grand-Parent), alors c'est inconnu.
										2014-09-12	Pierre-Luc Simard	Récupérer uniquement le dernier profil souscripteur
                                        2018-11-08  Pierre-Luc Simard   Utilisation du nom de plan complet

exec RP_UN_RepScholarshipLevelSalesByRep 1, '2010-01-01','2010-05-14',1,0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepScholarshipLevelSalesByRep] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@EndPeriodAgency BIT, -- Indique s'il faut obtenir l'agence active à la fin de la période, sinon on doit obtenir l'agence à la date InForce
	@RepID INTEGER ) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE
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
		SELECT UR.UnitID,
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
		M.UnitID,
		M.UnitQty,
		M.RepID,
		BossID = MAX(RBH.BossID),
		M.ModalID,
		M.ConventionID
	INTO #Unit
	FROM (
		SELECT 
			U.UnitID,
			UnitQty = UN.UnitQty,
			U.RepID,
			U.InforceDate,
			U.ConventionID,
			U.ModalID,
			RepBossPct = MAX(RBH.RepBossPct)
		FROM #UnitNet UN
		JOIN dbo.Un_Unit U ON UN.UnitID = U.UnitID
		LEFT JOIN Un_RepBossHist RBH 	ON RBH.RepID = U.RepID
												AND CASE
														WHEN @EndPeriodAgency = 1 THEN @EndDate
														ELSE U.InforceDate
													END >= RBH.StartDate 
												AND ((CASE
														WHEN @EndPeriodAgency = 1 THEN @EndDate
														ELSE U.InforceDate
														END <= RBH.EndDate) OR (RBH.EndDate IS NULL)) 
												AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			U.UnitID, 
			U.RepID, 
			U.InforceDate, 
			UN.UnitQty, 
			U.ModalID, 
			U.ConventionID
		) M
	LEFT JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID 
												AND RBH.RepBossPct = M.RepBossPct
												AND CASE
														WHEN @EndPeriodAgency = 1 THEN @EndDate
														ELSE M.InforceDate
													END >= RBH.StartDate
												AND ((CASE
													WHEN @EndPeriodAgency = 1 THEN @EndDate
													ELSE M.InforceDate
													END <= RBH.EndDate) OR (RBH.EndDate IS NULL)) 
												AND RBH.RepRoleID = 'DIR'
	WHERE ISNULL(M.RepID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), M.RepID),0) -- selon le rep
		OR ISNULL(RBH.BossID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), RBH.BossID),0) -- selon le rep
	GROUP BY
		M.UnitID,
		M.UnitQty,
		M.RepID,
		M.ModalID,
		M.ConventionID
/*
	-- Totaux détaillés par scolarité et régime
	SELECT
		M.PlanID,
		U.RepID,
		U.BossID,
		-- Détail pour secondaire
		SECUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'SEC' THEN U.UnitQty ELSE 0 END),
		SECCountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'SEC' THEN 1 ELSE 0 END),
		-- Détail pour colégiale
		COLUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'COL' THEN U.UnitQty ELSE 0 END),
		COLCountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'COL' THEN 1 ELSE 0 END),
		-- Détail pour universitaire
		UNIUnitQty = SUM(CASE WHEN S.ScholarshipLevelID = 'UNI' THEN U.UnitQty ELSE 0 END),
		UNICountUnit = SUM(CASE WHEN S.ScholarshipLevelID = 'UNI' THEN 1 ELSE 0 END) ,
		-- Détail pour inconnu
		UNKUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK') THEN U.UnitQty ELSE 0 END) ,
		UNKCountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'UNK') THEN 1 ELSE 0 END) ,
		-- Détail pour aucun
		NDIUnitQty = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') THEN U.UnitQty ELSE 0 END),
		NDICountUnit = SUM(CASE WHEN (S.ScholarshipLevelID = 'NDI') THEN 1 ELSE 0 END),
		-- Détail total
		TOTUnitQty = SUM(U.UnitQty),
		TOTCountUnit = SUM(1) 
	INTO #UnitDtl
	FROM 
		#Unit U
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	GROUP BY 
		M.PlanID, 
		U.RepID, 
		U.BossID
	*/	
		
	SELECT
		M.PlanID,
		U.RepID,
		U.BossID,
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
	FROM 
		#Unit U
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
	GROUP BY 
		M.PlanID, 
		U.RepID, 
		U.BossID

	-- Résultat du rapport
	SELECT
		OrderBy = 1,
		P.PlanID,
        PlanDesc = P.NomPlan,
		R.RepCode,
		U.RepID,
		U.BossID,
		RepName = H.FirstName + ' ' + H.LastName,
		AgencyName = A.FirstName + ' ' + A.LastName,
		RepStatus = 
			CASE
			    WHEN R.BusinessEnd <= GetDate() THEN 'Inactif'
			ELSE 'Actif'
			END,
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
		TOTUnitQtyPct = CASE WHEN UR.UnitQtyTotal <> 0 THEN U.TOTUnitQty / UR.UnitQtyTotal * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité scolarité inconnu par rapport au total
		UNKCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CAST(U.UNKCountUnit AS DECIMAL)/ U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité sans scolarité par rapport au total
		NDICountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CAST(U.NDICountUnit AS DECIMAL)/ U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du secondaire par rapport au total
		SECCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CAST(U.SECCountUnit AS DECIMAL) / U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du colégial par rapport au total
		COLCountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CAST(U.COLCountUnit AS DECIMAL) / U.TOTCountUnit * 100 ELSE 0 END ,
		-- pourcentage du nombre de groupe d'unité de l'université par rapport au total
		UNICountUnitPct = CASE WHEN U.TOTCountUnit <> 0 THEN CAST(U.UNICountUnit AS DECIMAL) / U.TOTCountUnit * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du régime par rapport au total représentant
		TOTCountUnitPct = CASE WHEN UR.CountUnitTotal <> 0 THEN CAST(U.TOTCountUnit AS DECIMAL) / UR.CountUnitTotal * 100 ELSE 0 END
	FROM #UnitDtl U
	JOIN (
		SELECT 
			RepID, 
			UnitQtyTotal = SUM(TOTUnitQty) , 
			CountUnitTotal = SUM(TOTCountUnit)
		FROM #UnitDtl
		GROUP BY RepID
		) UR ON UR.RepID = U.RepID
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = U.RepID
	JOIN dbo.Mo_Human A ON A.HumanID = U.BossID
	JOIN Un_Plan P ON P.PlanID = U.PlanID
	-----
	UNION
	-----
	SELECT
		OrderBy = 2,
		PlanID = 0,
		PlanDesc = 'Total des régimes',
		R.RepCode,
		U.RepID,
		U.BossID,
		H.FirstName + ' ' + H.LastName AS RepName ,
		A.FirstName + ' ' + A.LastName AS AgencyName,
		RepStatus = 
			CASE
				WHEN (R.BusinessEnd <= GETDATE()) THEN 'Inactif'
			ELSE 'Actif'
			END,
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
		TOTUnitQtyPct = CASE WHEN SUM(UR.UnitQtyTotal) <> 0 THEN SUM(U.TOTUnitQty) / SUM(UR.UnitQtyTotal) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité scolarité inconnu par rapport au total
		UNKCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CAST(SUM(U.UNKCountUnit) AS DECIMAL)/ SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité sans scolarité par rapport au total
		NDICountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CAST(SUM(U.NDICountUnit) AS DECIMAL)/ SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du secondaire par rapport au total
		SECCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CAST(SUM(U.SECCountUnit) AS DECIMAL) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du colégial par rapport au total
		COLCountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CAST(SUM(U.COLCountUnit) AS DECIMAL) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité de l'université par rapport au total
		UNICountUnitPct = CASE WHEN SUM(U.TOTCountUnit) <> 0 THEN CAST(SUM(U.UNICountUnit) AS DECIMAL) / SUM(U.TOTCountUnit) * 100 ELSE 0 END,
		-- pourcentage du nombre de groupe d'unité du régime par rapport au total représentant
		TOTCountUnitPct = CASE WHEN SUM(UR.CountUnitTotal) <> 0 THEN CAST(SUM(U.TOTCountUnit) AS DECIMAL) / SUM(UR.CountUnitTotal) * 100 ELSE 0 END
	FROM #UnitDtl U
	JOIN (
		SELECT 
			RepID, 
			UnitQtyTotal = SUM(TOTUnitQty), 
			CountUnitTotal = SUM(TOTCountUnit)
		FROM #UnitDtl
		GROUP BY RepID
		) UR ON UR.RepID = U.RepID
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = U.RepID
	JOIN dbo.Mo_Human A ON A.HumanID = U.BossID
	GROUP BY
		R.RepCode,
		U.RepID,
		U.BossID,
		H.FirstName,
		H.LastName,
		A.FirstName,
		A.LastName,
		R.BusinessEnd
	ORDER BY
		AgencyName,
		U.BossID,
		RepStatus,
		RepName,
		U.RepID,
		OrderBy,
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
				'Ventes des représentants et agences par niveau de scolarité',
				'RP_UN_RepScholarshipLevelSalesByRep',
				'EXECUTE RP_UN_RepScholarshipLevelSalesByRep @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @EndPeriodAgency = '+CAST(@EndPeriodAgency AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)

	-- FIN DES TRAITEMENTS
	RETURN 0
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepScholarshipLevelSalesByRep] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@StartDate = '2008-05-01', -- Date de début de la période
	@EndDate = '2008-05-31', -- Date de fin de la période
	@EndPeriodAgency = 1, -- Indique s'il faut obtenir l'agence active à la fin de la période (1), sinon on doit obtenir l'agence à la date InForce (0)
	@RepID = 149653 -- Limiter les résultats selon un représentant, 0 pour tous, 149653 pour Claude Cossette
*/