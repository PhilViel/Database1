
CREATE PROCEDURE [dbo].[DMo_User]
  (@ConnectID   MoID,
   @UserID     MoID)
AS
BEGIN
  DECLARE
    @ResultID    MoIDOption,
    @CanDelete	MoID;

  SET @ResultID = @UserID;
  SET @CanDelete = 0;

  BEGIN TRANSACTION;

  IF EXISTS (SELECT *
             FROM Mo_Connect
             WHERE (UserID = @UserID) )
  BEGIN
    IF EXISTS (SELECT *
               FROM Mo_Connect C
                 JOIN Mo_Log L ON (L.ConnectID = C.ConnectID)
               WHERE (UserID = @UserID) )

      DELETE FROM Mo_Log
      WHERE EXISTS (SELECT *
                    FROM Mo_Connect C
                    WHERE (C.ConnectID = Mo_Log.ConnectID)
                      AND (UserID = @UserID) );

    DELETE FROM Mo_Connect WHERE (UserID = @UserID);
  END;

  EXEC @ResultID = DMo_NoteWithClassName
    @ConnectID,
    @UserID,
    'TMOUSER,TMOUSERS'

  IF (@@ERROR <> 0) OR (@ResultID = 0)
    GOTO ON_ERROR_USER;

  DELETE FROM Mo_UserGroupDtl
  WHERE (UserID = @UserID);

  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  DELETE FROM Mo_UserRight
  WHERE (UserID = @UserID);
/*
  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  DELETE FROM Mo_ContactUser
  WHERE (UserID = @UserID);
*/
  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  DELETE FROM Mo_User
  WHERE (UserID = @UserID);

  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  DELETE FROM dbo.Mo_Human
  WHERE (HumanID = @UserID);

  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  DELETE FROM dbo.Mo_Adr 
  WHERE (SourceID = @UserID)
    AND (AdrTypeID = 'H');

  IF (@@ERROR <> 0)
    GOTO ON_ERROR_USER;

  EXEC IMo_Log @ConnectID, 'Mo_Users', @UserID, 'D', '';

  COMMIT TRANSACTION;
  RETURN(@ResultID);

  ON_ERROR_USER:
  BEGIN
    ROLLBACK TRANSACTION;
    RETURN(-1);
  END;
END;


