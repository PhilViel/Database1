/****************************************************************************************************
	Retourne la liste des enregistrements de configuration des taux d'intérêts.
 ******************************************************************************
	2004-10-29 Bruno Lapointe
		Migration, documentation et normalisation
		BR-ADX0001130
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_InterestRate] (
	@InterestRateID INTEGER) -- ID unique d'un mois de taus d'intérêt. (0=tous)
AS
BEGIN
	SELECT 
		InterestRateID,
		YearPeriod,
		MonthPeriod,
		InterestRate,
		GovernmentGrantInterestRate,
		OperID
	FROM Un_InterestRate 
	WHERE @InterestRateID = InterestRateID
		OR @InterestRateID = 0
	ORDER BY 
		YearPeriod DESC,
		MonthPeriod DESC
END

