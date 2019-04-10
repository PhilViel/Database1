
/******************************************************************************
	Insertion d'ajouts/modifications d'enregistrement de configuration du 
	traitement automatique des CPA.
 ******************************************************************************
	2004-10-22 Bruno Lapointe
		Création
		IA-ADX0000532(12.56)
 ******************************************************************************/
CREATE PROCEDURE SP_IU_UN_AutomaticDepositTreatmentCfg (
	@ConnectID MoID, -- ID unique de connexion de l'usager
	@TreatmentDay UnTreatmentDay, -- Jour de prélèvement : 1=Dimanche, 2=Lundi, 3=Mardi, 4=Mercredi, 5=Jeudi, 6=Vendredi et 7=Samedi (Clef primaire unique)
	@DaysAfterToTreat INTEGER, -- Nombre de jour à additionner au jour courant pour connaître le dernier jour à traiter.
	@DaysAddForNextTreatment INTEGER) -- Nombre de jour à additionner à DaysAfterToTreat pour le prochain traitement de ce TreatmentDay.
AS
BEGIN
	-- Valeurs de retour
	-- >0  : Sauvegarde réussi.  Correspond au ID de l'enregistrement sauvegardé
	-- <=0 : Erreur

	IF NOT EXISTS ( -- Vérifie s'il y a un enregistrement pour ce jour de semaine.
			SELECT TreatmentDay
			FROM Un_AutomaticDepositTreatmentCfg
			WHERE @TreatmentDay = TreatmentDay)
	BEGIN
		INSERT INTO Un_AutomaticDepositTreatmentCfg (
			TreatmentDay,
			DaysAfterToTreat,
			DaysAddForNextTreatment)
		VALUES (
			@TreatmentDay,
			@DaysAfterToTreat,
			@DaysAddForNextTreatment)

		IF @@ERROR = 0
			-- Garde un log
			EXECUTE IMo_Log @ConnectID, 'Un_AutomaticDepositTreatmentCfg', @TreatmentDay, 'I', ''
		ELSE
			SET @TreatmentDay = 0
	END
	ELSE
	BEGIN
		UPDATE Un_AutomaticDepositTreatmentCfg 
		SET
			DaysAfterToTreat = @DaysAfterToTreat,
			DaysAddForNextTreatment = @DaysAddForNextTreatment
		WHERE TreatmentDay = @TreatmentDay

		IF @@ERROR = 0
			-- Garde un log
			EXECUTE IMo_Log @ConnectID, 'Un_AutomaticDepositTreatmentCfg', @TreatmentDay, 'U', ''
		ELSE
			SET @TreatmentDay = 0
	END

	RETURN @TreatmentDay
END

