/****************************************************************************************************
	Procédure de sauvegarde d'ajout ou modification de prix de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_IU_UN_RepContestPriceCfg] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@RepContestPriceCfgID INTEGER, -- ID unique du prix
	@RepContestCfgID INTEGER, -- ID unique du concours au quel appartient le prix
	@ContestPriceName VARCHAR(75), -- Nom du prix
	@MinUnitQty MONEY, -- Nombre minimum de ventes nécessaire pour mériter ce prix
	@SectionColor INTEGER) -- Couleur utiliser pour identifier le prix lorsque qu'il est gagné.
AS
BEGIN
	-- Valeur de retour :
	-- 0  : Erreur lors de la sauvegarde
	-- >0 : La sauvegarde à réussi la valeur correspond au RepContestPriceCfgID du prix sauvegardé.
	IF @RepContestPriceCfgID = 0
	BEGIN
		INSERT INTO Un_RepContestPriceCfg (
			RepContestCfgID,
			ContestPriceName,
			MinUnitQty,
			SectionColor)
		VALUES (
			@RepContestCfgID,
			@ContestPriceName,
			@MinUnitQty,
			@SectionColor)

		IF @@ERROR = 0
		BEGIN
			SET @RepContestPriceCfgID = IDENT_CURRENT('Un_RepContestPriceCfg')
			EXEC IMo_Log @ConnectID, 'Un_RepContestPriceCfg', @RepContestPriceCfgID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_RepContestPriceCfg 
		SET
			RepContestCfgID = @RepContestCfgID,
			ContestPriceName = @ContestPriceName,
			MinUnitQty = @MinUnitQty,
			SectionColor = @SectionColor
		WHERE RepContestPriceCfgID = @RepContestPriceCfgID

		IF (@@ERROR = 0)
			EXEC IMo_Log @ConnectID, 'Un_RepContestPriceCfg', @RepContestPriceCfgID, 'U', ''
		ELSE
			SET @RepContestPriceCfgID = 0
	END

	RETURN @RepContestPriceCfgID
END

