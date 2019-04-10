
/******************************************************************************
	Destruction d'une raison de résiliation
******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
******************************************************************************/
CREATE PROCEDURE SP_DL_UN_UnitReductionReason (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager qui fait l'opération
	@UnitReductionReasonID INTEGER) -- ID unique de la raison de résiliation
AS
BEGIN
	-- >0 : La suppression a réussie (Correspond au ID de l'enregistrement supprimé)
	-- -1 : La suppression a échouée
	-- -2 : Déjà utilisé

	IF EXISTS (
			SELECT UnitReductionID 
			FROM Un_UnitReduction 
			WHERE UnitReductionReasonID = @UnitReductionReasonID)
		SET @UnitReductionReasonID = -2
	ELSE
	BEGIN
		DELETE 
		FROM Un_UnitReductionReason
		WHERE UnitReductionReasonID = @UnitReductionReasonID
	
		IF @@ERROR <> 0
			SET @UnitReductionReasonID = -1
	END

	RETURN @UnitReductionReasonID
END

