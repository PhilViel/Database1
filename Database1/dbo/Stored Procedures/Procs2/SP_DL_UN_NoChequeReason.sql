
/******************************************************************************
	Destruction d'une raison de ne pas commander de chèques
******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
******************************************************************************/
CREATE PROCEDURE SP_DL_UN_NoChequeReason (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager qui fait l'opération
	@NoChequeReasonID INTEGER) -- ID unique de la raison de résiliation
AS
BEGIN
	-- >0 : La suppression a réussie (Correspond au ID de l'enregistrement supprimé)
	-- -1 : La suppression a échouée
	-- -2 : Déjà utilisé

	IF EXISTS (
			SELECT UnitReductionID 
			FROM Un_UnitReduction 
			WHERE NoChequeReasonID = @NoChequeReasonID)
		SET @NoChequeReasonID = -2
	ELSE
	BEGIN
		DELETE 
		FROM Un_NoChequeReason
		WHERE NoChequeReasonID = @NoChequeReasonID
	
		IF @@ERROR <> 0
			SET @NoChequeReasonID = -1
	END
	
	RETURN @NoChequeReasonID
END

