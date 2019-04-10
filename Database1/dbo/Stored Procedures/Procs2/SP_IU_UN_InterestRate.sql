
/******************************************************************************
	Sauvegarde l'ajout ou l'édition d'enregistrement de configuration des taux 
	d'intérêts.
 ******************************************************************************
	2004-10-29 Bruno Lapointe
		Migration, documentation et normalisation
		BR-ADX0001130
 ******************************************************************************/
CREATE PROCEDURE SP_IU_UN_InterestRate (
	@ConnectID MoID, -- ID unique de connexion de l'usager
	@InterestRateID MoID, -- ID unique de l'enregistrement (0=ajout)
	@YearPeriod MoID, -- Année couverte
	@MonthPeriod MoID, -- Mois couvert
	@InterestRate MoPct100, -- Taux d'intérêt pour l'int. RI, l'int. individuel et l'int. TIN
	@GovernmentGrantInterestRate MoPct100) -- Taux d'intérêt pour l'int. RI, l'int. individuel et l'int. TIN
AS
BEGIN
	-- Valeur de retour
	-- >0  : La sauvegarde a réussi
	-- <=0 : La sauvegarde a échoué
	--		0  : Erreur SQL à la sauvegarde.
	--		-1 : Il existe déjà un enregistrement pour ce mois de cette année.

	IF @InterestRateID = 0
	BEGIN
		-- Vérifie qu'il existe déjà un enregistrement pour ce mois de cette année.
		IF EXISTS (
				SELECT InterestRateID
				FROM Un_InterestRate
				WHERE YearPeriod = @YearPeriod
				  AND MonthPeriod = @MonthPeriod)
			SET @InterestRateID = -1
		ELSE
		BEGIN
			-- Fait l'ajout
			INSERT INTO Un_InterestRate(
				YearPeriod, 
				MonthPeriod, 
				InterestRate, 
				GovernmentGrantInterestRate)
			VALUES (
				@YearPeriod, 
				@MonthPeriod, 
				@InterestRate, 
				@GovernmentGrantInterestRate)

			IF @@ERROR = 0
				SET @InterestRateID = IDENT_CURRENT('Un_InterestRate')
			ELSE
				SET @InterestRateID = 0
		END
	END
	ELSE
	BEGIN
		-- Mise à jour de l'enregistrement
		UPDATE Un_InterestRate 
		SET 
			YearPeriod = @YearPeriod,
			MonthPeriod = @MonthPeriod,
			InterestRate = @InterestRate,
			GovernmentGrantInterestRate = @GovernmentGrantInterestRate
		WHERE InterestRateID = @InterestRateID
	
		IF @@ERROR <> 0
			SET @InterestRateID = 0
	END

	RETURN @InterestRateID
END

