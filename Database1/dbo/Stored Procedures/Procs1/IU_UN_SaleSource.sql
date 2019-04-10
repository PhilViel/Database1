
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom :			SL_UN_SaleSourceList
Description :	Création ou modification d'une source de vente
Valuer de retour : @Result
					<= 0 Erreur
					> 0 ID de la source de vente	

							2004-09-01 Bruno Lapointe	Création
			ADX0001357	IA	2007-06-04	Alain Quirion	Ajout de bIsContestWinner
 ******************************************************************************/
CREATE PROCEDURE dbo.IU_UN_SaleSource (
	@SaleSourceID INTEGER, -- Id unique de la source de vente (0 = nouvelle)
	@SaleSourceDesc VARCHAR(75), -- Description de la source de vente
	@bIsContestWinner BIT)	--Indique s'il s'agit d'un gagnant de concours
AS
BEGIN
	-- >0 : La sauvegarde à réussi.  La valeur correspond au SaleSourceID de l'enregistrement sauvegarder.
	-- =0 : Erreur à la sauvegarde.
	DECLARE @iResult INTEGER

	IF @SaleSourceID <= 0
	BEGIN
		INSERT INTO Un_SaleSource (
			SaleSourceDesc,
			bIsContestWinner )
		VALUES (
			@SaleSourceDesc,
			@bIsContestWinner)

		IF @@ERROR = 0
			SET @iResult = SCOPE_IDENTITY()
		ELSE
			SET @iResult = -1
	END
	ELSE
	BEGIN
		UPDATE Un_SaleSource 
		SET	SaleSourceDesc = @SaleSourceDesc,
			bIsContestWinner = @bIsContestWinner
		WHERE SaleSourceID = @SaleSourceID

		IF @@ERROR = 0
			SET @iResult = @SaleSourceID
		ELSE
			SET @iResult = -2
	END

	RETURN @iResult
END

