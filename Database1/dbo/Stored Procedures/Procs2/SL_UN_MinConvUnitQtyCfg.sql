
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_MinConvUnitQtyCfg
Description         :	Retourne la liste des configurations du minimum d'unités par convention convention.
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001272	IA	2006-03-26	Alain Quirion		Modification. Changement de nom et suppression du paramètre d'entrée @MinConvUnitQtyCfgID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_MinConvUnitQtyCfg
AS
BEGIN
	SELECT
		MinConvUnitQtyCfgID,
		EffectDate,
		MinUnitQty
	FROM Un_MinConvUnitQtyCfg
	ORDER BY EffectDate DESC
END

