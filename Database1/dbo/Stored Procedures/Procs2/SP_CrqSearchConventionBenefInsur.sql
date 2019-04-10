
CREATE PROCEDURE dbo.SP_CrqSearchConventionBenefInsur (@ConventionID MoID) AS

-------------------------------------------------------------------------
-- STORED PROCEDURE DE RECHERCHE D'ASSURANCE BÉNÉFICIAIRE PAR CONVENTION
-------------------------------------------------------------------------

SELECT U.UnitID,
	BI.BenefInsurID,
	BI.BenefInsurDate,
	BI.BenefInsurFaceValue,
	BI.BenefInsurPmtByYear,
	BI.BenefInsurRate
FROM dbo.Un_Unit U
INNER JOIN Un_Modal M 
	ON M.ModalID = U.ModalID
INNER JOIN Un_BenefInsur BI 
	ON BI.BenefInsurPmtByYear = M.PmtByYEarID
		AND BI.BenefInsurDate <= U.InForceDate
INNER JOIN (
			SELECT BenefInsurDate = MAX(BenefInsurDate), 
				U.UnitID, 
				BI.BenefInsurFaceValue
				FROM dbo.Un_Unit U
				INNER JOIN Un_Modal M 
					ON M.ModalID = U.ModalID
				INNER JOIN Un_BenefInsur BI 
					ON BI.BenefInsurPmtByYear = M.PmtByYEarID
						AND BI.BenefInsurDate <= U.InForceDate
				GROUP BY U.UnitID, BI.BenefInsurFaceValue
			) MBI 
		ON MBI.UnitID = U.UnitID
			AND MBI.BenefInsurDate = BI.BenefInsurDate
			AND MBI.BenefInsurFaceValue = BI.BenefInsurFaceValue
WHERE U.ConventionID = @ConventionID
ORDER BY U.UnitID

/* FIN DES TRAITEMENTS */
RETURN 0


