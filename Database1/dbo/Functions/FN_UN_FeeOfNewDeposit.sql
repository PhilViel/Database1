/****************************************************************************************************
	Fonction qui retourne le montant de frais d'un nouveau dépôt.  Cette fonction
	est utilisé par la procédure de traitement et génération des CPA.
*********************************************************************************
	2004-10-13 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_UN_FeeOfNewDeposit (
	@UnitID INTEGER,
	@CotisationFee MONEY,
	@OperDate DATETIME,
	@UnitQty MONEY,
	@FeeSplitByUnit MONEY,
	@FeeByUnit MONEY,
	@TotFee MONEY,
	@TotCotisation MONEY)
RETURNS MONEY
AS
BEGIN
	DECLARE 
		@Fee MONEY

	SET @Fee = 0

	SET @FeeByUnit = ROUND(@UnitQty * @FeeByUnit,2)
	SET @FeeSplitByUnit = ROUND(@UnitQty * @FeeSplitByUnit,2)

	IF @CotisationFee >= 0 
	BEGIN
		IF @TotFee + @TotCotisation < @FeeSplitByUnit
		BEGIN
			IF @CotisationFee + @TotFee + @TotCotisation > @FeeSplitByUnit
			BEGIN
				SET @Fee = @FeeSplitByUnit - @TotFee + @TotCotisation
				IF @TotFee + @TotCotisation + @CotisationFee < @FeeSplitByUnit + ((@FeeByUnit - @FeeSplitByUnit) * 2)
					SET @Fee = @Fee + ROUND((@CotisationFee-@Fee)/2,2)
				ELSE 
					SET @Fee = @FeeByUnit - @TotFee
			END
			ELSE
				SET @Fee = @CotisationFee
		END
		ELSE IF @TotFee + @TotCotisation < @FeeSplitByUnit + ((@FeeByUnit - @FeeSplitByUnit) * 2)
		BEGIN
			IF @TotFee + @TotCotisation + @CotisationFee < @FeeSplitByUnit + ((@FeeByUnit - @FeeSplitByUnit) * 2)
			BEGIN
				IF (@TotFee - @FeeSplitByUnit > @TotCotisation) AND
					(@CotisationFee / 2 <> ROUND(@CotisationFee/2,2))
					SET @Fee = ROUND(@CotisationFee/2,2)-.01
				ELSE
					SET @Fee = ROUND(@CotisationFee/2,2)
			END
			ELSE
				SET @Fee = @FeeByUnit - @TotFee
		END
		ELSE
			SET @Fee = 0

		IF @Fee > @FeeByUnit - @TotFee
			SET @Fee = @FeeByUnit - @TotFee
	END
	RETURN @Fee
END

