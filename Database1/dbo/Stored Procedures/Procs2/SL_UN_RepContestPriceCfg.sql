/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	SL_UN_RepContestPriceCfg
Description         :	Liste des prix des concours
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepContestPriceCfg] (
	@RepContestPriceCfgID INTEGER, -- Filtre sur le ID unique du prix (0=Tous)
	@RepContestCfgID INTEGER) -- Filtre sur le ID unique du concours (0=Tous)
AS
BEGIN
	SELECT
		P.RepContestPriceCfgID,
		P.RepContestCfgID,
		P.ContestPriceName,
		P.MinUnitQty,
		P.SectionColor,
		C.ContestName
	FROM Un_RepContestPriceCfg P
	JOIN Un_RepContestCfg C ON C.RepContestCfgID = P.RepContestCfgID
	WHERE	( @RepContestPriceCfgID = 0
		 	OR @RepContestPriceCfgID = P.RepContestPriceCfgID
			)
		AND( @RepContestCfgID = 0
		 	OR @RepContestCfgID = P.RepContestCfgID
			)
	ORDER BY 
		C.ContestName,
		P.RepContestCfgID, 
		P.MinUnitQty DESC, 
		P.RepContestPriceCfgID
END

