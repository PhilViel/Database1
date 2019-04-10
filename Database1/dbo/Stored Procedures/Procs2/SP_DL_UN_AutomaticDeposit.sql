
/******************************************************************************
	Suppression d'horaires de prélèvement
 ******************************************************************************
	2004-06-09 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE SP_DL_UN_AutomaticDeposit (
	@ConnectID INTEGER, -- ID Unique de connexion d'usager
	@AutomaticDepositID INTEGER) -- ID Unique de l'horaire de prélèvement
AS
BEGIN
	-- -1 Erreur à la supression de l'horaire de prélèvement

	DELETE 
	FROM Un_AutomaticDeposit
	WHERE AutomaticDepositID = @AutomaticDepositID
	
	IF (@@ERROR = 0)
		RETURN @AutomaticDepositID
	ELSE
		RETURN -1
END

