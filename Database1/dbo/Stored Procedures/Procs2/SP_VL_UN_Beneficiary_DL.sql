/****************************************************************************************************
	Valide si l'on peut supprimer un bénéficiaire
 ******************************************************************************
	2004-06-08 Bruno Lapointe		Création
	2009-07-21 Éric Deshaies		Empêcher la suppression d’un bénéficiaire
									s'il est utilisé dans l’historique des
									changements de bénéficiaire
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_Beneficiary_DL] (
	@BeneficiaryID INTEGER)
AS
BEGIN
	-- DB01 = Il y a une ou des conventions de liés

	CREATE TABLE #WngAndErr(
		Code VARCHAR(4),
		NbRecord INTEGER
	)

	-- DB01 = Il y a une ou des conventions de liés
	INSERT INTO #WngAndErr
		SELECT 
			'DB01',
			COUNT(ConventionID)
		FROM dbo.Un_Convention 
		WHERE BeneficiaryID = @BeneficiaryID
		HAVING COUNT(ConventionID) > 0

	-- Si le bénéficiaire n'est pas liée à une convention, s'assurer qu'il n'est pas utilisé dans l’historique des changements
	-- de bénéficiaire
	IF NOT EXISTS (SELECT *
				   FROM #WngAndErr
				   WHERE Code = 'DB01')
		INSERT INTO #WngAndErr
			SELECT 'DB01',COUNT(DISTINCT CB.iID_Convention)
			FROM tblCONV_ChangementsBeneficiaire CB
			WHERE CB.iID_Nouveau_Beneficiaire = @BeneficiaryID
			HAVING COUNT(DISTINCT CB.iID_Convention) > 0

	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END;


