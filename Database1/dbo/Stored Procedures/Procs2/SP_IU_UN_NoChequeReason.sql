/****************************************************************************************************
	Création ou modification d'une raison de ne pas commander de chèques
 ******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_NoChequeReason] (
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@NoChequeReasonID INTEGER, -- Id unique de la raison
	@NoChequeReason	VARCHAR(75), -- Description de la raison
	@NoChequeReasonActive BIT, -- 1 ou 0 (Active ou inactive)
	@NoChequeReasonImplicationID UnNoChequeReasonImplication) -- Implication (0: Aucunes, 1: RES à 0, 2: RES partiel)
AS
BEGIN
	IF @NoChequeReasonID = 0
	BEGIN
		INSERT INTO Un_NoChequeReason (
			NoChequeReason, 
			NoChequeReasonActive, 
			NoChequeReasonImplicationID)
		VALUES (
			@NoChequeReason, 
			@NoChequeReasonActive, 
			@NoChequeReasonImplicationID)

		IF @@ERROR = 0
		BEGIN
			SET @NoChequeReasonID = IDENT_CURRENT('Un_NoChequeReason')
			EXEC IMo_Log @ConnectID, 'Un_NoChequeReason', @NoChequeReasonID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_NoChequeReason 
		SET
			NoChequeReason = @NoChequeReason,
			NoChequeReasonActive = @NoChequeReasonActive,
			NoChequeReasonImplicationID = @NoChequeReasonImplicationID
		WHERE NoChequeReasonID = @NoChequeReasonID

		IF @@ERROR = 0
			EXEC IMo_Log @ConnectID, 'Un_NoChequeReason', @NoChequeReasonID, 'U', ''
		ELSE
			SET @NoChequeReasonID = 0
	END

	RETURN @NoChequeReasonID
END

