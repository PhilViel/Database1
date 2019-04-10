/****************************************************************************************************
	Fonction d'arrondissement sur un montant avec taxe
*********************************************************************************
	2004-06-03 Bruno Lapointe
		Création
*********************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_TaxRounding (
	@Amount DECIMAL(24,10)) 
RETURNS MONEY
AS
BEGIN
	-- On conserve 2 décimales à la cenne et on les arrondit à la cenne supérieure 
	RETURN ( SELECT CEILING(ROUND(@Amount * 100, 2, 1)) / 100 )
END
