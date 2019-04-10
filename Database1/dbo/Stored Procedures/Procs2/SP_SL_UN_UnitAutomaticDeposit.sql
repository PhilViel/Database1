/****************************************************************************************************
	Permet d'obtenir la liste des horaires de prélèvement sur groupe d'unités 
	d'un groupe en particulier.
 ******************************************************************************
	2004-06-09 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitAutomaticDeposit] (
	@UnitID INTEGER) -- ID Unique de groupe d'unités
AS
BEGIN
	SELECT 
		A.AutomaticDepositID,
		A.UnitID,
		A.StartDate,
		A.EndDate,
		A.FirstAutomaticDepositDate,
		A.TimeUnit,
		A.TimeUnitLap,
		A.CotisationFee,
		A.SubscInsur,
		A.BenefInsur,
		TaxOnInsur = dbo.FN_CRQ_TaxRounding((A.SubscInsur+A.BenefInsur)*ISNULL(ST.StateTaxPct, 0))
	FROM Un_AutomaticDeposit A
	JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN Mo_State ST ON ST.StateID = S.StateID
	WHERE A.UnitID = @UnitID
END


