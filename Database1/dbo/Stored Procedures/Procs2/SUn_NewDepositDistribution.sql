
-- Optimisé version 26
CREATE PROCEDURE dbo.SUn_NewDepositDistribution (
@ConnectID MoID,
@UnitID MoID,
@CotisationFee MoMoney,
@OperDate MoGetDate,
@Cotisation MoMoney OUTPUT,
@Fee MoMoney OUTPUT)
AS
BEGIN

  DECLARE
  @FeeSplitForUnit MoMoney,
  @FeeForUnit MoMoney,
  @TotFee MoMoney,
  @TotCotisation MoMoney,
  @Amount MoMoney;

  SET @Cotisation = 0;
  SET @Fee = 0;

  SELECT
    @FeeForUnit = (U.UnitQty * M.FeeByUnit),
    @FeeSplitForUnit = (U.UnitQty * M.FeeSplitByUnit)
  FROM dbo.Un_Unit U 
  JOIN Un_Modal M ON (U.ModalID = M.ModalID)
  WHERE U.UnitID = @UnitID;

  SELECT @TotFee = ISNULL(SUM(Fee),0), 
         @TotCotisation = ISNULL(SUM(Cotisation),0) 
  FROM Un_Cotisation
  WHERE (UnitID = @UnitID)
    AND ((EffectDate < @OperDate)
        OR (EffectDate = @OperDate));

  IF @CotisationFee >= 0 
  BEGIN
    IF @TotFee + @TotCotisation < @FeeSplitForUnit
    BEGIN
      IF @CotisationFee + @TotFee + @TotCotisation > @FeeSplitForUnit
      BEGIN
        SET @Fee = @FeeSplitForUnit - (@TotFee + @TotCotisation);
        IF (@TotFee + @TotCotisation + @CotisationFee) < (@FeeSplitForUnit + ((@FeeForUnit - @FeeSplitForUnit) * 2))
          SET @Fee = @Fee + ROUND((@CotisationFee-@Fee)/2,2)
        ELSE 
          SET @Fee = @FeeForUnit - @TotFee;
      END
      ELSE
        SET @Fee = @CotisationFee;
    END
    ELSE IF (@TotFee + @TotCotisation) < (@FeeSplitForUnit + ((@FeeForUnit - @FeeSplitForUnit) * 2))
      BEGIN
         IF (@TotFee + @TotCotisation + @CotisationFee) < (@FeeSplitForUnit + ((@FeeForUnit - @FeeSplitForUnit) * 2))
         BEGIN
           IF ((@TotFee - @FeeSplitForUnit) > @TotCotisation) AND
               (@CotisationFee / 2 <> ROUND(@CotisationFee/2,2))
             SET @Fee = ROUND(@CotisationFee/2,2)-.01
           ELSE
             SET @Fee = ROUND(@CotisationFee/2,2);
         END
         ELSE
           SET @Fee = @FeeForUnit - @TotFee; 
      END
      ELSE
        SET @Fee = 0;  
    IF @Fee > (@FeeForUnit - @TotFee)     
      SET @Fee = @FeeForUnit - @TotFee;

    SET @Cotisation = @CotisationFee - @Fee;
  END;

END;


