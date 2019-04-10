/****************************************************************************************************
	Procédure de suppresssion de prix de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_DL_UN_RepContestPriceCfg] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@RepContestPriceCfgID INTEGER) -- ID unique du prix de concours à supprimer
AS
BEGIN
	-- Valeur de retour :
	-- -1: Erreur de suppression 
	-- >0: Suppression réussi avec succès
	
	DECLARE
		@Result INTEGER

	DELETE 
	FROM Un_RepContestPriceCfg
	WHERE RepContestPriceCfgID = @RepContestPriceCfgID

	IF @@ERROR = 0
		SET @Result = @RepContestPriceCfgID
	ELSE
		SET @Result = -1

	RETURN @Result
END

