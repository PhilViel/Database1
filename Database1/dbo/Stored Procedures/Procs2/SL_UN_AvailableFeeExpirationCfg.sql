
/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas inc
Nom 				:	SL_UN_AvailableFeeExpirationCfg
Description 		:	Renvoi la liste des configurations des expirations de frais disponibles
Valeurs de retour	:	Dataset :
							AvailableFeeExpirationCfgID	INTEGER		ID de la configuration
							StartDate					DATETIME	Date de début
							MonthAvailable				INTEGER		Expiration (en mois)

Notes				:	ADX0001253	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************/
CREATE PROCEDURE dbo.SL_UN_AvailableFeeExpirationCfg
AS
BEGIN
	SELECT
		AvailableFeeExpirationCfgID,	--ID de la configuration
		StartDate,						--Date de début
		MonthAvailable					--Expiration (en mois)
	FROM Un_AvailableFeeExpirationCfg
	ORDER BY StartDate DESC
END

