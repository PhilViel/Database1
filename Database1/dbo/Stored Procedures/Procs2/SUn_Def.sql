
/******************************************************************************

  Description : Retourne les paramètres de configuration propre à l'application

  Variables : @ConnectID ID Unique de connexion de l'usager qui fait la sélection


 ******************************************************************************
	23-06-2003 Bruno           Modification et documentation
	27-06-2003 Bruno           Modification
	07-08-2003 Andre           Modification
	26-08-2003 Andre           Modification point 0729
	24-10-2003 Sylvain         Modification point 0756
	11-11-2003 Bruno           Modification #0778
	2004-10-12 Bruno Lapointe
		Correction temporaire pour bon focntionnement de UniSQL
		IA-ADX0000532(12.56)
	2004-10-22 Bruno Lapointe
		Correction temporaire pour bon focntionnement de UniSQL
		IA-ADX0000532(12.56)
 ******************************************************************************/
CREATE PROCEDURE SUn_Def
 (@ConnectID MoID)
AS
BEGIN
	DECLARE 
		@NbBankOpenDays INTEGER

	SELECT 
		@NbBankOpenDays = DaysAfterToTreat+DaysAddForNextTreatment
	FROM Un_AutomaticDepositTreatmentCfg
	WHERE DATEPART(dw, GETDATE()) = TreatmentDay

	SELECT
		MaxLifeCotisation,
		MaxYearCotisation,
		MaxLifeGovernmentGrant,
		MaxYearGovernmentGrant,
		YearQtyOfMaxYearCotisation,
		OpenDaysForBankTransaction = @NbBankOpenDays,
		ScholarshipMode,
		ScholarshipYear,
		GovernmentBN,
		MaxRepRisk,
		LastVerifDate,
		MaxPostInForceDate,
		MaxSubscribeAmountAjustmentDiff,
		ProjectionCount,
		ProjectionType,
		ProjectionOnNextRepTreatment,
		MaxFaceAmount,
		StartDateForIntAfterEstimatedRI,
		MonthNoIntAfterEstimatedRI,
		CESGWaitingDays
	FROM Un_Def
END

