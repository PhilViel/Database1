﻿
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas
Nom                 :	DL_UN_RepBusinessBonusCfg
Description         :	Suppression d’une configuration de bonis d’affaires
Valeurs de retours  :	@ReturnValue :
							> 0 : [Réussite]
							<= 0 : [Échec].

Note                :	ADX0001260	IA	2007-03-23	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_RepBusinessBonusCfg(
	@RepBusinessBonusCfgID INTEGER)		
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	DELETE 
	FROM Un_RepBusinessBonusCfg
	WHERE RepBusinessBonusCfgID = @RepBusinessBonusCfgID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	RETURN @iResult
END

