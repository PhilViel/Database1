
/****************************************************************************************************
Code de service		:		IMo_UserGroup
Nom du service		:		IMo_UserGroup
But					:		
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID          
						@UserGroupID        
						@UserGroupDesc      

Exemple d'appel:
							
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@UserGroupID

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()

 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[IMo_UserGroup]
 (@ConnectID            MoID,
  @UserGroupID          MoID,
  @UserGroupDesc        MoDesc)
AS
BEGIN
  DECLARE 
    @LogDesc MoDescOption,
    @OldUserGroupDesc MoDesc;

  BEGIN TRANSACTION

  IF (@UserGroupID = 0)
  BEGIN
    /* Création de l'utiliateur dans Mo_User */
    INSERT INTO Mo_UserGroup (
      UserGroupDesc)
 	  VALUES (
			@UserGroupDesc);

    IF (@@ERROR = 0) 
    BEGIN
      SET @UserGroupID = SCOPE_IDENTITY();
      EXEC IMo_Log @ConnectID, 'Mo_UserGroup', @UserGroupID, 'I', @UserGroupDesc;
    END;
  END
  ELSE
  BEGIN
    SELECT 
      @OldUserGroupDesc = UserGroupDesc
    FROM Mo_UserGroup
    WHERE (UserGroupID = @UserGroupID);

    UPDATE Mo_UserGroup SET
      UserGroupDesc = @UserGroupDesc
    WHERE (UserGroupID = @UserGroupID);


    IF @OldUserGroupDesc <> @UserGroupDesc
      SET @LogDesc = @OldUserGroupDesc+' -> '+@UserGroupDesc;
    ELSE
      SET @LogDesc = '';
 
    IF (@@ERROR <> 0) 
      SET @UserGroupID = 0
    ELSE
      EXEC IMo_Log @ConnectID, 'Mo_UserGroup', @UserGroupID, 'U', @LogDesc;
  END;

  IF (@UserGroupID <> 0)
    COMMIT TRANSACTION
  ELSE
    ROLLBACK TRANSACTION

  RETURN @UserGroupID;
END;
