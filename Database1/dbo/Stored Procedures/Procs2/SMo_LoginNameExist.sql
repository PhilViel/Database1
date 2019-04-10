CREATE PROCEDURE SMo_LoginNameExist
  (@ConnectID   	MoID,
   @LoginNameID    	MoLoginName)
AS
BEGIN
  SELECT U.UserID
  FROM Mo_User U
  WHERE (LoginNameID = @LoginNameID)
    AND (U.TerminatedDate IS NULL OR U.TerminatedDate > GetDate())
END;

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[SMo_LoginNameExist] TO PUBLIC
    AS [dbo];

