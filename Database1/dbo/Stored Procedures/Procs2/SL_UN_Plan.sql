/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Plan
Description         :	Liste des plans
Valeurs de retours  :	Dataset :
									PlanID					INTEGER 	ID unique du plan.
									PlanTypeID				CHAR(3)		Chaîne de 3 caractères identifiant le type du plan ('IND' 
																		= Individuel, 'COL' = Collectif).
									PlanDesc				VARCHAR(75)	Nom donnée par Gestion Universitas à ce plan.
									PlanScholarshipQty		SMALLINT	Nombre de bourse que génère ce plan pour une convention.
									PlanOrderID				SMALLINT	Inutilisé
									PlanGovernmentRegNo		NVARCHAR(10)Numéro enregistré du régime au gouvernement.
									IntReimbAge				SMALLINT	Age que doit avoir le bénéficiaire pour que la convention 
																		soit illigible au remboursement intégral.
									bEligibleForCESG		BIT			Régime admissible à la SCEE (0=non, 1=oui).
									bEligibleForACESG		BIT			Régime admissible à la SCEE+ (0=non, 1=oui).
									bEligibleForCLB			BIT			Régime admissible au BEC (0=non, 1=oui).

Note                :							2004-06-07	Bruno Lapointe	Création
								ADX0000923	IA	2006-03-23	Bruno Lapointe	Retour des champs bEligibleForCESG, bEligibleForACESG
																			et bEligibleForCLB
								ADX0001317	IA	2007-05-01	Alain Quirion	Ajout du tiAgeQualif
												2010-01-07	Pierre-Luc Simard	Renommer le plan Reeeflex 2010 pour le différencier du Reeeflex
                                                2018-11-08  Pierre-Luc Simard   Utilisation du champ NomPlan
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Plan] (
	@PlanID INTEGER) -- ID Unique du plan, si 0 retourne tous
AS
BEGIN
	SELECT
		PlanID,
		PlanTypeID,
		PlanDesc = NomPlan,
		PlanScholarshipQty,
		PlanOrderID,
		PlanGovernmentRegNo,
		IntReimbAge,
		bEligibleForCESG,
		bEligibleForACESG,
		bEligibleForCLB,
		tiAgeQualif
	FROM Un_Plan
	WHERE @PlanID = 0
		OR @PlanID = PlanID
	ORDER BY PlanDesc
END