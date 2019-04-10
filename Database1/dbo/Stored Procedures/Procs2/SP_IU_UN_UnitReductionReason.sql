/****************************************************************************************************
	Création ou modification d'une raison de résiliation
 ******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
	2008-07-30 Patrick Robitaille
		Ajout de la gestion du champ bReduitTauxConservationRep
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_IU_UN_UnitReductionReason] (
	@ConnectID INTEGER, -- Identificateur de la connection de l'usager
	@UnitReductionReasonID INTEGER, -- Id unique de la raison de résiliation
	@UnitReductionReason	VARCHAR(75), -- Description de la raison
	@UnitReductionReasonActive BIT, -- 1 ou 0 (Active ou inactive) 
	@bReduitTauxConservationRep BIT) -- 1 ou 0 (Diminue ou non le taux de conservation du rep)
AS
BEGIN
	IF @UnitReductionReasonActive = NULL
		SET @UnitReductionReasonActive = 1

	IF @bReduitTauxConservationRep = NULL
		SET @bReduitTauxConservationRep = 1

	IF @UnitReductionReasonID = 0
	BEGIN
		INSERT INTO Un_UnitReductionReason (
			UnitReductionReason, 
			UnitReductionReasonActive,
			bReduitTauxConservationRep)
		VALUES (
			@UnitReductionReason, 
			@UnitReductionReasonActive,
			@bReduitTauxConservationRep)
		
		IF @@ERROR = 0
		BEGIN
			SET @UnitReductionReasonID = IDENT_CURRENT('Un_UnitReductionReason')
			EXEC IMo_Log @ConnectID, 'Un_UnitReductionReason', @UnitReductionReasonID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_UnitReductionReason 
		SET
			UnitReductionReason = @UnitReductionReason,
			UnitReductionReasonActive  = @UnitReductionReasonActive,
			bReduitTauxConservationRep = @bReduitTauxConservationRep
		WHERE UnitReductionReasonID = @UnitReductionReasonID

		IF @@ERROR = 0
			EXEC IMo_Log @ConnectID, 'Un_UnitReductionReason', @UnitReductionReasonID, 'U', ''
		ELSE
			SET @UnitReductionReasonID = 0
  END

  RETURN @UnitReductionReasonID
END

