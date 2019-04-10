/****************************************************************************************************

	PROCEDURE RETOURNANT LE NOMBRE DE DOSSIERS D'UNE TABLE
*********************************************************************************
	01-04-2004 Dominic Létourneau
		Création de la stored procedure
*********************************************************************************/
CREATE PROCEDURE [dbo].[SL_CRQ_CountRecords] (
	@Table varchar(255), -- nom de la table où l'on lance la requête
	@Condition varchar(255) -- condition à effectuer dans la requête
)
AS

BEGIN

	-- Bâtit dynamiquement une requête selon une table et une condition  
	-- passées en paramètre pour effectuer un COUNT du nombre de dossiers
	EXEC ('SELECT nb_dossier = COUNT(*) FROM ' + @Table + ' WHERE ' + @Condition)

END


