CREATE PROCEDURE RMo_UserRight
 (@ConnectID            MoID,
  @UserID               MoID,
  @RightID              MoID,
  @Status               MoID)
AS
BEGIN
  DECLARE @Result MoID;
 
  SET @Result = @UserID;

  IF (@Status = 0 OR @Status = 1) AND EXISTS (SELECT UserID FROM Mo_UserRight WHERE UserID = @UserID AND RightID = @RightID)
    EXEC @Result = DMo_UserRight @ConnectID, @UserID, @RightID; 
  ELSE IF (@Status = 2) AND NOT EXISTS (SELECT UserID FROM Mo_UserRight WHERE UserID = @UserID AND RightID = @RightID AND Granted <> 0)
    EXEC @Result = IMo_UserRight @ConnectID, @UserID, @RightID, 1; 
  ELSE IF (@Status = 3) AND NOT EXISTS (SELECT UserID FROM Mo_UserRight WHERE UserID = @UserID AND RightID = @RightID AND Granted = 0)
    EXEC @Result = IMo_UserRight @ConnectID, @UserID, @RightID, 0; 

  RETURN @Result;
END;
