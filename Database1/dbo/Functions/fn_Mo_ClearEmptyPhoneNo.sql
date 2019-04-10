
CREATE FUNCTION dbo.fn_Mo_ClearEmptyPhoneNo
(@FPhoneNo MoDesc)
RETURNS MoDesc
AS
BEGIN

  DECLARE
    @FPhoneNoStr   MoDesc;

  --Initialize variables
  SET @FPhoneNoStr  = REPLACE(@FPhoneNo,' ','');
  SET @FPhoneNoStr  = REPLACE(@FPhoneNoStr,'(','');
  SET @FPhoneNoStr  = REPLACE(@FPhoneNoStr,')','');
  SET @FPhoneNoStr  = REPLACE(@FPhoneNoStr,'-','');

  IF (@FPhoneNoStr = '')
    SET @FPhoneNoStr = NULL
  ELSE
    SET @FPhoneNoStr = @FPhoneNo;

  RETURN(@FPhoneNoStr)

END

