/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	RP_UN_RepContestPrice
Description         :	Procédure stockée du rapport : Concours et Concours des directeurs (Prix)
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepContestPrice] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepContestCfgID INTEGER ) -- ID Unique du concours
AS
BEGIN
	SELECT 
		RepContestPriceCfgID,
		ContestPriceName,
		SectionColor, 
		MinUnitQty
	FROM Un_RepContestPriceCfg
	WHERE RepContestCfgID = @RepContestCfgID
	-----
	UNION 
	-----
	SELECT 
		RepContestPriceCfgID = 0,
		ContestPriceName = 'Non Qualifié',
		SectionColor = 16777215,
		MinUnitQty = 0
	ORDER BY 
		MinUnitQty DESC
END

