/****************************************************************************************************
	Sélection des enregistrements de configuration du traitement automatique des 
	CPA.
 ******************************************************************************
	2004-10-22 Bruno Lapointe
		Création
		IA-ADX0000532(12.56)
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_AutomaticDepositTreatmentCfg] (
	@TreatmentDay UnTreatmentDay) -- Jour de prélèvement : 1=Dimanche, 2=Lundi, 3=Mardi, 4=Mercredi, 5=Jeudi, 6=Vendredi et 7=Samedi (0 = Tous)
AS
BEGIN
	DECLARE 
		@LastBankFileEndDate DATETIME

	-- Va chercher le dernier jour traité, si c'est le premier fichier traité ce sera la date du jour
	SET @LastBankFileEndDate = dbo.fn_Mo_DateNoTime(GETDATE())
	SELECT
		@LastBankFileEndDate = MAX(BankFileEndDate)
	FROM Un_BankFile

	SELECT
		TreatmentDay,
		TreatmentDayDesc =
			CASE TreatmentDay
				WHEN 1 THEN 'Dimanche'
				WHEN 2 THEN 'Lundi'
				WHEN 3 THEN 'Mardi'
				WHEN 4 THEN 'Mercredi'
				WHEN 5 THEN 'Jeudi'
				WHEN 6 THEN 'Vendredi'
				WHEN 7 THEN 'Samedi'
			END,
		DaysAfterToTreat,
		DaysAddForNextTreatment,
		LastBankFileEndDate = @LastBankFileEndDate
	FROM Un_AutomaticDepositTreatmentCfg
	WHERE @TreatmentDay = TreatmentDay
		OR @TreatmentDay = 0
END

