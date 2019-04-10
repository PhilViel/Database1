
/******************************************************************************
	Suppression d'une source de vente
 ******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE SP_DL_UN_SaleSource (
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@SaleSourceID INTEGER) -- Id unique de la source de vente
AS
BEGIN
	-- =1  : La suppression a réussie.
	-- =-1 : La suppression a échouée.
	DECLARE
		@ResultID INTEGER

	SET @ResultID = 1

	DELETE FROM Un_SaleSource
	WHERE SaleSourceID = @SaleSourceID

	IF @@ERROR <> 0
		SET @ResultID = -1

	RETURN @ResultID
END

