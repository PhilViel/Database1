
CREATE FUNCTION dbo.fn_Mo_FormatZIP
( @FZipCode    MoDesc,
  @FCountry    MoCountry     -- Country  CAN = Canada
)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FZipCodeStr MoDesc;

  IF @FZipCode IS NULL
    RETURN('')

  SET @FZipCodeStr = UPPER(REPLACE(RTRIM(LTRIM(@FZipCode)), ' ', ''))

  IF (@FCountry = 'CAN') AND (DATALENGTH(@FZipCodeStr) = 6)
    SET @FZipCodeStr = SUBSTRING(@FZipCodeStr, 1, 3) + SPACE(1) + SUBSTRING(@FZipCodeStr, 4, 3)
  ELSE
    SET @FZipCodeStr = @FZipCode

  RETURN(@FZipCodeStr)
END

