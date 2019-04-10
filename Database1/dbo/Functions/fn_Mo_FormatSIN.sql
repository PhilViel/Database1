
CREATE FUNCTION dbo.fn_Mo_FormatSIN
  (@FSIN     MoDesc,
   @FCountry MoCountry)     -- Country  CAN = Canada
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FSINStr   MoDesc;

  IF @FSIN IS NULL
    RETURN('')

  --Initialize variables
  SET @FSINStr  = UPPER(REPLACE(RTRIM(LTRIM(@FSIN)), ' ', ''))

  IF (@FCountry = 'CAN') AND (DATALENGTH(@FSINStr) = 9)
    SET @FSINStr = SUBSTRING(@FSINStr, 1, 3) + SPACE(1) + SUBSTRING(@FSINStr, 4, 3) + SPACE(1) + SUBSTRING(@FSINStr, 7, 3)
  ELSE
    SET @FSINStr = @FSIN

  RETURN(@FSINStr)
END

