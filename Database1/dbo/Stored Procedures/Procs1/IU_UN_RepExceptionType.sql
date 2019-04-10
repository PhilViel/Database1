/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	IU_UN_RepExceptionType
Description         :	Procédure stockée permettant d’ajouter un Type d’exception sur 
			commission ou de mettre à jour un type d’exception sur commission.
Valeurs de retours  :	@ReturnValue :
			> 0 : [Réussite]
			<= 0 : [Échec].

Note			: ADX0001003	IA	2006-07-13	Mireya Gonthier
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_RepExceptionType] ( 
	@ConnectID MoID, 	-- ID unique de connexion
	@RepExceptionTypeID MoOptionCode, --Chaîne unique de 3 caractères identifiant le type de l'exception.
	@RepExceptionTypeDesc MoDesc, 	-- Description du type d'exception.
	@RepExceptionTypeTypeID UnRepExceptionTypeType)	-- Chaîne de 3 caractères décrivant sur quoi s'applique ce type d'exception.  
AS 
BEGIN   
	DECLARE   @Result MoIDOption  

	SET @Result = 1  
	----------------- 
	BEGIN TRANSACTION 
	-----------------   

	IF NOT EXISTS (	SELECT RepExceptionTypeID                   
			FROM Un_RepExceptionType                   
			WHERE RepExceptionTypeID = @RepExceptionTypeID)   
	BEGIN      
		INSERT INTO Un_RepExceptionType (       
			RepExceptionTypeID,       
			RepExceptionTypeDesc,        
			RepExceptionTypeTypeID,       
			RepExceptionTypeVisible)     
		VALUES (
			@RepExceptionTypeID,       
			@RepExceptionTypeDesc,       
			@RepExceptionTypeTypeID,       
			1)    -- Les insertions et mises à jour sont toujours visbiles lorqu'ajouté par l'usager
	END   
	ELSE   
	BEGIN      
		UPDATE Un_RepExceptionType 
			SET     
				RepExceptionTypeDesc = @RepExceptionTypeDesc,       
				RepExceptionTypeTypeID = @RepExceptionTypeTypeID 
			WHERE RepExceptionTypeID = @RepExceptionTypeID    
	END    

 	IF (@@ERROR <> 0)   
		SET @Result = -1   

	IF @Result = 1  

		------------------
		COMMIT TRANSACTION  
		------------------
	
	ELSE   
		--------------------
		ROLLBACK TRANSACTION   
		--------------------    
	
	RETURN @Result 
END


