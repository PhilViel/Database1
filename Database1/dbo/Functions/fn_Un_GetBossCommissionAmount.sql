

--  dbo UDF fn_Un_GetBossCommissionAmount
--      This function takes as input a Total Fee for a unit group,
--                                     Commission Paid to date,
--                                     Advance Paid to date,
--                                     Commission + advance to pay,
--      and returns the amount to pay of commission
CREATE FUNCTION dbo.fn_Un_GetBossCommissionAmount
( @FAdvance       MoMoney,
  @FCommPaid      MoMoney,
  @FAdvancePaid   MoMoney,
  @ToPay          MoMoney
)
RETURNS MoMoney
AS
BEGIN
  DECLARE
    @Commission  MoMoney
    
  SET @Commission = @ToPay - (dbo.fn_Un_GetBossAdvanceAmount(@FAdvance, @FAdvancePaid) + (@FCommPaid + @FAdvancePaid))

  RETURN(@Commission)
END

