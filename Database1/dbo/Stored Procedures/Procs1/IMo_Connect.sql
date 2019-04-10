
/****************************************************************************************************
Code de service		:		IMo_Connect
Nom du service		:		IMo_Connect
But					:		
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID
						@UserID	
						@StationName
						@IPAddress	
						@ConnectEnd	

Exemple d'appel:
							
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ConnectID

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()

 ****************************************************************************************************/


CREATE PROCEDURE [dbo].[IMo_Connect]
 (@ConnectID            MoID,
  @UserID		MoID,  /*Key*/
  @StationName		MoDescOption,
  @IPAddress		MoDescOption,
  @ConnectEnd		MoDateOption  )
AS
BEGIN
DECLARE
	@ResultID	MoID,
	@iCodeID	MoIDOption,
	@iUserID	MoIDOption;

  BEGIN TRANSACTION;

  IF (@ConnectID = 0 )
  BEGIN
    /* Recherche User */
    SELECT
       @iUserID = UserID,
       @iCodeID = CodeID
    FROM Mo_User
    WHERE ( UserID = @UserID );

    IF ( @iUserID is NULL )
      GOTO ON_ERROR_CONNECT;

    INSERT INTO Mo_Connect (
        UserID,
				CodeID,
				StationName,
			 	IPAddress )
    VALUES (
				@UserID,
        @iCodeID,
				@StationName,
				@IPAddress);

    IF (@@ERROR = 0)
    BEGIN
      SELECT @ConnectID = SCOPE_IDENTITY();

      EXEC IMo_Log @ConnectID, 'Mo_Connect', @ConnectID, 'I', '';
    END
    ELSE
      SET @ConnectID = 0;
  END
  ELSE
  BEGIN
    UPDATE Mo_Connect SET
      ConnectEnd = @ConnectEnd
    WHERE ( ConnectID = @ConnectID );

    IF (@@ERROR <> 0)
      SET @ConnectID = 0
    ELSE
    BEGIN
      EXEC IMo_Log @ConnectID, 'Mo_Connect', @ConnectID, 'U', '';
    END
  END

  ON_ERROR_CONNECT:
  IF ( @ConnectID = 0)
    ROLLBACK TRANSACTION
  ELSE
    COMMIT TRANSACTION;

  RETURN  @ConnectID;
END;
