

CREATE FUNCTION dbo.fn_Mo_StrToMoney
( @Str         MoDesc
)
RETURNS MoMoney
AS
BEGIN
DECLARE
  @FMoney     MoMoney,
  @FMoneyStr  MoDesc,
  @Position   MoID,
  @CommaPast  MoBitFalse,
  @NumericStart MoBitFalse,
  @NumericEnd   MoID

  SET @Position = 1
  SET @NumericEnd = 1
  SET @FMoneyStr = ''
  SET @CommaPast = 0
  SET @NumericStart = 0

  WHILE @Position <= DATALENGTH(@Str)
  BEGIN
    IF     (NOT SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9',',','.'))
       AND (@NumericStart = 1)
      SET @NumericEnd = @Position

    IF     (SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9',',','.'))
       AND (@NumericStart = 0)
      SET @NumericStart = 1

    SET @Position = @Position + 1
  END

  SET @Position = @NumericEnd
  WHILE @Position > 0
  BEGIN
    IF SUBSTRING(@Str,@Position,1) IN ('0','1','2','3','4','5','6','7','8','9')
      SET @FMoneyStr = SUBSTRING(@Str,@Position,1) + @FMoneyStr
    IF (SUBSTRING(@Str,@Position,1) IN ('.',',')) AND (@CommaPast = 0) AND (LEN(@FMoneyStr)<3)
    BEGIN
      SET @FMoneyStr = '.' + @FMoneyStr
      SET @CommaPast = 1
    END
    SET @Position = @Position - 1
  END

  IF ISNUMERIC(@FMoneyStr) = 1
    SET @FMoney = CAST(@FMoneyStr as Money)
  ELSE
    SET @FMoney = Null

  RETURN(@FMoney)
END

