
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_MinUniqueDepCfg
Description         :	Retourne la liste des configurations du minimum d'épargnes et frais pour un ajout d'unité
						avec modalité de paiement unique
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001277	IA	2007-03-27	Alain Quirion		Modification.  Changement de nom et suppresion du paramètre d'entrée
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_MinUniqueDepCfg
AS
BEGIN
	SELECT
		MinUniqueDepCfgID,
		EffectDate,
		MinAmount
	FROM Un_MinUniqueDepCfg
	ORDER BY EffectDate DESC
END

