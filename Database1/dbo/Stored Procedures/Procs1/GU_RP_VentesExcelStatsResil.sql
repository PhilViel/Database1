/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelStatsResil
Description         :	Statistiques sur les résiliations en groupes d'unités pour fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-17 	
****************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelStatsResil]
	(
	@StartDate DATETIME, 	-- Date de début de la période
	@EndDate DATETIME  	-- Date de fin de la période
	)
AS
BEGIN
	SET NOCOUNT ON

	SELECT -- Unités signées (Nombre de groupe d'unités)
		0 AS Ordre,
		'Signé' AS UnitStateName,
		TEST = Sum(CASE WHEN [SignatureDate] Between DATEADD (YEAR, -1, @StartDate) And CAST(YEAR(@EndDate)-1 AS varchar(4)) + '-12-31' THEN 1 ELSE 0 END), 
		TEST2 = Sum(CASE WHEN [SignatureDate] Between DATEADD (YEAR, -1, @StartDate) And DATEADD (YEAR, -1, @EndDate) THEN 1 ELSE 0 END), 
		TEST3 = Sum(CASE WHEN [SignatureDate] Between @StartDate And @EndDate THEN 1 ELSE 0 END)
	FROM Un_Unit	
	UNION
	SELECT -- Résiliations avant le délai de 60 jours (Nombre de groupe d'unités)
		1 AS Ordre,
		Un_UnitState.UnitStateName, 
		TEST = Sum(CASE WHEN [StartDate] Between DATEADD (YEAR, -1, @StartDate) And CAST(YEAR(@EndDate)-1 AS varchar(4)) + '-12-31' THEN 1 ELSE 0 END), 
		TEST2 = Sum(CASE WHEN [StartDate] Between DATEADD (YEAR, -1, @StartDate) And DATEADD (YEAR, -1, @EndDate) THEN 1 ELSE 0 END), 
		TEST3 = Sum(CASE WHEN [StartDate] Between @StartDate And @EndDate THEN 1 ELSE 0 END)
	FROM Un_UnitUnitState 
	INNER JOIN Un_UnitState ON Un_UnitUnitState.UnitStateID = Un_UnitState.UnitStateID
	GROUP BY Un_UnitState.UnitStateName
	HAVING (Un_UnitState.UnitStateName='Résiliation frais et épargne') 
		OR (Un_UnitState.UnitStateName='Résiliation complète')
	UNION
	SELECT -- Résiliations après le délai de 60 jours (Nombre de groupe d'unités)
		2 AS Ordre,
		Un_UnitState.UnitStateName, 
		TEST = Sum(CASE WHEN [StartDate] Between DATEADD (YEAR, -1, @StartDate) And CAST(YEAR(@EndDate)-1 AS varchar(4)) + '-12-31' THEN 1 ELSE 0 END), 
		TEST2 = Sum(CASE WHEN [StartDate] Between DATEADD (YEAR, -1, @StartDate) And DATEADD (YEAR, -1, @EndDate) THEN 1 ELSE 0 END), 
		TEST3 = Sum(CASE WHEN [StartDate] Between @StartDate And @EndDate THEN 1 ELSE 0 END)
	FROM Un_UnitUnitState 
	INNER JOIN Un_UnitState ON Un_UnitUnitState.UnitStateID = Un_UnitState.UnitStateID
	GROUP BY Un_UnitState.UnitStateName
	HAVING (Un_UnitState.UnitStateName='Résiliation épargne') 
		OR (Un_UnitState.UnitStateName='Résiliation valeur 0')

END

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_VentesExcelStatsResil] TO [Rapport]
    AS [dbo];

