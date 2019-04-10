
CREATE PROCEDURE SMo_ValidateUser
  (@LoginNameID  MoLoginName,
   @PasswordID   MoLoginName)
AS
BEGIN
  DECLARE @Result MoBitFalse;

  IF EXISTS (SELECT *
             FROM Mo_User
             WHERE (LoginNameID = @LoginNameID)
               AND (dbo.fn_Mo_Decrypt(PasswordID) = @PasswordID)
               AND (TerminatedDate IS NULL OR TerminatedDate > GetDate()))
    SET @Result = 1
  ELSE
    SET @Result = 0;

  RETURN(@Result);
END;
