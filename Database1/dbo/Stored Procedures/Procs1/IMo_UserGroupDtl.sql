CREATE PROCEDURE [dbo].[IMo_UserGroupDtl]
 (@ConnectID            MoID,
  @UserID               MoID,
  @UserGroupID          MoID)
AS
BEGIN
  DECLARE 
		@LogDesc MoDesc,
		@UserName MoDesc,
		@UserGroupDesc MoDesc;

  BEGIN TRANSACTION

  IF NOT EXISTS (SELECT UserID FROM Mo_UserGroupDtl WHERE UserID = @UserID AND UserGroupID = @UserGroupID)
  BEGIN
    /* Création de l'utiliateur dans Mo_User */
    INSERT INTO Mo_UserGroupDtl (
      UserID,
      UserGroupID)
 	  VALUES (
			@UserID,
      @UserGroupID);

    IF (@@ERROR <> 0) 
      SET @UserID = 0
    ELSE
    BEGIN
      SELECT @UserName = LastName+', '+FirstName
      FROM dbo.Mo_Human 
      WHERE HumanID = @UserID;

      SELECT @UserGroupDesc = UserGroupDesc
      FROM Mo_UserGroup
      WHERE UserGroupID = @UserGroupID;

      SET @LogDesc = @UserName+'('+CAST(@UserID AS VARCHAR)+') <-> '+@UserGroupDesc+'('+CAST(@UserGroupID AS VARCHAR)+')';
      EXEC IMo_Log @ConnectID, 'Mo_UserGroupDtl', @UserID, 'I', @LogDesc;
    END;
  END;

  IF (@UserID <> 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  RETURN @UserID;
END;


