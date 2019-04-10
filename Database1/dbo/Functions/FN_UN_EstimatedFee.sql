/****************************************************************************************************
	Fonction de calcul de frais estimé
*********************************************************************************
	2004-05-06 Dominic Létourneau
		Migration de l'ancienne fonction selon les nouveaux standards
	2004-07-16 Bruno Lapointe
		Correction de l'arrondissement Assignment ADX0000858
*********************************************************************************/
CREATE FUNCTION dbo.FN_UN_EstimatedFee (
	@CotisationAndFee MONEY, -- Montant de cotisation et de frais
	@UnitQty MONEY, -- Quantité d'unité du groupe
	@FeeSplitByUnit MONEY, -- Séparation de frais par unité
	@FeeByUnit MONEY) -- Frais par unité
RETURNS MONEY
AS
BEGIN
	DECLARE 
		@Fee MONEY
	
	IF @CotisationAndFee >= ROUND(@UnitQty * @FeeSplitByUnit, 2) + ROUND(((@FeeByUnit - @FeeSplitByUnit) * 2) * @UnitQty, 2)
		SET @Fee = ROUND(@FeeByUnit * @UnitQty, 2)
	ELSE IF @CotisationAndFee > ROUND(@UnitQty * @FeeSplitByUnit, 2)
		SET @Fee = ROUND(@FeeSplitByUnit * @UnitQty, 2) + ROUND((@CotisationAndFee - ROUND(@FeeSplitByUnit * @UnitQty,2))/2, 2)
	ELSE 
		SET @Fee = @CotisationAndFee 
	
	RETURN(@Fee)
END

