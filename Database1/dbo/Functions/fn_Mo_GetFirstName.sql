
CREATE FUNCTION dbo.fn_Mo_GetFirstName
  (@FLongName       MoDesc,
   @FirstNameFirst  MoBitTrue)
RETURNS MoDesc
AS
BEGIN
  DECLARE @FirstName MoDesc

  IF @FirstNameFirst = 1
  BEGIN
    IF CHARINDEX(', ', @FLongName) <> 0
      SET @FirstName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(', ', @FLongName)))
    ELSE
      IF CHARINDEX(',', @FLongName) <> 0
        SET @FirstName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(',', @FLongName)))
      ELSE
        SET @FirstName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(' ', @FLongName)))
  END
  ELSE
  BEGIN
    IF CHARINDEX(', ', @FLongName) <> 0
      SET @FirstName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(', ', @FLongName)+2), ''))
    ELSE
      IF CHARINDEX(',', @FLongName) <> 0
        SET @FirstName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(',', @FLongName)+1), ''))
      ELSE
        SET @FirstName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(' ', @FLongName)+1), ''))
  END
  RETURN(@FirstName)
END

