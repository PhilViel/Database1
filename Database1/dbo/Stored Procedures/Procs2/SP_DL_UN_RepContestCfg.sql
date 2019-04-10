/****************************************************************************************************
	Procédure de suppresssion de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_DL_UN_RepContestCfg] (
	@ConnectID INTEGER,
	@RepContestCfgID INTEGER)
AS
BEGIN
	-- Valeur de retour :
	-- -1 : Erreur lors de la suppression du concours
	-- -2 : Erreur lors de la suppression des facteurs de multiplication du concours
	-- -3 : Erreur lors de la suppression des prix du concours
	-- >0 : La suppression a eu lieu avec succès

	DECLARE
		@Result INTEGER

	-- Suppression des prix rattachés
	DELETE 
	FROM Un_RepContestPriceCfg
	WHERE RepContestCfgID = @RepContestCfgID

	IF (@@ERROR = 0)
		SET @Result = @RepContestCfgID
	ELSE
		SET @Result = -3

	IF @Result > 0
	BEGIN
		-- Suppression des facteurs de multiplications rattachés
		DELETE 
		FROM Un_RepContestUnitMultFactorCfg
		WHERE RepContestCfgID = @RepContestCfgID
	
		IF (@@ERROR = 0)
			SET @Result = @RepContestCfgID
		ELSE
			SET @Result = -2
	END

	IF @Result > 0
	BEGIN
		-- Suppression du concours
		DELETE 
		FROM Un_RepContestCfg
		WHERE RepContestCfgID = @RepContestCfgID
	
		IF (@@ERROR = 0)
			SET @Result = @RepContestCfgID
		ELSE
			SET @Result = -1
	END

	RETURN @Result
END

