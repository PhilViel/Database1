
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_RepFormationFeeCfg
Description 		:	Renvoi la liste des configurations de frais de formations
Valeurs de retour	:	Dataset :
							RepFormationFeeCfgID	INTEGER	ID de la configuration
							StartDate				DATE	Date de début
							FormationFeeAmount		MONEY	Montant des frais de formations

Notes				:	ADX0001257	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_RepFormationFeeCfg
AS
BEGIN
	SELECT
		RepFormationFeeCfgID,		--INTEGER	ID de la configuration
		StartDate,					--DATE	Date de début
		FormationFeeAmount			--MONEY	Montant des frais de formations
	FROM Un_RepFormationFeeCfg
	ORDER BY StartDate DESC
END

