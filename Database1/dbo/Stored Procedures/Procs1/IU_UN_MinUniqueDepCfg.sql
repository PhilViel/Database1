

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_MinUniqueDepCfg
Description         :	Sauvegarde un enregistrement de configuration du minimum du dépôt pour un ajout d'unité avec
						modalité de paiement unique.
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-07	Bruno Lapointe		Création
						ADX0001277	IA	2007-03-27	Alain Quirion		Modification.  Changement de nom
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_MinUniqueDepCfg (
	@ConnectID INTEGER,			-- ID unique de connexion de l'usager qui fait l'opération
	@MinUniqueDepCfgID INTEGER,	--ID unique de l'enregistrement à insérer (=0) ou modifier (<>0)
	@EffectDate DATETIME,		-- Date d'effectivité de la configuration versus la date effective du groupe d'unités (Un_Unit.InForceDate)
	@MinAmount MONEY )			-- Montant minimum du dépôt unique de l'ajout d'unités
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @MinUniqueDepCfgID <= 0
	BEGIN
		INSERT INTO Un_MinUniqueDepCfg (
			EffectDate,
			MinAmount )
		VALUES (
			@EffectDate,
			@MinAmount )

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinUniqueDepCfg', @iResult, 'I', '' -- Trace l'insertion
		END			
	END
	ELSE
	BEGIN
		UPDATE Un_MinUniqueDepCfg
		SET
			EffectDate  = @EffectDate,
			MinAmount   = @MinAmount 
		WHERE MinUniqueDepCfgID = @MinUniqueDepCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE
		BEGIN
			SET @iResult = @MinUniqueDepCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_MinUniqueDepCfg', @iResult, 'U', '' -- Trace de la mise à jour
		END	
	END
	
	RETURN @iResult
END

