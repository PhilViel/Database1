/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_CESPSendFile700Details
Description         :	Retourne le détail d’un fichier d’envoi au PCEE.
Valeurs de retours  :	Dataset :
									iNbConvention	INTEGER	Nombre de convention dans le fichier.
									fMarketValue	MONEY	Valeur marchande de toutes les conventions du fichier.
Note                :	ADX0000811	IA	2006-04-12	Bruno Lapointe	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_CESPSendFile700Details] (
	@iCESPSendFileID INTEGER ) -- ID du fichier d’envoi au PCEE.
AS
BEGIN
	SELECT
		iNbConvention = COUNT(ConventionID), -- Nombre de convention dans le fichier.
		fMarketValue = SUM(fMarketValue) -- Valeur marchande de toutes les conventions du fichier.
	FROM Un_CESP700
	WHERE iCESPSendFileID = @iCESPSendFileID
END

