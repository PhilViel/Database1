
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_MinDepositCfg
Description         :	Supprime un enregistrement de configuration du minimum d'épargnes et frais par dépôt pour les
						conventions.
Valeurs de retours  :		>0 : Suppression réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001273	IA	2007-03-26	Alain Quirion		Modification. Changement du nom et suppression du @ConnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_MinDepositCfg (
	@MinDepositCfgID INTEGER) -- ID unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_MinDepositCfg
	WHERE MinDepositCfgID = @MinDepositCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1
	
	RETURN @iResult
END

