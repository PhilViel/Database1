/****************************************************************************************************
	Liste des facteurs de multiplication des concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_SL_UN_RepContestUnitMultFactorCfg] (
	@RepContestUnitMultFactorCfgID INTEGER, -- Filtre du ID unique du facteur de multiplication (0=Tous)
	@RepContestCfgID INTEGER) -- Filtre du ID unique du concours (0=Tous)
AS
BEGIN
	SELECT
		F.RepContestUnitMultFactorCfgID,
		F.RepContestCfgID,
		F.StartDate,
		F.EndDate,
		F.RecruitUnitMultFactor,
		F.NonRecruitUnitMultFactor,
		C.ContestName
	FROM Un_RepContestUnitMultFactorCfg F 
	JOIN Un_RepContestCfg C ON C.RepContestCfgID = F.RepContestCfgID
	WHERE (@RepContestUnitMultFactorCfgID = 0
		 OR @RepContestUnitMultFactorCfgID = F.RepContestUnitMultFactorCfgID)
	  AND (@RepContestCfgID = 0
		 OR @RepContestCfgID = F.RepContestCfgID)
	ORDER BY 
		C.ContestName,
		F.RepContestCfgID, 
		F.StartDate, 
		F.EndDate, 
		F.RepContestUnitMultFactorCfgID
END

