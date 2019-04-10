/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_MinDepositCfg
Description         :	Retourne la liste des configurations des minimums d'épargnes et frais par dépôts pour une 
						convention selon la modalité de paiement et le plan.
Valeurs de retours  :	Dataset de données

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001273	IA	2007-03-26	Alain Quirion		Modification. Changement du nom et suppression du paramètre d'entrée MinDepositCfgID
										2010-01-07	Pierre-Luc Simard	Renommer le plan Reeeflex 2010 pour le différencier du Reeeflex
																		Cette dernière empêche l'affichage de date de fin dans Uniacces dans le régime Reeeflex original
                                        2018-11-08  Pierre-Luc Simard   Utilisation du champ NomPlan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_MinDepositCfg]
AS
BEGIN
	SELECT
		M.MinDepositCfgID,
		M.PlanID,
		PlanDesc = P.NomPlan,
		M.EffectDate,
		ModalTypeID = CASE
						WHEN M.ModalTypeID = 1 THEN 'Annuel'
						WHEN M.ModalTypeID = 2 THEN 'Semi-annuel'
						WHEN M.ModalTypeID = 6 THEN 'Bmensuel'
						WHEN M.ModalTypeID = 12 THEN 'Mensuel'
						WHEN M.ModalTypeID = 4 THEN 'Trimestriel'
						WHEN M.ModalTypeID = 0 THEN 'Unique'						
					END,
		M.MinAmount
	FROM Un_MinDepositCfg M
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	ORDER BY
		P.PlanDesc,		
		ModalTypeID ASC,
		M.EffectDate DESC
END