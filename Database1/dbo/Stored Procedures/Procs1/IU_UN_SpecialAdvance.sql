/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_SpecialAdvance
Description         :	Procédure de sauvegarde d’ajout ou d'édition d'avance spécial.
Valeurs de retours  :	@ReturnValue :
						> 0 : La sauvegarde a réussie.  La valeur de retour correspond au 
							SpecialAdvanceID de l’avance spéciale sauvegardée.
						<= 0 : La sauvegarde a échouée.

Note                :	ADX0000735	IA	2005-07-19	Pierre-Michel Bussière	Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_SpecialAdvance (
	@ConnectID INTEGER, -- ID unique de l’usager qui a coché les groupes d’unités.
	@SpecialAdvanceID INTEGER, -- ID unique de l'avance spécial. (0 = ajout)
	@RepID INTEGER, -- ID du représentant.
	@EffectDate DATETIME, -- Date d'effectivité de l'avancement spéciale.
	@Amount MONEY, -- Montant de l'avance spéciale.
	@vcSpecialAdvanceDesc VARCHAR(100), -- Champ contenant la description justifiant l'avancement spéciale.
	@RepTreatmentID INTEGER) -- ID unique du traitement de commissions (Un_RepTreatment) qui a généré cette avance spéciale. Null = Entré manuelle.
AS
BEGIN
	IF ISNULL(@RepTreatmentID,0) <= 0
		SET @RepTreatmentID = NULL

	IF NOT EXISTS (
		SELECT SpecialAdvanceID
		FROM Un_SpecialAdvance
		WHERE SpecialAdvanceID = @SpecialAdvanceID)
	BEGIN
		-- Insertion de la valeur unitaire
		INSERT INTO Un_SpecialAdvance (
			RepID, -- ID du représentant.
			EffectDate, -- Date d'effectivité de l'avancement spéciale.
			Amount, -- Montant de l'avance spéciale.
			vcSpecialAdvanceDesc, -- Champ contenant la description justifiant l'avancement spéciale.
			RepTreatmentID ) -- ID unique du traitement de commissions (Un_RepTreatment) qui a généré cette avance spéciale. Null = Entré manuelle.
		VALUES (
			@RepID,
			@EffectDate,
			@Amount,
			@vcSpecialAdvanceDesc,
			@RepTreatmentID )

		IF @@ERROR <> 0
			SET @SpecialAdvanceID = -1
		ELSE
			SET @SpecialAdvanceID = SCOPE_IDENTITY()
	END
	ELSE
	BEGIN
		-- Modification de la valeur unitaire
		UPDATE Un_SpecialAdvance
		SET 	RepID = @RepID,
			EffectDate = @EffectDate,
			Amount = @Amount,
			vcSpecialAdvanceDesc = @vcSpecialAdvanceDesc,
			RepTreatmentID = @RepTreatmentID
		WHERE SpecialAdvanceID = @SpecialAdvanceID

		IF @@ERROR <> 0
			SET @SpecialAdvanceID = -2
	END

	RETURN @SpecialAdvanceID
END

