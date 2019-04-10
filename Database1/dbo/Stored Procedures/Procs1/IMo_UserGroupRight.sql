CREATE PROCEDURE IMo_UserGroupRight
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

  IF NOT EXISTS (SELECT UserGroupID FROM Mo_UserGroupRight WHERE UserGroupID = @UserGroupID AND RightID = @RightID)
  BEGIN
    /* Création de l'utiliateur dans Mo_User */
    INSERT INTO Mo_UserGroupRight (
      UserGroupID,
      RightID)
 	  VALUES (
			@UserGroupID,
      @RightID);

    IF (@@ERROR <> 0) 
      SET @UserGroupID = 0
    ELSE
    BEGIN
      SELECT @UserGroupDesc = UserGroupDesc
      FROM Mo_UserGroup
      WHERE UserGroupID = @UserGroupID;

      SELECT @RightCode = RightCode
      FROM Mo_Right
      WHERE RightID = @RightID;

      SET @LogDesc = @UserGroupDesc+'('+CAST(@UserGroupID AS VARCHAR)+') <-> '+@RightCode+'('+CAST(@RightID AS VARCHAR)+')';
      EXEC IMo_Log @ConnectID, 'Mo_UserGroupRight', @UserGroupID, 'I', @LogDesc;
    END;
  END;

  IF (@UserGroupID <> 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  RETURN @UserGroupID;
END;
