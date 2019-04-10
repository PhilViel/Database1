
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_CESP700OfConvention
Description         :	Rapport des enregistrements 700 pour une convention.  Les enregistrements 700 correspondent 
						aux valeurs marchandes.

Valeurs de retours  :	Dataset de données du rapport
Note                :	ADX0000650	IA	2005-02-03	Bruno Lapointe			Création
						ADX0001244	IA	2007-02-15	Alain Quirion			Modification : ajout de la colonne sur le nombre de conventions et changement du nom de la procédure
*********************************************************************************************************************/
CREATE PROCEDURE dbo.RP_UN_CESP700OfConvention (
	@ConventionID INTEGER ) -- Identificateur d'une convention
AS
BEGIN
	SELECT 
		S.vcCESPSendFile,
		S.dtCESPSendFile,
		G.fMarketValue
	FROM Un_CESP700 G
	JOIN Un_CESPSendFile S ON S.iCESPSendFileID = G.iCESPSendFileID
	WHERE G.ConventionID = @ConventionID
	ORDER BY vcCESPSendFile
END

