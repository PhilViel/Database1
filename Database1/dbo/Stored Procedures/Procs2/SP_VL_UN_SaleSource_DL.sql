/****************************************************************************************************
	Vérification de la pertinence de la suppression d'une source de vente.
 ******************************************************************************
	2004-09-01 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_VL_UN_SaleSource_DL] (
	@SaleSourceID INTEGER) -- Id unique de la source de vente
AS
BEGIN
	-- 0  : On peut la supprimer.
	-- -1 : La source de ventes est utilisées pas des groupes d'unités on ne peut donc pas la supprimer.

	IF EXISTS (
			SELECT 
				UnitID
			FROM dbo.Un_Unit 
			WHERE SaleSourceID = @SaleSourceID)
		RETURN(-1)

	RETURN (0)
END


