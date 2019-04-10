/****************************************************************************************************
	Procédure de sauvegarde d'ajout et modification de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_IU_UN_RepContestCfg] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@RepContestCfgID INTEGER, -- ID unique du concours
	@StartDate DATETIME, -- Date de début de la période couverte par le concours
	@EndDate DATETIME, -- Date de fin de la période couverte par le concours
	@ContestName VARCHAR(75), -- Nom du concours
	@RepContestType UnRepContestType) -- Chaîne de 3 caractères identifiant le type ('REC':Recrues, 'CBP':Club du président, 'DIR':Directeur, 'OTH':Autres)
AS
BEGIN
	IF @EndDate <= 0
		SET @EndDate = NULL

	IF @RepContestCfgID = 0
	BEGIN
		INSERT INTO Un_RepContestCfg (
			RepContestType,
			StartDate,
			EndDate,
			ContestName)
		VALUES (
			@RepContestType,
			@StartDate,
			@EndDate,
			@ContestName)

		IF @@ERROR = 0
		BEGIN
			SET @RepContestCfgID = IDENT_CURRENT('Un_RepContestCfg')
			EXEC IMo_Log @ConnectID, 'Un_RepContestCfg', @RepContestCfgID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_RepContestCfg 
		SET
			RepContestType = @RepContestType,
			StartDate = @StartDate,
			EndDate = @EndDate,
			ContestName = @ContestName
		WHERE RepContestCfgID = @RepContestCfgID

		IF @@ERROR = 0
			EXEC IMo_Log @ConnectID, 'Un_RepContestCfg', @RepContestCfgID, 'U', ''
		ELSE
			SET @RepContestCfgID = 0
	END

	RETURN @RepContestCfgID
END

