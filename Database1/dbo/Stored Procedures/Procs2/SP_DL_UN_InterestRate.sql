
/******************************************************************************
	Suppression d'un enregistrement de configuration de taux d'intérêt
 ******************************************************************************
	2004-10-29 Bruno Lapointe
		Migration, documentation et normalisation
		BR-ADX0001130
 ******************************************************************************/
CREATE PROCEDURE SP_DL_UN_InterestRate (
	@ConnectID MoID,
	@InterestRateID MoID)
AS
BEGIN
	-- Valeur de retour
	-- >0  : La suppression réussi, correspond au ID de l'enregistrement supprimé
	-- <=0 : La suppression a échoué
	--		-1 : Le calcul d'intérêt pour cette période a déjà été fait
	--		-2 : Erreur à la suppression dansa la table Un_InterestRate

	-- Vérifie si le calcul d'intérêt pour cette période a déjà été fait
	IF EXISTS (
			SELECT InterestRateID
			FROM Un_InterestRate
			WHERE InterestRateID = @InterestRateID
			  AND ISNULL(OperID,0) > 0)
		SET @InterestRateID = -1

	-- Supprime l'enregistrement
	IF @InterestRateID > 0
		DELETE
		FROM Un_InterestRate
		WHERE InterestRateID = @InterestRateID

	IF @@ERROR <> 0
		SET @InterestRateID = -2

	RETURN @InterestRateID
END

