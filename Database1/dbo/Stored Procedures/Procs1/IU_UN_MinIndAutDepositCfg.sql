
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_MinIndAutDepositCfg
Description         :	Sauvegarde un enregistrement de configuration du minimum par prélèvement pour les prélèvements 
						automatiques des conventions individuelles.
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001275	IA	2007-03-27	Alain Quirion		Modification. Changement de nom
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_MinIndAutDepositCfg (
	@ConnectID INTEGER,				-- ID unique de connexion de l'usager qui fait l'opération
	@MinIndAutDepositCfgID INTEGER, -- ID unique de l'enregistrement à insérer (=0) ou modifier (<>0)
	@EffectDate DATETIME,			-- Date d'effectivité de la configuration versus la date effective du groupe d'unités (Un_Unit.InForceDate)
	@MinAmount MONEY )				-- Montant minimum du prélèvement sur conventions individuelles (Un_Plan.PlanTypeID = 'IND')
AS
BEGIN
	DECLARE @iResult INT
	
	SET @iResult = 1

	IF @MinIndAutDepositCfgID <= 0
	BEGIN
		INSERT INTO Un_MinIndAutDepositCfg (
				EffectDate,
				MinAmount)
		VALUES (
				@EffectDate,
				@MinAmount)
		
		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinIndAutDepositCfg', @iResult, 'I', '' -- Trace l'insertion
		END
	END
	ELSE
	BEGIN
		UPDATE Un_MinIndAutDepositCfg
		SET
			EffectDate  = @EffectDate,
			MinAmount   = @MinAmount 
		WHERE MinIndAutDepositCfgID = @MinIndAutDepositCfgID
	
		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
		BEGIN
			SET @iResult = @MinIndAutDepositCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinIndAutDepositCfg', @iResult, 'U', '' -- Trace de la mise à jour
		END
	END
	
	RETURN @iResult
END

