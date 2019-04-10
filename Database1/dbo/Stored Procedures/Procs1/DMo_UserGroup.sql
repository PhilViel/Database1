CREATE PROCEDURE DMo_UserGroup
 (@ConnectID            MoID,
  @UserGroupID          MoID)
AS
BEGIN
  DECLARE 
    @UserGroupDesc MoDesc;
  
  BEGIN TRANSACTION

  SELECT 
    @UserGroupDesc = UserGroupDesc  
  FROM Mo_UserGroup  
  WHERE (UserGroupID = @UserGroupID);

  DELETE 
  FROM Mo_UserGroup  
  WHERE (UserGroupID = @UserGroupID);

  IF (@@ERROR = 0)
  BEGIN
    EXEC IMo_Log @ConnectID, 'Mo_UserGroup', @UserGroupID, 'D', @UserGroupDesc;

    COMMIT TRANSACTION
    RETURN (@UserGroupID);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (0);
  END
END
