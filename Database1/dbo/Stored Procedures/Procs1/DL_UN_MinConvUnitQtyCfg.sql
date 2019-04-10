
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_MinConvUnitQtyCfg
Description         :	Supprime un enregistrement de configuration du minimum d'unités pour une convention
Valeurs de retours  :		>0 : Suppression réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001272	IA	2006-03-26	Alain Quirion		Modification. Changement de nom et suppresion du paramètre d'entrée ConnectID
*********************************************************************************************************************/
CREATE PROCEDURE dbo.DL_UN_MinConvUnitQtyCfg (
	@MinConvUnitQtyCfgID INTEGER) -- ID unique de l'enregistrement à supprimer
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = 0

	DELETE
	FROM Un_MinConvUnitQtyCfg
	WHERE MinConvUnitQtyCfgID = @MinConvUnitQtyCfgID

	IF @@ERROR <> 0
		SET @iResult = -1
	ELSE
		SET @iResult = 1

	RETURN @iResult
END



-- Suppression de l'ancienne procédure stockée si elle existe
IF EXISTS (
		SELECT name 
		FROM sysobjects 
		WHERE name = 'SP_DL_UN_MinDepositCfg' 
		  AND type = 'P')
	DROP PROCEDURE dbo.SP_DL_UN_MinDepositCfg

