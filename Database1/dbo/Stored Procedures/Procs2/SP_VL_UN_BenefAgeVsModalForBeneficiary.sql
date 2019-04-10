/****************************************************************************************************
	Retourne les conventions dont la validation de l'age du beneficiaire versus 
	modalité pour un bénéficiaire n'a pas passé                                                                               
 ******************************************************************************
	2004-06-08 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_BenefAgeVsModalForBeneficiary] (
  @BeneficiaryID  INTEGER, -- ID unique du bénéficiaire
  @BirthDate      DATETIME) -- Date de naissance 
AS 
BEGIN
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
	JOIN Un_Modal M ON (M.ModalID = U.ModalID)
	WHERE (C.BeneficiaryID = @BeneficiaryID)
	  AND (dbo.fn_Mo_Age(@BirthDate, U.InForceDate) <> M.BenefAgeOnBegining)
END


