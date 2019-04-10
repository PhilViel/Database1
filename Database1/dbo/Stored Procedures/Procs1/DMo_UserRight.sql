CREATE PROCEDURE [dbo].[DMo_UserRight]
 (@ConnectID            MoID,
  @UserID               MoID,
  @RightID              MoID)
AS
BEGIN
  DECLARE 
		@LogDesc MoDesc,
		@UserName MoDesc,
		@RightCode MoDesc;

  BEGIN TRANSACTION

  DELETE 
  FROM Mo_UserRight  
  WHERE (RightID = @RightID)
    AND (UserID = @UserID);

  IF (@@ERROR = 0)
  BEGIN
    SELECT @UserName = LastName+', '+FirstName
    FROM dbo.Mo_Human
    WHERE HumanID = @UserID;

    SELECT @RightCode = RightCode
    FROM Mo_Right
    WHERE RightID = @RightID;

    SET @LogDesc = @UserName+'('+CAST(@UserID AS VARCHAR)+') <-> '+@RightCode+'('+CAST(@RightID AS VARCHAR)+')';
    EXEC IMo_Log @ConnectID, 'Mo_UserRight', @UserID, 'D', @LogDesc;

    COMMIT TRANSACTION
    RETURN (@UserID);
  END
  ELSE
  BEGIN
    ROLLBACK TRANSACTION
    RETURN (0);
  END
END
