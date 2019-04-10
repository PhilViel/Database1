
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_MaxConvDepositDateCfg
Description         :	Sauvegarde un enregistrement de configuration de date maixumu pour les dépôts d'une convention
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-06	Bruno Lapointe		Création
						ADX0001270	IA	2006-03-26	Alain Quirion		Modification. CHangement de nom
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_MaxConvDepositDateCfg (
	@ConnectID INTEGER,					-- ID unique de connexion de l'usager qui fait l'opération
	@MaxConvDepositDateCfgID INTEGER,	-- ID unique de l'enregistrement à insérer (=0) ou modifier (<>0)
	@EffectDate DATETIME,				-- Date d'effectivité de la configuration versus la date de vigueur de la convention qui est la plus petite des groupes d'unités (Un_Unit.InForceDate)
	@YearQty INTEGER )					-- Le nombre d'année ou l'on peut déposé de l'argent dans la convention après la date de vigueur
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @MaxConvDepositDateCfgID <= 0
	BEGIN
		INSERT INTO Un_MaxConvDepositDateCfg (
			EffectDate,
			YearQty )
		VALUES (
			@EffectDate,
			@YearQty )
	
		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MaxConvDepositDateCfg', @iResult, 'I', '' -- Trace l'insertion
		END			
	END
	ELSE
	BEGIN
		UPDATE Un_MaxConvDepositDateCfg
		SET
			EffectDate = @EffectDate,
			YearQty    = @YearQty 
		WHERE MaxConvDepositDateCfgID = @MaxConvDepositDateCfgID
	
		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
		BEGIN
			SET @iResult = @MaxConvDepositDateCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MaxConvDepositDateCfg', @iResult, 'U', '' -- Trace mise à jour
		END
	END
	
	RETURN @iResult
END

