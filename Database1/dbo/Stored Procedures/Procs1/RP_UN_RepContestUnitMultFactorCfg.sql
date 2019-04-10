/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	RP_UN_RepContestUnitMultFactorCfg
Description         :	Procédure stockée du rapport : Concours et Concours des directeurs (Facteur de multiplication)
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepContestUnitMultFactorCfg] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepContestCfgID INTEGER ) -- ID Unique du concours
AS
BEGIN
	SELECT 
		RepContestUnitMultFactorCfgID,
		StartDate,
		EndDate,
		RecruitUnitMultFactor,
		NonRecruitUnitMultFactor
	FROM Un_RepContestUnitMultFactorCfg
	WHERE RepContestCfgID = @RepContestCfgID
	ORDER BY 
		StartDate, 
		EndDate
END

