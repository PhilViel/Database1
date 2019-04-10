/****************************************************************************************************
	Donne la liste des directeurs qui ont été actif dans une période
 ******************************************************************************
	2004-06-10 Bruno Lapointe
		Création Point 13.01.04.03 (1.1)
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_BossInPeriod](
	@RepID INTEGER, -- ID Unique du représentant, si tous = 0
	@StartDate DATETIME, -- Date de début de la période
	@EndDate DATETIME) -- Date de fin de la période
AS
BEGIN
	IF NOT EXISTS ( -- Si ID nest pas celui d'un rep on cancel le filtre
			SELECT 
				RepID
			FROM Un_Rep	
			WHERE RepID = @RepID)
		SET @RepID = 0

	SELECT DISTINCT
		LH.RepID,
		RepName = R.LastName+', '+R.FirstName
	FROM Un_RepLevelHist LH
	JOIN dbo.Mo_Human R ON R.HumanID = LH.RepID
	JOIN Un_RepLevel L ON LH.RepLevelID = L.RepLevelID
	WHERE ((LH.StartDate >= @StartDate AND LH.StartDate < @EndDate + 1)
		 OR (ISNULL(LH.EndDate, @EndDate + 1) >= @StartDate AND ISNULL(LH.EndDate, @EndDate + 2) < @EndDate + 1)
		 OR (LH.StartDate < @StartDate AND ISNULL(LH.EndDate, @EndDate + 2) > @EndDate + 1))
	  AND L.RepRoleID IN ('DIR', 'DIS', 'PRO', 'PRS')
	  AND ((@RepID = LH.RepID) 
		 OR (EXISTS( -- Vérifie si c'est une usager ou un directeur des ventes, car seul eux peuvent voir toutes les agences
				SELECT DISTINCT 
					LH.RepID
				FROM Un_RepLevelHist LH
				JOIN Un_RepLevel L ON LH.RepLevelID = L.RepLevelID
				WHERE ((LH.StartDate >= @StartDate AND LH.StartDate < @EndDate + 1)
					 OR (ISNULL(LH.EndDate, @EndDate + 1) >= @StartDate AND ISNULL(LH.EndDate, @EndDate + 2) < @EndDate + 1)
					 OR (LH.StartDate < @StartDate AND ISNULL(LH.EndDate, @EndDate + 2) > @EndDate + 1))
				  AND L.RepRoleID IN ('PRO', 'PRS')
				  AND (@RepID = 0 OR @RepID = LH.RepID))))
	ORDER BY 
		R.LastName+', '+R.FirstName,
		LH.RepID
END


