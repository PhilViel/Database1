
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_RepRecruitMonthCfg
Description 		:	Renvoi la liste des configurations de durée en mois des recrues
Valeurs de retour	:	Dataset :
							RepRecruitMonthCfgID	INTEGER	ID de la configuration
							EffectDate				DATE	Date de début
							Months					INTEGER	Nombre de mois

Notes				:	ADX0001254	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_RepRecruitMonthCfg
AS
BEGIN
	SELECT
		RepRecruitMonthCfgID,		--ID de la configuration
		EffectDate,					--Date de début
		Months						--Nombre de mois
	FROM Un_RepRecruitMonthCfg
	ORDER BY EffectDate DESC
END

