
CREATE FUNCTION dbo.fn_Mo_FormatPhoneNo
( @FPhoneNo    MoDesc,
  @FCountry    MoCountry     -- Country  CAN = Canada
)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FPhoneNoStr   MoDesc,
    @FRegCode      Modesc,
    @FLastDigits   Modesc,
    @FFirstDigits  MoDesc,
    @Position      MoID;

  IF @FPhoneNo IS NULL
    RETURN('')

  --Initialize variables
  SET @FPhoneNoStr  = UPPER(REPLACE(RTRIM(LTRIM(@FPhoneNo)), ' ', ''))
  SET @FRegCode     = ''
  SET @FLastDigits  = ''
  SET @FFirstDigits = '';
  SET @Position = DATALENGTH(@FPhoneNoStr)

  IF (@FCountry = 'CAN') AND (@Position > 6) AND (@Position < 11)
  BEGIN
    WHILE @Position > 0
    BEGIN
      IF DATALENGTH(@FLastDigits) < 4
        SET @FLastDigits = SUBSTRING(@FPhoneNoStr, @Position, 1) + @FLastDigits
      ELSE IF DATALENGTH(@FFirstDigits) < 3
        SET @FFirstDigits = SUBSTRING(@FPhoneNoStr, @Position, 1) +  @FFirstDigits
      ELSE IF DATALENGTH(@FRegCode) < 3
        SET @FRegCode  = SUBSTRING(@FPhoneNoStr, @Position, 1) + @FRegCode
      SET @Position = @Position -1
    END

    IF @FRegCode <> ''
      SET @FRegCode = '('+@FRegCode+')'

    SET @FPhoneNoStr = @FRegCode + SPACE(1) + @FFirstDigits +'-'+ @FLastDigits
  END
  ELSE
    SET @FPhoneNoStr = @FPhoneNo

  RETURN(@FPhoneNoStr)
END

