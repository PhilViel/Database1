/****************************************************************************************************
	Retourne un enregistrement avec le dépôt minimum sur ajout d'unités en mode 
	de paiement unique s'il y a déjà un groupe d'unité pour la convention.
 ******************************************************************************
	2004-05-27 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_MinUniqueDep](
	@ConventionID INTEGER, -- ID Unique de la convention
	@ModalID      INTEGER, -- ID Unique de la modalité de paiement du groupe d'unités
	@InForceDate  DATETIME, -- Date de vigueur
	@UnitQty      MONEY) -- Nombre d'unités
AS
BEGIN
	SELECT 
		D.MinAmount
	FROM Un_MinUniqueDepCfg D,
		(
		SELECT
			PmtQty,
			PmtRate
		FROM Un_Modal 
		WHERE (ModalID = @ModalID)
		) M,
		(
		SELECT 
			COUNT(1) AS UnitGroupCount
		FROM dbo.Un_Unit 
		WHERE ConventionID = @ConventionID 
		) U  
	WHERE (D.EffectDate IN (
		SELECT 
			MAX(EffectDate)           
		FROM Un_MinUniqueDepCfg 
		WHERE (EffectDate <= @InforceDate))) -- Va chercher le minimum en vigueur s'il y en a
	  AND (M.PmtQty = 1) -- Mode de paiement unique Unique
	  AND (U.UnitGroupCount > 0) -- Il faut déjà avoir un groupe d'unités dans la convention pour que ce soit un ajout d'unités
	  AND (ROUND(@UnitQty * M.PmtRate,2) < D.MinAmount)  
END;


