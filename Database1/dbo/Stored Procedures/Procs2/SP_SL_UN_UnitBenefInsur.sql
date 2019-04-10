/****************************************************************************************************
	Liste des taux d'assurances bénéficiaires pour un groupe d'unités
 ******************************************************************************
	2004-08-27 Bruno Lapointe
		Migration et normalisation
		Bug Report : ADX0001073
 ******************************************************************************/
CREATE PROC [dbo].[SP_SL_UN_UnitBenefInsur] (
	@ModalID INTEGER, -- ID unique de la modalité du groupe d'unités
	@InForceDate DATETIME) -- Date de vigueur du groupe d'unités
AS
BEGIN
	DECLARE 
		@PmtByYearID INTEGER

	SELECT 
		@PmtByYearID = PmtByYearID
	FROM Un_Modal
	WHERE @ModalID = ModalID

	SELECT 
		BI.BenefInsurID,
		BI.BenefInsurDate,
		BI.BenefInsurFaceValue,
		BI.BenefInsurPmtByYear,
		BI.BenefInsurRate
	FROM Un_BenefInsur BI 
	JOIN (
		SELECT 
			BenefInsurDate = MAX(BenefInsurDate), 
			BenefInsurFaceValue
		FROM Un_BenefInsur  
		WHERE BenefInsurPmtByYear = @PmtByYearID
		  AND (BenefInsurDate <= @InForceDate)
		GROUP BY BenefInsurFaceValue) MBI ON MBI.BenefInsurDate = BI.BenefInsurDate AND MBI.BenefInsurFaceValue = BI.BenefInsurFaceValue
	WHERE BI.BenefInsurPmtByYear = @PmtByYearID
END

