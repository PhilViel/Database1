/****************************************************************************************************
Copyrights (c) 2006 Gestion Universitas inc
Nom                 :	DL_UN_RepExceptionType
Description         :	Procédure stockée de suppression d’un type d’exception sur commission.
Valeurs de retours  :	@ReturnValue :
			> 0 : [Réussite]
			<= 0 : [Échec].
																					
Note			: ADX0001003	IA	2006-07-13	Mireya Gonthier
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepExceptionType] ( 
	@ConnectID MoID, 
	@RepExceptionTypeID MoOptionCode) 
AS 
BEGIN    
	DECLARE   @Result MoIDOption  
	
	SET @Result = 1  

	-----------------  
	BEGIN TRANSACTION 
	-----------------   
	
	BEGIN
		DELETE 
		FROM Un_RepExceptionType   
		WHERE (RepExceptionTypeID = @RepExceptionTypeID)   
			
		 IF (@@ERROR <> 0)   
			SET @Result = -1   
	END 
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



