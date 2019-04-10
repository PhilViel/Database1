
CREATE PROCEDURE dbo.SP_CrqSearchBenefInsurByConvention (@ConventionID MoID) AS

-------------------------------------------------------------------------
-- STORED PROCEDURE DE RECHERCHE D'ASSURANCE BÉNÉFICIAIRE PAR CONVENTION
-------------------------------------------------------------------------

SELECT U.UnitID,
	B.BenefInsurID,
	B.BenefInsurDate,
	B.BenefInsurFaceValue,
	B.BenefInsurPmtByYear,
	B.BenefInsurRate
FROM dbo.Un_Unit U
LEFT JOIN Un_BenefInsur B
	ON U.BenefInsurID = B.BenefInsurID
WHERE U.ConventionID = @ConventionID

/* FIN DES TRAITEMENTS */
RETURN 0


