CREATE PROCEDURE [dbo].[DMo_UserGroupDtl]
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

  DELETE 
  FROM Mo_UserGroupDtl  
  WHERE (UserGroupID = @UserGroupID)
    AND (UserID = @UserID);

  IF (@@ERROR = 0)
  BEGIN
    SELECT @UserName = LastName+', '+FirstName
    FROM dbo.Mo_Human
    WHERE HumanID = @UserID;

    SELECT @UserGroupDesc = UserGroupDesc
    FROM Mo_UserGroup
    WHERE UserGroupID = @UserGroupID;

    SET @LogDesc = @UserName+'('+CAST(@UserID AS VARCHAR)+') <-> '+@UserGroupDesc+'('+CAST(@UserGroupID AS VARCHAR)+')';
    EXEC IMo_Log @ConnectID, 'Mo_UserGroupDtl', @UserID, 'D', @LogDesc;

    COMMIT TRANSACTION
    RETURN (@UserID);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (0);
  END
END
