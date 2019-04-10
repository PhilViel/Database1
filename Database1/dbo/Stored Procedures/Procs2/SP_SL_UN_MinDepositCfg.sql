/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_MinDepositCfg
Description         :	Retourne la liste des configurations des minimums d'épargnes et frais par dépôts pour une 
								convention selon la modalité de paiement et le plan.
Valeurs de retours  :	Dataset de données
Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_MinDepositCfg] (
	@MinDepositCfgID INTEGER) -- ID Unique de connexion de l'usager
AS
BEGIN
	SELECT
		M.MinDepositCfgID,
		M.PlanID,
		P.PlanDesc,
		M.EffectDate,
		M.ModalTypeID,
		M.MinAmount
	FROM Un_MinDepositCfg M
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	WHERE @MinDepositCfgID = 0
		OR @MinDepositCfgID = M.MinDepositCfgID
	ORDER BY
		P.PlanDesc,
		M.EffectDate,
		M.ModalTypeID DESC
END

