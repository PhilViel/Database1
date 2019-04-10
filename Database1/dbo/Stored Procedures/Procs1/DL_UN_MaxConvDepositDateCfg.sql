
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_MaxConvDepositDateCfg
Description         :	Supprime un enregistrement de configuration de date maximum pour les dépôts d'une convention
Valeurs de retours  :		>0 : Suppression réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001270	IA	2006-03-26	Alain Quirion		Modification. CHangement de nom et suppresion du ConnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_MaxConvDepositDateCfg (
	@MaxConvDepositDateCfgID INTEGER) -- ID unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0
	
	DELETE
	FROM Un_MaxConvDepositDateCfg
	WHERE MaxConvDepositDateCfgID = @MaxConvDepositDateCfgID
	
	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END

