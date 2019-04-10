/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelStatsRepUnitPlan
Description         :	Statistiques des ventes par agence et par plan pour fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-11 	
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelStatsRepUnitPlan]
	(
	@StartDate DATETIME, 	-- Date de début de la période
	@EndDate DATETIME  	-- Date de fin de la période
	)
AS
BEGIN
	SET NOCOUNT ON

	-- Table temporaire contenant le nombre d'unités réduit dans la période demandée
	CREATE TABLE #tUnitReductPeriod (
		UnitID INTEGER PRIMARY KEY,
		UnitReductPeriod MONEY NOT NULL )
	INSERT INTO #tUnitReductPeriod
	SELECT 	
		Un_UnitReduction.UnitID, 
		Sum(Un_UnitReduction.UnitQty) AS Unit_Reduct
	FROM Un_UnitReduction
	WHERE Un_UnitReduction.ReductionDate Between @StartDate And @EndDate
	GROUP BY Un_UnitReduction.UnitID

	-- Table temporaire contenant le nombre d'unités brutes
	CREATE TABLE #tUnitBrute (
		UnitID INTEGER PRIMARY KEY,
		UnitBrute MONEY NOT NULL )
	INSERT INTO #tUnitBrute
	SELECT 	
		U.UnitID, 
		UnitQty + ISNULL(UnitReduct,0) AS Unit_Brute
	FROM dbo.Un_Unit AS U 
	LEFT JOIN 
		(
		SELECT 
			Un_UnitReduction.UnitID, 
			Sum(Un_UnitReduction.UnitQty) AS UnitReduct
		FROM Un_UnitReduction
		GROUP BY 
			Un_UnitReduction.UnitID
		) AS UR ON U.UnitID = UR.UnitID
	WHERE U.ValidationConnectID IS NOT NULL AND U.dtFirstDeposit Between @StartDate And @EndDate
		
	-- Table temporaire contenant pour chaque groupe d'unité, le plus grand pourcentage d'un directeur sur un représentant, à la date d'entrée en vigueur
	CREATE TABLE #tUnitDirPct (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER NOT NULL,
		InForceDate DATETIME NULL,
		MaxDirPct MONEY NOT NULL )
	INSERT INTO #tUnitDirPct
	SELECT 
		Un_Unit.UnitID, 
		Un_Unit.RepID, 
		Un_Unit.InForceDate, 
		Max(Un_RepBossHist.RepBossPct) AS MaxDirPct
	FROM dbo.Un_Unit 
	LEFT JOIN Un_RepBossHist ON Un_Unit.RepID = Un_RepBossHist.RepID
	WHERE (((Un_RepBossHist.RepRoleID)='DIR') AND ((Un_RepBossHist.StartDate)<=Un_Unit.InForceDate) AND ((Un_RepBossHist.EndDate) Is Null Or (Un_RepBossHist.EndDate)>=Un_Unit.InForceDate))
	GROUP BY 
		Un_Unit.UnitID, 
		Un_Unit.RepID, 
		Un_Unit.InForceDate

	CREATE TABLE #tUnitRepDir (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER NOT NULL,
		InForceDate DATETIME NULL,
		MaxDirID INTEGER NOT NULL )
	INSERT INTO #tUnitRepDir
	SELECT 
		#tUnitDirPct.UnitID, 
		#tUnitDirPct.RepID, 
		#tUnitDirPct.InForceDate, 
		Max(Un_RepBossHist.BossID) AS MaxDirID 
	FROM #tUnitDirPct 
	LEFT JOIN Un_RepBossHist ON (#tUnitDirPct.RepID = Un_RepBossHist.RepID) AND (#tUnitDirPct.MaxDirPct = Un_RepBossHist.RepBossPct)
	WHERE (((Un_RepBossHist.RepRoleID)='DIR') AND ((Un_RepBossHist.StartDate)<=#tUnitDirPct.InForceDate) AND ((Un_RepBossHist.EndDate) Is Null Or (Un_RepBossHist.EndDate)>=#tUnitDirPct.InForceDate))
	GROUP BY 
		#tUnitDirPct.UnitID, 
		#tUnitDirPct.RepID, 
		#tUnitDirPct.InForceDate
	
	SELECT 	
		Mo_Human.LastName, 
		Mo_Human.FirstName, 
		Un_Rep.RepCode, 
		Mo_Human_1.LastName, 
		Mo_Human_1.FirstName, 
		Un_Plan.PlanDesc, 
		Sum(ISNULL(#tUnitBrute.UnitBrute,0)) AS SommeUnitBrute, 
		Sum(ISNULL(#tUnitReductPeriod.UnitReductPeriod,0)) AS SommeUnitReductPeriod, 
		Sum(ISNULL(#tUnitBrute.UnitBrute,0)-ISNULL(#tUnitReductPeriod.UnitReductPeriod,0)) AS SommeUnitNette 
	FROM #tUnitRepDir
	LEFT JOIN #tUnitBrute ON #tUnitRepDir.UnitID = #tUnitBrute.UnitID
	LEFT JOIN #tUnitReductPeriod ON #tUnitRepDir.UnitID = #tUnitReductPeriod.UnitID 
	INNER JOIN dbo.Un_Unit ON #tUnitRepDir.UnitID = Un_Unit.UnitID
	INNER JOIN dbo.Un_Convention ON Un_Unit.ConventionID = Un_Convention.ConventionID
	INNER JOIN Un_Plan ON Un_Convention.PlanID = Un_Plan.PlanID
	INNER JOIN dbo.Mo_Human AS Mo_Human_1 ON #tUnitRepDir.MaxDirID = Mo_Human_1.HumanID
	INNER JOIN Un_Rep ON #tUnitRepDir.RepID = Un_Rep.RepID
	INNER JOIN dbo.Mo_Human ON Un_Rep.RepID = Mo_Human.HumanID
	GROUP BY 
		Mo_Human.LastName, 
		Mo_Human.FirstName, 
		Un_Rep.RepCode, 	
		Mo_Human_1.LastName, 
		Mo_Human_1.FirstName, 
		Un_Plan.PlanDesc
	ORDER BY 
		Mo_Human.LastName, 
		Mo_Human.FirstName, 	
		Un_Rep.RepCode, 	
		Mo_Human_1.LastName, 
		Mo_Human_1.FirstName, 
		Un_Plan.PlanDesc
	
	DROP TABLE #tUnitReductPeriod
	DROP TABLE #tUnitBrute
	DROP TABLE #tUnitDirPct
	DROP TABLE #tUnitRepDir

END



GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_VentesExcelStatsRepUnitPlan] TO [Rapport]
    AS [dbo];

