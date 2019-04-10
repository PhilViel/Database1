
CREATE FUNCTION dbo.fn_Mo_GetLastName
  (@FLongName       MoDesc,
   @FirstNameFirst  MoBitTrue)
RETURNS MoDesc
AS
BEGIN
  DECLARE @LastName MoDesc

  IF @FirstNameFirst = 0
  BEGIN
    IF CHARINDEX(', ', @FLongName) <> 0
      SET @LastName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(', ', @FLongName)))
    ELSE
      IF CHARINDEX(',', @FLongName) <> 0
        SET @LastName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(',', @FLongName)))
      ELSE
        SET @LastName = RTRIM(SUBSTRING(@FLongName, 0, CHARINDEX(' ', @FLongName)))
  END
  ELSE
  BEGIN
    IF CHARINDEX(', ', @FLongName) <> 0
      SET @LastName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(', ', @FLongName)+2), ''))
    ELSE
      IF CHARINDEX(',', @FLongName) <> 0
        SET @LastName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(',', @FLongName)+1), ''))
      ELSE
        SET @LastName = LTRIM(REPLACE(@FLongName, SUBSTRING(@FLongName, 0, CHARINDEX(' ', @FLongName)+1), ''))
  END
  RETURN(@LastName)
END

