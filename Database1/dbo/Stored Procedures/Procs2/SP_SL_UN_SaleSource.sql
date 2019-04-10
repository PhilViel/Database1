/****************************************************************************************************
	Renvoi la liste des sources de ventes inscrites au système.
 ******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_SaleSource] (
	@SaleSourceID INTEGER) -- Id unique de la source de vente (0 = tous)
AS
BEGIN
	SELECT 
		SaleSourceID,
		SaleSourceDesc
	FROM Un_SaleSource
	WHERE @SaleSourceID = SaleSourceID
		OR @SaleSourceID = 0
	ORDER BY SaleSourceDesc
END

