
/******************************************************************************
	Suppression d'arrêt de paiement sur convention
 ******************************************************************************
	2004-06-09 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE SP_DL_UN_Breaking (
	@ConnectID INTEGER, -- ID Unique de connexion de l'usager
	@BreakingID INTEGER) -- ID unique de l'arrêt de paiement sur convention
AS
BEGIN
	-- -1 = Erreur lors de la suppression de l'arrêt de paiement sur convention

	DELETE 
	FROM Un_Breaking
	WHERE BreakingID = @BreakingID

	IF @@ERROR = 0
		RETURN 1
	ELSE
		RETURN -1
END;


