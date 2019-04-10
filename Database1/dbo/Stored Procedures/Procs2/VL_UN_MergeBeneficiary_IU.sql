/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 			:	VL_UN_MergeBeneficiary_IU
Description 		:	Validation de la fusion des bénéficiaires
Valeurs de retour	:	Dataset :
						vcErrorCode		CHAR(3)			Code d’erreur
						vcErrorText		VARCHAR(1000)	Texte de l’erreur
						
						Code d’erreur		Erreur
						MB1					Le bénéficiaire avec l’historique de NAS le plus ancien est dans la position du bénéficiaire remplacé.
						MB2					Un ajustement à la date de fin de régime a été saisi pour au moins une des conventions du bénéficiaire qui sera supprimé

Note			:	ADX0001234	IA	2007-02-15	Alain Quirion		Création
					ADX0001355	IA	2007-07-03	Alain Quirion		Ajout du message d'attention MB2
*************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_MergeBeneficiary_IU] (
	@iNewBeneficiaryID INTEGER,			--Identifiant unique du bénéficiaire remplaçant.
	@iOldBeneficiaryID INTEGER)			--Identifiant unique du bénéficiaire remplacé
AS
BEGIN
	DECLARE @dtNewBeneficiaryDate DATETIME,
			@dtOldBeneficiaryDate DATETIME

	SELECT
			@dtNewBeneficiaryDate = MIN(EffectDate)
	FROM Un_HumanSocialNumber SSN
	WHERE SSN.HumanID = @iNewBeneficiaryID

	SELECT
			@dtOldBeneficiaryDate = MIN(EffectDate)
	FROM Un_HumanSocialNumber SSN
	WHERE SSN.HumanID = @iOldBeneficiaryID

	SELECT  vcErrorCode = 'MB1',
			vcErrorText = 'Le bénéficiaire avec l’historique de NAS le plus ancien est dans la position du bénéficiaire remplacé'
	WHERE ISNULL(@dtOldBeneficiaryDate, '9999-12-31') < ISNULL(@dtNewBeneficiaryDate, '9999-12-31')
	-----
	UNION
	-----
	SELECT  DISTINCT
			vcErrorCode = 'MB2',
			vcErrorText = 'Un ajustement à la date de fin de régime a été saisi pour au moins une des conventions du bénéficiaire qui sera supprimé'
	FROM dbo.Un_Beneficiary B
	JOIN dbo.Un_Convention C ON C.BeneficiaryID = B.BeneficiaryID
	WHERE C.BeneficiaryID = @iOldBeneficiaryID
			AND C.dtRegEndDateAdjust IS NOT NULL
END


