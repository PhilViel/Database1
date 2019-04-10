
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_BeneficiaryCeilingCfg
Description         :	Retourne la liste des configurations des plafonds des bénéficiaires
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001265	IA	2007-03-26	Alain Quirion		Modification. Suppresion du BeneficiaryCeilingCfgID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.SL_UN_BeneficiaryCeilingCfg
AS
BEGIN
	SELECT
		BeneficiaryCeilingCfgID,
		EffectDate,
		AnnualCeiling,
		LifeCeiling 
	FROM Un_BeneficiaryCeilingCfg
	ORDER BY EffectDate DESC
END

