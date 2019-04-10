
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_MaxConvDepositDateCfg
Description         :	Retourne la liste des configurations de la date maximum pour faire des dépôts pour une convention.
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001270	IA	2006-03-26	Alain Quirion		Modification. Changement de nom et suppresion du paramêtre d'Entrée @MaxConvDepositDateCfgID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_MaxConvDepositDateCfg
AS
BEGIN
	SELECT
		MaxConvDepositDateCfgID,
		EffectDate,
		YearQty
	FROM Un_MaxConvDepositDateCfg	
	ORDER BY EffectDate DESC
END

