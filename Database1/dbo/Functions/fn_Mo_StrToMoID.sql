
CREATE FUNCTION dbo.fn_Mo_StrToMoID
 (@Str         MoDesc)
RETURNS MoID
AS
BEGIN
DECLARE
  @FMoID      MoID,
  @FMoIDStr   MoDesc,
  @Position   MoID,
  @NumericStart MoBitFalse,
  @NumericEnd   MoID

  SET @Position = 1
  SET @NumericEnd = 1
  SET @FMoIDStr = ''
  SET @NumericStart = 0

  WHILE @Position <= DATALENGTH(@Str)
  BEGIN
    IF     (NOT SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9'))
       AND (@NumericStart = 1)
      SET @NumericEnd = @Position

    IF     (SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9'))
       AND (@NumericStart = 0)
      SET @NumericStart = 1

    SET @Position = @Position + 1
  END

  SET @Position = @NumericEnd
  WHILE @Position > 0
  BEGIN
    IF SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9')
      SET @FMoIDStr = SUBSTRING(@Str,@Position,1) + @FMoIDStr
    SET @Position = @Position - 1
  END

  IF ISNUMERIC(@FMoIDStr) = 1
    SET @FMoID = CAST(@FMoIDStr as Money)
  ELSE
    SET @FMoID = Null

  RETURN(@FMoID)
END

