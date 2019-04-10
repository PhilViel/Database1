CREATE PROCEDURE DMo_UserGroupRight
 (@ConnectID            MoID,
  @UserGroupID          MoID,
  @RightID              MoID)
AS
BEGIN
  DECLARE 
		@LogDesc MoDesc,
		@UserGroupDesc MoDesc,
		@RightCode MoDesc;

  BEGIN TRANSACTION

  DELETE 
  FROM Mo_UserGroupRight  
  WHERE (RightID = @RightID)
    AND (UserGroupID = @UserGroupID);

  IF (@@ERROR = 0)
  BEGIN
    SELECT @UserGroupDesc = UserGroupDesc
    FROM Mo_UserGroup
    WHERE UserGroupID = @UserGroupID;

    SELECT @RightCode = RightCode
    FROM Mo_Right
    WHERE RightID = @RightID;

    SET @LogDesc = @UserGroupDesc+'('+CAST(@UserGroupID AS VARCHAR)+') <-> '+@RightCode+'('+CAST(@RightID AS VARCHAR)+')';
    EXEC IMo_Log @ConnectID, 'Mo_UserGroupRight', @UserGroupID, 'D', @LogDesc;

    COMMIT TRANSACTION
    RETURN (@UserGroupID);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (0);
  END
END
