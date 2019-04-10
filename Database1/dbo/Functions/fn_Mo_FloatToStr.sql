
CREATE FUNCTION dbo.fn_Mo_FloatToStr 
( @FFloat      Float,
  @FLang       MoLang,     -- Language  FRA = French / ENU = English / UNK = Unknown
  @Decimal     MoID,
  @DollarSign  MoBitTrue   -- Show Dollar sign
)  
RETURNS MoDesc 
AS  
BEGIN
DECLARE
  @FMoneyStr  MoDesc,
  @IntPart    MoDesc,
  @DecPart    MoDesc,
  @Temp       MoDesc,
  @Position   MoID;

  --Default setting is in english 
  SET @FMoneyStr = LTRIM(RTRIM(STR(ROUND(@FFloat, @Decimal), 20, @Decimal)))
  SET @IntPart = SUBSTRING(@FMoneyStr, 1, (DATALENGTH(@FMoneyStr)-1-@Decimal))
  SET @DecPart = SUBSTRING(@FMoneyStr, (DATALENGTH(@FMoneyStr)-@Decimal+1), @Decimal)
  SET @Position = DATALENGTH(@IntPart)
  
  SET @Temp      = ''
  SET @FMoneyStr = ''

  WHILE @Position > 0 
  BEGIN
    SET @Temp = SUBSTRING(@IntPart, @Position, 1) + @Temp
    IF (DATALENGTH(@Temp) = 3) OR (@Position = 1) 
    BEGIN
      IF @FMoneyStr = '' 
        SET @FMoneyStr = @Temp
      ELSE 
        SET @FMoneyStr = @Temp + SPACE(1) + @FMoneyStr
      SET @Temp = ''
    END
    SET @Position = @Position -1
  END

  IF @FLang = 'FRA'
  BEGIN
    SET @FMoneyStr = @FMoneyStr + ',' + @DecPart
    IF @DollarSign = 1
      SET @FMoneyStr = @FMoneyStr + ' $'
  END
  ELSE
  BEGIN 
    SET @FMoneyStr = @FMoneyStr + '.' + @DecPart
    IF @DollarSign = 1
      SET @FMoneyStr = '$ ' + @FMoneyStr
  END

  RETURN(@FMoneyStr)   
END

