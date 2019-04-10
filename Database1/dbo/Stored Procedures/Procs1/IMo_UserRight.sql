CREATE PROCEDURE [dbo].[IMo_UserRight]
 (@ConnectID            MoID,
  @UserID               MoID,
  @RightID              MoID,
  @Granted              MoBitTrue)
AS
BEGIN
  DECLARE 
		@LogDesc MoDesc,
		@UserName MoDesc,
		@RightCode MoDesc;

  BEGIN TRANSACTION

  IF NOT EXISTS (SELECT UserID FROM Mo_UserRight WHERE UserID = @UserID AND RightID = @RightID)
  BEGIN
    /* Création de l'utiliateur dans Mo_User */
    INSERT INTO Mo_UserRight (
      UserID,
      RightID,
      Granted)
 	  VALUES (
			@UserID,
      @RightID,
      @Granted);

    IF (@@ERROR <> 0) 
      SET @UserID = 0
    ELSE
    BEGIN
      SELECT @UserName = LastName+', '+FirstName
      FROM dbo.Mo_Human 
      WHERE HumanID = @UserID;

      SELECT @RightCode = RightCode
      FROM Mo_Right
      WHERE RightID = @RightID;

      SET @LogDesc = @UserName+'('+CAST(@UserID AS VARCHAR)+') <-> '+@RightCode+'('+CAST(@RightID AS VARCHAR)+')';
      IF @Granted <> 0
        SET @LogDesc = @LogDesc + 'Granted(True)' 
      ELSE
        SET @LogDesc = @LogDesc + 'Granted(False)';
      EXEC IMo_Log @ConnectID, 'Mo_UserRight', @UserID, 'I', @LogDesc;
    END;
  END
  ELSE IF NOT EXISTS (SELECT UserID FROM Mo_UserRight WHERE UserID = @UserID AND RightID = @RightID AND Granted = @Granted)
  BEGIN
    UPDATE Mo_UserRight SET 
      Granted = @Granted
    WHERE UserID = @UserID AND RightID = @RightID;

    IF (@@ERROR <> 0) 
      SET @UserID = 0
    ELSE
    BEGIN
      IF @Granted <> 0
        SET @LogDesc = 'Granted False -> True' 
      ELSE
        SET @LogDesc = 'Granted True -> False';
      EXEC IMo_Log @ConnectID, 'Mo_UserRight', @UserID, 'U', @LogDesc;
    END;     
  END;

  IF (@UserID <> 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  RETURN @UserID;
END;


