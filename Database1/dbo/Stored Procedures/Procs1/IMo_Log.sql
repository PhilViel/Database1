
/****************************************************************************************************
Code de service		:		IMo_Log
Nom du service		:		IMo_Log
But					:		
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@ConnectID 
						@LogTableName
						@LogCodeID   
						@LogActionID 
						@LogText     

Exemple d'appel:
							
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													RETURN (0)
													RETURN (-1)

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()

 ****************************************************************************************************/


CREATE PROCEDURE [dbo].[IMo_Log]
 (@ConnectID          MoID,
  @LogTableName       MoDesc,
  @LogCodeID          MoIDOption,
  @LogActionID        MoLogAction,
  @LogText            MoTextOption)
AS
BEGIN
  IF (@ConnectID <> 0)
  BEGIN
    INSERT INTO Mo_Log
     (ConnectID,
      LogTableName,
      LogCodeID ,
      LogActionID,
      LogText)
    VALUES
     (@ConnectID,
      @LogTableName,
      @LogCodeID,
      @LogActionID,
      @LogText);

    IF (@@ERROR = 0)
      RETURN SCOPE_IDENTITY();
    ELSE
      RETURN (0);
  END
  ELSE
    RETURN (-1);
END;
