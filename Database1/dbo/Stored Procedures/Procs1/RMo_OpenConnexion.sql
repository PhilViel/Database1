
/****************************************************************************************************
Code de service		:		RMo_OpenConnexion
Nom du service		:		RMo_OpenConnexion
But					:		Ouverture d'une connexion 
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@LoginNameID
						@PassWordID 
						@StationName
						@IPAddress	

Exemple d'appel:
					
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@UserID        
													@UserName 
													@CodeID	
													@LangID 
													@ModulexVersion 
													@ApplicationVersion
													@MoTimeOut 
													@ConnectID        
						
Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-09-24					Jean-François Gauthier					Remplacement du @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[RMo_OpenConnexion]
/* Ouverture d'une connexion */
 (@LoginNameID           MoLoginName,
  @PassWordID            MoLoginName,
  @StationName           MoDescOption,
  @IPAddress		 MoDescOption,
  @UserID                MoID OUTPUT,
  @UserName              MoDescOption OUTPUT,
  @CodeID		 MoIDOption OUTPUT,
  @LangID                MoLang OUTPUT,
  @ModulexVersion        MoID OUTPUT,
  @ApplicationVersion    MoID OUTPUT,
  @MoTimeOut             MoID OUTPUT)
AS
BEGIN
  DECLARE
    @ConnectID MoID;

  SET @ConnectID = -1;

  SELECT
    @ModulexVersion = ModulexVersion,
    @ApplicationVersion = ApplicationVersion
  FROM Mo_Def;

  SELECT
    @UserID = UserID,
    @CodeID = CodeID
  FROM Mo_User
  WHERE (LoginNameID = @LoginNameID)
    AND (dbo.fn_Mo_Decrypt(PasswordID) = @PasswordID);

  IF ( @UserID IS NOT NULL)  AND ( @UserID <> 0 )
  BEGIN

    SELECT
      @UserName = FirstName + ' ' + LastName,
      @LangID = LangID
    FROM dbo.Mo_Human 
    WHERE HumanID=@UserID;

    IF @LangID = 'UNK'
      SET @LangID = 'ENU';

    BEGIN TRANSACTION

    INSERT INTO Mo_Connect (
      UserID,
      CodeID,
      StationName,
      IPAddress)
    VALUES (
      @UserID,
      @CodeID,
      @StationName,
      @IPAddress);

    IF (@@ERROR = 0)
    BEGIN
      SELECT @ConnectID = SCOPE_IDENTITY();

      COMMIT TRANSACTION
    END
    ELSE
    BEGIN
      SET @ConnectID = 0
      ROLLBACK TRANSACTION
    END
  END
  ELSE
  BEGIN
    SET @ConnectID = 0
    SET @UserID = -1;
    SET @CodeID = -1;
    SET @UserName = ''
    SET @LangID = 'ENU'
  END

  RETURN @ConnectID;
END;


