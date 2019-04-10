
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	DL_UN_RepFormationFeeCfg
Description         :	Suppression d’une configuration de frais de formations
Valeurs de retours  :	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Note                :	ADX0001257	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_RepFormationFeeCfg(
	@RepFormationFeeCfgID INTEGER)		
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	DELETE 
	FROM Un_RepFormationFeeCfg
	WHERE RepFormationFeeCfgID = @RepFormationFeeCfgID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END

