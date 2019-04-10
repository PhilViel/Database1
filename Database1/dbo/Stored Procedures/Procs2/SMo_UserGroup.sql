
/****************************************************************************************************
Code de service		:		SMo_UserGroup
Nom du service		:		
But					:		
Description			:		

Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------
						@ConnectID					MoID
						@UserGroupID				MoID

Exemple d'appel:
				EXECUTE dbo.SMo_UserGroup 2, 0
		
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
						Mo_UserGroup				UserGroupID
													UserGroupDesc
                    
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2009-10-13					Jean-François Gauthier					Création de l'entête
					
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[SMo_UserGroup]
 (@ConnectID            MoID,
  @UserGroupID          MoID)
AS
	BEGIN
		SELECT 
			UserGroupID,
			UserGroupDesc
		FROM 
			dbo.Mo_UserGroup  
		WHERE 
			(UserGroupID = @UserGroupID) 
			OR 
			(@UserGroupId=0)
	END
