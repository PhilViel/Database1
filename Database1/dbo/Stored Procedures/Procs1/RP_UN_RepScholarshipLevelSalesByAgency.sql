/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepScholarshipLevelSalesByAgency
Description         :	Procédure stockée du rapport : Ventes des représentants et agences par niveau de scolarité (Agences)
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-08	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepScholarshipLevelSalesByAgency](	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
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
		FROM (
			-- Unit Net de la période
			SELECT
				U.UnitID,
				UnitQty = ISNULL(UB.UnitQty,0) - ISNULL(R.UnitQty,0)
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
			) UN
		JOIN dbo.Un_Unit U ON UN.UnitID = U.UnitID
		LEFT JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID 
											AND U.InforceDate >= RBH.StartDate 
											AND (U.InforceDate <= RBH.EndDate OR RBH.EndDate IS NULL) 
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
										AND M.InforceDate >= RBH.StartDate 
										AND (M.InforceDate <= RBH.EndDate OR RBH.EndDate IS NULL) 
										AND RBH.RepRoleID = 'DIR'
	WHERE ISNULL(M.RepID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), M.RepID),0) -- selon le rep
		OR ISNULL(RBH.BossID,0) = ISNULL(ISNULL(NULLIF(@RepID,0), RBH.BossID),0) -- selon le rep
	GROUP BY
		M.UnitID,
		M.UnitQty,
		M.RepID,
		M.ModalID,
		M.ConventionID

	-- Résultat du rapport
	SELECT
		U.BossID,
		AgencyName = A.FirstName + ' ' + A.LastName 
	FROM #Unit U
	JOIN dbo.Mo_Human A ON A.HumanID = U.BossID
	GROUP BY
		A.LastName,
		A.FirstName,
		U.BossID
	ORDER BY
		A.LastName,
		A.FirstName,
		U.BossID

	DROP TABLE #UnitBrut
	DROP TABLE #Reduction
	DROP TABLE #Unit
	
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
				'Ventes des représentants et agences par niveau de scolarité (Agences)',
				'RP_UN_RepScholarshipLevelSalesByAgency',
				'EXECUTE RP_UN_RepScholarshipLevelSalesByAgency @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @RepID = '+CAST(@RepID AS VARCHAR)

	-- FIN DES TRAITEMENTS
	RETURN 0
END


