/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_Modal
Description         :	Liste des plans
Valeurs de retours :	Dataset :
								ModalID					INTEGER		ID de la modalité de dépôts
								PlanID					INTEGER		ID du régime
								PlanDesc				VARCHAR(75)	Nom du régime
								PlanTypeID				CHAR(3)		Type de régime (IND = individuel, COL = collectif)
								ModalDate				DATETIME	Date d’entrée en vigueur de la modalité.
								PmtByYearID				SMALLINT	Nombre de dépôts par année.
								PmtQty					INTEGER		Nombre total de dépôt.
								BenefAgeOnBeginning		INTEGER		Age du bénéficiaire à la d’entrée en vigueur.
								PmtRate					MONEY		Montant d’épargne et de frais par dépôt par unité.
								SubscriberInsuranceRate MONEY		Montant d’assurance souscripteur par dépôt par unité.
								FeeByUnit				MONEY		Frais par unité.
								FeeSplitByUnit			MONEY		Montant de frais à atteindre avant la répartition 50/50.
								BusinessBonusToPay		BIT			Indique s’il faut payer des bonis d’affaires pour les groupes d’unités de cette modalité de dépôts.
								NbUnits					INTEGER		Nombre de groupes d'unités qui utilisent actuellement cette modalité de dépôt

Note                :			ADX0001317	IA	2007-05-01	Alain Quirion	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_Modal] (
	@PlanID INTEGER, -- ID Unique du plan, si 0 retourne tous
	@ModalID INTEGER) -- ID de la modalité de dépôt
AS
BEGIN
	SELECT
		M.ModalID,				
		P.PlanID,					
		P.PlanDesc,			
		P.PlanTypeID,	
		M.ModalDate,				
		M.PmtByYearID,				
		M.PmtQty,	
		M.BenefAgeOnBegining,	
		M.PmtRate,					
		M.SubscriberInsuranceRate, 
		M.FeeByUnit,				
		M.FeeSplitByUnit,			
		M.BusinessBonusToPay,
		NbUnits = ISNULL(U.NbUnits,0)
	FROM Un_Modal M
	JOIN Un_Plan P ON P.PlanID = M.PlanID	
	LEFT JOIN (
				SELECT	NbUnits = COUNT(*),
						M.ModalID	
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				GROUP BY M.ModalID) U ON U.ModalID = M.ModalID
	WHERE (M.ModalId = @ModalID 
				OR @ModalID =0)
			AND (@PlanID = 0
				OR @PlanID = P.PlanID)
	ORDER BY P.PlanDesc, M.ModalDate, M.BenefAgeOnBegining
END


