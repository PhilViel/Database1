
CREATE FUNCTION dbo.fn_Un_GetBossAdvanceAmount
( @FAdvance       MoMoney, 
  @FAdvancePaid   MoMoney
)
RETURNS MoMoney
AS
BEGIN
  RETURN(@FAdvance - @FAdvancePaid) 
END

