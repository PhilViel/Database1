/****************************************************************************************************
	Permet d'obtenir la liste des arrêts de paiements sur groupe d'unités d'un 
	groupe en particulier.
 ******************************************************************************
	2003-06-12 André Sanscartier
		Création
	2004-06-09 Bruno Lapointe
		Migration
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_UnitHoldPayment](
  @UnitID INTEGER) -- ID unique de l'unité
AS
BEGIN
	SELECT
		UnitHoldPaymentID,
		UnitID,
		StartDate,
		EndDate,
		Reason
	FROM Un_UnitHoldPayment
	WHERE UnitID = @UnitID
	ORDER BY 
		StartDate Desc
END

