
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	IU_UN_SubscriberAgeLimitCfg
Description         :	Sauvegarde un enregistrement de configuration des plafonds des bénéficiaires
Valeurs de retours  :		>0 : Sauvegarde réussie
							<=0 : Erreur SQL

Note                :	ADX0000472	IA	2005-02-04	Bruno Lapointe		Création
						ADX0001268	IA	2007-03-26	Alain Quirion		Modification. CHangement de nom de la procédure
*********************************************************************************************************************/
CREATE PROCEDURE dbo.IU_UN_SubscriberAgeLimitCfg (
	@ConnectID INTEGER,					-- ID unique de connexion de l'usager
	@SubscriberAgeLimitCfgID INTEGER,	-- ID unique de l'enregistrement de configuration (0 = Nouveau)
	@EffectDate DATETIME,				-- Date d'effectivité des limites
	@MaxAgeForSubscInsur INTEGER,		-- Limite maximum d'âge du souscripteur pour l'assurance souscripteur
	@MinSubscriberAge INTEGER )			-- Limite minimum du souscripteur pour pouvoir prendre une convention
AS
BEGIN
	DECLARE @iResult INTEGER

	SET @iResult = 1

	IF @SubscriberAgeLimitCfgID <= 0
	BEGIN
		INSERT INTO Un_SubscriberAgeLimitCfg (
			EffectDate,
			MaxAgeForSubscInsur,
			MinSubscriberAge )
		VALUES (
			@EffectDate,
			@MaxAgeForSubscInsur,
			@MinSubscriberAge )

		IF @@ERROR <> 0
			SET @iResult = -1
		ELSE 
		BEGIN
			SET @iResult = SCOPE_IDENTITY()
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_SubscriberAgeLimitCfg', @iResult, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_SubscriberAgeLimitCfg
		SET
			EffectDate = @EffectDate,
			MaxAgeForSubscInsur = @MaxAgeForSubscInsur,
			MinSubscriberAge = @MinSubscriberAge
		WHERE SubscriberAgeLimitCfgID = @SubscriberAgeLimitCfgID

		IF @@ERROR <> 0
			SET @iResult = -2
		ELSE 
		BEGIN
			SET @iResult = @SubscriberAgeLimitCfgID
			EXECUTE SP_IU_CRQ_Log @ConnectID, 'Un_SubscriberAgeLimitCfg', @iResult, 'U', ''
		END
	END

	RETURN @iResult
END

