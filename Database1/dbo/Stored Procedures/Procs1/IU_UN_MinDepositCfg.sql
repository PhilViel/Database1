
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_MinDepositCfg
Description         :	Sauvegarde un enregistrement de configuration du minimum d'épargnes et de frais par dépôt
						pour les conventions.
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001273	IA	2007-03-26	Alain Quirion		Modification. Changement du nom
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_MinDepositCfg (
	@ConnectID INTEGER,			-- ID unique de connexion de l'usager qui fait l'opération
	@MinDepositCfgID INTEGER,	-- ID unique de l'enregistrement à insérer (=0) ou modifier (<>0)
	@PlanID INTEGER,			-- ID unique du plan (Universitas, Reeeflex, Individuel, etc.)
	@EffectDate DATETIME,		-- Date d'effectivité de la configuration versus la date effective du groupe d'unités (Un_Unit.InForceDate) 
	@ModalTypeID UnModalType,	-- Type de modalité (0 = Unique, 1 = Annuel, 2 = Semi-annuel, 4 = Trimestriel, 6 = Bi-Mensuel et 12 = Mensuel)
	@MinAmount MONEY)			-- Montant minimum d'épargnes et de frais par dépôt
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @MinDepositCfgID <= 0
	BEGIN
		INSERT INTO Un_MinDepositCfg (
			PlanID,
			EffectDate,
			ModalTypeID,
			MinAmount )
		VALUES (
			@PlanID,
			@EffectDate,
			@ModalTypeID,
			@MinAmount )

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinDepositCfg', @iResult, 'I', '' -- Trace l'insertion
		END
			
	END
	ELSE
	BEGIN
		UPDATE Un_MinDepositCfg
		SET
			PlanID = @PlanID,
			EffectDate = @EffectDate,
			ModalTypeID = @ModalTypeID,
			MinAmount = @MinAmount 
		WHERE MinDepositCfgID = @MinDepositCfgID

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = @MinDepositCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinDepositCfg', @iResult, 'U', '' -- Trace la mise à jour
		END
	END

	RETURN @iResult
END

