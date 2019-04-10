
CREATE FUNCTION dbo.fn_Mo_NameCase
  (@FNameCase MoDesc)
RETURNS MoDesc
AS
BEGIN
  DECLARE
    @FNameCaseStr  MoDesc,
    @FNameStr      MoDesc,
    @FRegCode      CHAR,
    @FPrecRegCode      CHAR,
    @LenName       MoID,
    @Position      MoID;

  IF @FNameCase IS NULL
    RETURN('')

  --Initialize variables
  SET @FNameCaseStr  = LOWER(RTRIM(LTRIM(@FNameCase)));
  SET @LenName = DATALENGTH(@FNameCaseStr);
  SET @FNameStr = '';
  SET @Position = 1;
  SET @FPrecRegCode = '';
  IF @LenName = 0
    RETURN('')

  WHILE @Position <= @LenName
  BEGIN
    SET @FRegCode = SUBSTRING(@FNameCaseStr, @Position, 1);
     IF @FPrecRegCode IN ('.', '-', '/', '(', ')', '[', ']', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '#', '')
         SET @FNameStr = @FNameStr + Upper(@FRegCode);
      ELSE
         SET @FNameStr = @FNameStr + Lower(@FRegCode);
    SET @FPrecRegCode = @FRegCode;
    SET @Position = @Position + 1;
  END

  RETURN(@FNameStr)
END

