/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 	:	DL_UN_RepLevelBracket
Description         	:	Procédure de suppression d’une configuration de tombée 
Valeurs de retours  	:	
				@ReturnValue :
						> 0 : [Réussite], ID de la configuration de tombée supprimée
						<= 0 : [Échec].

Note			: ADX0000994	IA	2006-05-25	Alain Quirion			Création
**********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_RepLevelBracket] (
@RepLevelBracketID INTEGER)	--Identifiant unique de la configuration
AS
BEGIN
	DECLARE @iReturn INTEGER
	
	SET @iReturn = 1
	
	DELETE 
	FROM Un_RepLevelBracket
	WHERE RepLevelBracketID = @RepLevelBracketID
	
	IF @@ERROR <> 0
		SET @iReturn = -1
		
	RETURN @iReturn
END


