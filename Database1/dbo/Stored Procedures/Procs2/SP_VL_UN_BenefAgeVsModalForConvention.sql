/****************************************************************************************************
	Retourne les conventions dont la validation de l'age du beneficiaire versus 
	modalité pour un bénéficiaire n'a pas passé                                                                               
 ******************************************************************************
	2004-06-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_BenefAgeVsModalForConvention] (
  @ConventionID INTEGER,  -- ID unique de la convention
  @BeneficiaryID INTEGER)  -- ID unique du bénéficiaire
AS 
BEGIN
	IF EXISTS (
		SELECT DISTINCT
			C.ConventionID,
			C.ConventionNo
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
		JOIN Un_Modal M ON (M.ModalID = U.ModalID)
		JOIN dbo.Mo_Human H ON (H.HumanID = @BeneficiaryID)
		WHERE C.ConventionID = @ConventionID 
		  AND dbo.fn_Mo_Age(H.BirthDate, U.InForceDate) <> M.BenefAgeOnBegining)
		RETURN -1
	ELSE
		RETURN 1
END;


