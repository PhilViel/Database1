/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	DL_UN_RepLevel
Description         :	Procédure de suppression d'un niveau d'un représentant
Valeurs de retours  :	@ReturnValue :
				> 0 : [Réussite]
				<= 0 : [Échec].
				
				-1 : « Un ou plusieurs niveaux faisant parti de ce rôle sont utilisés dans des historiques de niveaux des représentants! »
				-2	: « Un ou plusieurs niveaux faisant parti de ce rôle sont utilisés dans les commissions! »

Note                :	ADX0000993	IA 	2006-05-19	Mireya Gonthier			Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepLevel] ( 
	@ConnectID MoID, 
	@RepLevelID MoID) 
AS 
BEGIN    
	DECLARE   
		@Result MoIDOption    
		
	SET @Result = 1   

	-- Vérifier que le niveau n'est pas utilisé dans les historiques de niveaux de représentants
	IF EXISTS (
		
		SELECT RepLevelID
		FROM Un_RepLevelHist
		WHERE RepLevelID = @RepLevelID
		)
		SET @Result = -1

	-- Vérifier que le niveau n'est pas utilisé dans les commissions
	IF EXISTS (
		SELECT RepLevelID
		FROM Un_RepBusinessBonus
		WHERE RepLevelID = @RepLevelID
		-----
		UNION
		-----
		SELECT RepLevelID
		FROM Un_RepCommission
		WHERE RepLevelID = @RepLevelID
		-----
		UNION
		-----
		SELECT RepLevelID
		FROM Un_RepException
		WHERE RepLevelID = @RepLevelID
		-----
		UNION
		-----
		SELECT RepLevelID
		FROM Un_RepProjection
		WHERE RepLevelID = @RepLevelID
		)
		IF @Result = 1
			SET @Result = -2

	-----------------
	BEGIN TRANSACTION   
	----------------- 
	
	IF @Result = 1
	BEGIN	
		DELETE 
		FROM Un_RepLevelBracket
		WHERE RepLevelID = @RepLevelID
		
		IF @@ERROR <> 0   
			SET @Result = -3   
	END

	IF @Result = 1
	BEGIN
		DELETE 
		FROM Un_RepLevel   
		WHERE RepLevelID = @RepLevelID

		IF @@ERROR <> 0   
			SET @Result = -4   
	END 

	if @Result = 1
		------------------
		COMMIT TRANSACTION
		------------------
   	ELSE     
		--------------------
		ROLLBACK TRANSACTION
		--------------------  
		   
   	RETURN (@Result) 
END



