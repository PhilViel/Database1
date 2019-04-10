
--  dbo UDF fn_Un_GetAdvanceAmount
--      This function takes as input a Total Fee for a unit group,
--                                     Advance Paid to date,
--                                     Commission + advance to pay,
--      and returns the amount to pay of advance
CREATE FUNCTION dbo.fn_Un_GetAdvanceAmount
( @FTotalFee     MoMoney,
  @FAdvancePaid  MoMoney,
  @ToPay         MoMoney
)
RETURNS MoMoney
AS
BEGIN
  DECLARE
    @Advance     MoMoney
  IF @FTotalFee < 0 
    SET @FTotalFee = 0
  IF @ToPay >= @FTotalFee   
    SET @Advance = (@ToPay - @FTotalFee) - @FAdvancePaid
  ELSE
    SET @Advance = @FAdvancePaid * -1

  RETURN(@Advance)
END

