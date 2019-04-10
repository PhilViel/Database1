
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_MinConvUnitQtyCfg
Description         :	Sauvegarde un enregistrement de configuration du minimum d'unités pour une convention
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001272	IA	2006-03-26	Alain Quirion		Modification. Changement de nom
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_MinConvUnitQtyCfg (
	@ConnectID INTEGER,				-- ID unique de connexion de l'usager qui fait l'opération
	@MinConvUnitQtyCfgID INTEGER,	-- ID unique de l'enregistrement à insérer (=0) ou modifier (<>0)
	@EffectDate DATETIME,			-- Date d'effectivité de la configuration versus la date de vigueur de la convention qui est la plus petite des groupes d'unités (Un_Unit.InForceDate) 
	@MinUnitQty MONEY)				-- Minimum d'unités de la convention
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @MinConvUnitQtyCfgID <= 0
	BEGIN
		INSERT INTO Un_MinConvUnitQtyCfg (
			EffectDate,
			MinUnitQty )
		VALUES (
			@EffectDate,
			@MinUnitQty )
	
		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinConvUnitQtyCfg', @iResult, 'I', '' -- Trace l'insertion
		END			
	END
	ELSE
	BEGIN
		UPDATE Un_MinConvUnitQtyCfg
		SET
			EffectDate = @EffectDate,
			MinUnitQty    = @MinUnitQty 
		WHERE MinConvUnitQtyCfgID = @MinConvUnitQtyCfgID
	
		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
		BEGIN
			SET @iResult = @MinConvUnitQtyCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinConvUnitQtyCfg', @iResult, 'U', '' -- Trace mise à jour
		END
	END
	
	RETURN @iResult
END

