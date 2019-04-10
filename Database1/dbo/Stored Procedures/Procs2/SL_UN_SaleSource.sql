
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom :			SL_UN_SaleSourceList
Description :	Renvoi la liste des sources de ventes inscrites au système.
Valuer de retour : DataSet 
						 SaleSourceID		INTEGER ID de la source de vente
						 SaleSourceDesc		VARCHAR	Description de la source
						 bIsContestWinner	BIT		Indique s'il s'agit d'une source de type gagnant de concours

Notes :						2003-08-19	André           Point 0718
			ADX0001357	IA	2007-06-04	Alain Quirion	Ajout de bIsContestWinner					
 ******************************************************************************/
CREATE PROCEDURE dbo.SL_UN_SaleSource (
@SaleSourceID INTEGER)
AS
BEGIN
  SELECT SaleSourceID,
         SaleSourceDesc,
		 bIsContestWinner
  FROM Un_SaleSource
  ORDER BY SaleSourceDesc
END

