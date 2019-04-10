/****************************************************************************************************
	Procédure de suppresssion de facteur de multiplication de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_DL_UN_RepContestUnitMultFactorCfg] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@RepContestUnitMultFactorCfgID INTEGER) -- ID unique du facteur de multiplication à supprimer
AS
BEGIN
	-- Valeur de retour :
	-- -1: Erreur de suppression 
	-- >0: Suppression réussi avec succès

	DECLARE
		@Result INTEGER

	DELETE 
	FROM Un_RepContestUnitMultFactorCfg
	WHERE RepContestUnitMultFactorCfgID = @RepContestUnitMultFactorCfgID

	IF @@ERROR = 0
		SET @Result = @RepContestUnitMultFactorCfgID
	ELSE
		SET @Result = -1

	RETURN @Result
END

