
CREATE FUNCTION dbo.fn_Mo_TranslateIntMonthToStr
(
  @FMonth     MoID,
  @FLang      MoOptionCode
)
RETURNS MoDesc
AS
BEGIN
DECLARE
  @FMonthStr  MoDesc;

  IF @FLang = 'FRA'
  BEGIN
    IF @FMonth = 1 SET @FMonthStr = 'janvier'
    ELSE IF @FMonth = 2 SET @FMonthStr = 'février'
    ELSE IF @FMonth = 3 SET @FMonthStr = 'mars'
    ELSE IF @FMonth = 4 SET @FMonthStr = 'avril'
    ELSE IF @FMonth = 5 SET @FMonthStr = 'mai'
    ELSE IF @FMonth = 6 SET @FMonthStr = 'juin'
    ELSE IF @FMonth = 7 SET @FMonthStr = 'juillet'
    ELSE IF @FMonth = 8 SET @FMonthStr = 'août'
    ELSE IF @FMonth = 9 SET @FMonthStr = 'septembre'
    ELSE IF @FMonth = 10 SET @FMonthStr = 'octobre'
    ELSE IF @FMonth = 11 SET @FMonthStr = 'novembre'
    ELSE IF @FMonth = 12 SET @FMonthStr = 'décembre'
  END
  ELSE
  BEGIN
    IF @FMonth = 1 SET @FMonthStr = 'january'
    ELSE IF @FMonth = 2 SET @FMonthStr = 'february'
    ELSE IF @FMonth = 3 SET @FMonthStr = 'march'
    ELSE IF @FMonth = 4 SET @FMonthStr = 'april'
    ELSE IF @FMonth = 5 SET @FMonthStr = 'may'
    ELSE IF @FMonth = 6 SET @FMonthStr = 'june'
    ELSE IF @FMonth = 7 SET @FMonthStr = 'july'
    ELSE IF @FMonth = 8 SET @FMonthStr = 'august'
    ELSE IF @FMonth = 9 SET @FMonthStr = 'september'
    ELSE IF @FMonth = 10 SET @FMonthStr = 'october'
    ELSE IF @FMonth = 11 SET @FMonthStr = 'november'
    ELSE IF @FMonth = 12 SET @FMonthStr = 'decemder'
  END;

  RETURN(@FMonthStr)
END

