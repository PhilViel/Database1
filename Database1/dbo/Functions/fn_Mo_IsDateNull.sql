
CREATE FUNCTION dbo.fn_Mo_IsDateNull
  (@FDate       MoDate)
RETURNS MoDate
AS
BEGIN
  IF (@FDate < 1) or (@FDate IS NULL)
    RETURN(NULL)

  RETURN(@FDate)
END

