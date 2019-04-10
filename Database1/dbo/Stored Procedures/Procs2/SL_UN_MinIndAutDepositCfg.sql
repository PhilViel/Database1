
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_MinIndAutDepositCfg
Description         :	Liste les enregistrements de la table de configuration du minimum d'épargnes et frais pour un
						prélèvement automatique sur une convention individuelle
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001275	IA	2007-03-27	Alain Quirion		Modification.  Changement de nom et suppresion du paramètre d'entrée
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_MinIndAutDepositCfg AS
BEGIN
	SELECT
		M.MinIndAutDepositCfgID,
		M.EffectDate,
		M.MinAmount
	FROM Un_MinIndAutDepositCfg M
	ORDER BY M.EffectDate DESC
END

