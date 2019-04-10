
CREATE FUNCTION dbo.fn_Mo_DateNoTime
  (@FDate       MoDate)
RETURNS MoDate
AS
BEGIN
  SET @FDate = dbo.fn_Mo_IsDateNull(@FDate)
  IF @FDate IS NULL
    RETURN(NULL)

  RETURN(CAST(FLOOR(CAST(@FDATE AS FLOAT)) AS DATETIME))
END

