
/****************************************************************************************************
Code de service		:		IU_UN_RepLevel
Nom du service		:		IU_UN_RepLevel
But					:		Procédure d'ajout et de mise à jour des niveaux des représentants
Facette				:		
Reférence			:		

Parametres d'entrée :	Parametres					Description
		                ----------                  ----------------
						@IPAddress	

Exemple d'appel:
					
		
Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------
													@ReturnValue :
														> 0 : [Réussite]
														<= 0 : [Échec]

Historique des modifications :
			
		Date						Programmeur								Description							Référence
		----------					-------------------------------------	----------------------------		---------------
		2006-05-19					Mireya Gonthier							Création							ADX0000993	IA
		2009-09-24					Jean-François Gauthier					Remplacement de @@Identity par Scope_Identity()
 ****************************************************************************************************/

CREATE PROCEDURE [dbo].[IU_UN_RepLevel] ( 
	@ConnectID MoID, 
	@RepLevelID MoID, 
	@RepRoleID MoOptionCode, 
	@LevelDesc MoDesc, 
	@TargetUnit MoMoney, 
	@ConservationRate MoPctPos, 
	@LevelShortDesc MoDescOption)  
AS 
BEGIN    

	-----------------
	BEGIN TRANSACTION    
	-----------------

	IF @RepLevelID = 0   
	BEGIN   
		INSERT INTO Un_RepLevel (       
			RepRoleID,       
			LevelDesc,       
			TargetUnit,       
			ConservationRate,       
			LevelShortDesc)     
		VALUES (       
			@RepRoleID,       
			@LevelDesc,       
			@TargetUnit,       
			@ConservationRate,       
			@LevelShortDesc) 
		IF @@ERROR = 0     
		BEGIN       
	  		SELECT @RepLevelID = SCOPE_IDENTITY();       
	  		EXEC IMo_Log @ConnectID, 'Un_RepLevel', @RepLevelID, 'I', ''    
		END     
		ELSE       
	   		SET @RepLevelID = -1    
	END  
	ELSE   
	BEGIN    
		UPDATE Un_RepLevel SET	
			RepRoleID = @RepRoleID,       
			LevelDesc = @LevelDesc,       
			TargetUnit = @TargetUnit,       
			ConservationRate = @ConservationRate,       
			LevelShortDesc = @LevelShortDesc     
		WHERE RepLevelID = @RepLevelID 

		IF @@ERROR = 0       
			EXEC IMo_Log @ConnectID, 'Un_RepLevel', @RepLevelID, 'U', ''   
		ELSE       
			SET @RepLevelID = -1;   
	END    
	IF @RepLevelID = -1     
		--------------------
		ROLLBACK TRANSACTION   
		--------------------
	ELSE    
		------------------   
		COMMIT TRANSACTION  
 		------------------
	RETURN @RepLevelID 
END
