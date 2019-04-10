/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	MT_UN_PlanModal
Description         :	Matrice retournant les plans et leurs modalités
Valeurs de retours  :	Dataset contenant les données des plans et des modalités
Note                :	
						ADX0000652	IA	2005-02-03	Bruno Lapointe		Création
						ADX0000707	IA	2005-07-12	Bruno Lapointe		La procédure retournera les modalités pour les
																		bénéficiaires ayant 2 ans de moins à 2 ans de
																		plus que le bénéficiaire à la date d’entrée en vigueur
						ADX0001317	IA	2007-05-01	Alain Quirion		Modification : Aller chercher l'année de qualification èa partir de la atble des plans
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[MT_UN_PlanModal] (
	@PlanID INTEGER, -- ID unique du plan
	@MostRencent BIT, -- Champ boolean indiquant si on veut uniquement les modalités les plus récentes (<>0) ou tous (0)
	@UnitDate DATETIME, -- Date du groupe d'unités, si l,option MostRecent = True alors on prend les plus récent sous cette date
	@ConventionID INTEGER) -- ID unique de la convnetion
AS
BEGIN
	DECLARE
		@dtBirthDate DATETIME

	SELECT
		@dtBirthDate = H.BirthDate
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human H ON H.HumanID = C.BeneficiaryID
	WHERE C.ConventionID = @ConventionID

	SELECT 
		P.PlanDesc,
		P.PlanTypeID,
		P.PlanScholarshipQty,
		P.PlanOrderID,
		P.PlanGovernmentRegNo,
		P.IntReimbAge,
		M.ModalID,
		M.ModalDate, 
		M.PlanID,
		M.PmtByYearID,
		M.PmtQty,
		M.BenefAgeOnBegining,
		M.PmtRate,
		M.SubscriberInsuranceRate,
		M.FeeByUnit,
		M.FeeSplitByUnit,
		M.FeeRefundable,
		P.tiAgeQualif,
		M.BusinessBonusToPay,
		MostRecent = ISNULL(MM.PmtQty, 0),
		UnitUse = ISNULL(COUNT(U.UnitID),0)
	FROM Un_Plan P
	LEFT JOIN Un_Modal M ON P.PlanID = M.PlanID
	LEFT JOIN (
		SELECT
			ModalDate = MAX(ModalDate),
			PmtByYearID,
			PmtQty,
			BenefAgeOnBegining
		FROM Un_Modal
		WHERE PlanID = @PlanID
			AND ModalDate <= @UnitDate
		GROUP BY
			PmtByYearID,
			PmtQty,
			BenefAgeOnBegining
		) MM ON MM.ModalDate = M.ModalDate AND MM.PmtByYearID = M.PmtByYearID AND MM.PmtQty = M.PmtQty AND MM.BenefAgeOnBegining = M.BenefAgeOnBegining
	LEFT JOIN dbo.Un_Unit U ON U.ModalID = M.ModalID
	WHERE P.PlanID = @PlanID
		AND	( @MostRencent = 0
				OR MM.PmtQty IS NOT NULL
				)
		AND	( @ConventionID = 0
				OR ABS(dbo.fn_Mo_Age(@dtBirthDate, @UnitDate) - M.BenefAgeOnBegining) <= 2
				)
	GROUP BY
		P.PlanDesc,
		P.PlanTypeID,
		P.PlanScholarshipQty,
		P.PlanOrderID,
		P.PlanGovernmentRegNo,
		M.ModalID,
		M.ModalDate,
		M.PlanID,
		M.PmtByYearID,
		M.PmtQty,
		M.BenefAgeOnBegining,
		M.PmtRate,
		M.SubscriberInsuranceRate,
		M.FeeByUnit,
		M.FeeSplitByUnit,
		M.FeeRefundable,
		P.tiAgeQualif,
		M.BusinessBonusToPay,
		MM.PmtQty,
		P.IntReimbAge
	ORDER BY
		M.BenefAgeOnBegining DESC,
		M.PmtByYearID,
		M.PmtQty,
		M.ModalDate DESC
END


