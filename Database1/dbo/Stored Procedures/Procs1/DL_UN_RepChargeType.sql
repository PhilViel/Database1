/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 	:	DL_UN_RepChargeType
Description         	:	Procédure de suppression d’un type d’ajustement ou de retenu
Valeurs de retours  	:	
				@ReturnValue :
						> 0 : [Réussite]
						<= 0 : [Échec].

Note			: ADX0000991	IA	2006-05-19	Alain Quirion			Création
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepChargeType] (
@RepChargeTypeID CHAR(3))
AS
BEGIN
	DECLARE @iReturn INTEGER
	SET @iReturn = 1
	
	DELETE 
	FROM Un_RepChargeType
	WHERE RepChargeTypeID = @RepChargeTypeID
	
	IF (@@ERROR <> 0)
		SET @iReturn = -1
	
	RETURN @iReturn
END


