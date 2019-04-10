/****************************************************************************************************
  Retourne les conventions dont la validation de l'age du beneficiaire versus 
  modalité pour un bénéficiaire n'a pas passé                                                                               
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_BenefAgeVsModalForUnit] (
	@ConventionID   INTEGER, -- ID unique de la convention
	@InForceDate    DATETIME, -- Date vigueur 
	@ModalID        INTEGER) -- ID unique de la modalité
AS 
BEGIN
	SELECT DISTINCT
		C.ConventionNo
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human H ON (H.HumanID = C.BeneficiaryID)
	JOIN Un_Modal M ON (M.ModalID = @ModalID)
	WHERE (C.ConventionID = @ConventionID)
	  AND (dbo.fn_Mo_Age(H.BirthDate, @InForceDate) <> M.BenefAgeOnBegining)
END;


