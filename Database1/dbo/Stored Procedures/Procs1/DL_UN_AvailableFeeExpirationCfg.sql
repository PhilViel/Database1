﻿
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	DL_UN_AvailableFeeExpirationCfg
Description         :	Supprime une configuration d’expiration des frais disponibles
Valeurs de retours  :	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Note                :	ADX0001253	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_AvailableFeeExpirationCfg(
	@AvailableFeeExpirationCfgID INTEGER)		
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	DELETE 
	FROM Un_AvailableFeeExpirationCfg
	WHERE AvailableFeeExpirationCfgID = @AvailableFeeExpirationCfgID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END

