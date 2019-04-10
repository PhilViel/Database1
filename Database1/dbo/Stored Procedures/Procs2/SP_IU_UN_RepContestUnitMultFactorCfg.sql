/****************************************************************************************************
	Procédure de sauvegarde d'ajout ou modification de facteur de multiplication
	de concours
 ******************************************************************************
	2004-09-07 Bruno Lapointe
		Création
 ******************************************************************************/
CREATE PROC [dbo].[SP_IU_UN_RepContestUnitMultFactorCfg] (
	@ConnectID INTEGER, -- ID unique de connexion de l'usager
	@RepContestUnitMultFactorCfgID INTEGER, -- ID unique du facteur de multiplication
	@RepContestCfgID INTEGER, -- ID unique du concours auquel appartient le facteur de multiplication
	@StartDate DATETIME, -- Date de début de la période sur laquel s'applique le facteur de multiplication
	@EndDate DATETIME, -- Date de fin de la période sur laquel s'applique le facteur de multiplication
	@RecruitUnitMultFactor DECIMAL(10,4), -- Facteur de multiplication des recrues
	@NonRecruitUnitMultFactor DECIMAL(10,4))  -- Facteur de multiplication des représentants autres que les recrues
AS
BEGIN
	-- Valeur de retour :
	-- 0  : Erreur lors de la sauvegarde
	-- >0 : La sauvegarde à réussi la valeur correspond au RepContestUnitMultFactorCfgID du facteur de multiplication sauvegardé.
	IF @EndDate <= 0
		SET @EndDate = NULL

	IF @RepContestUnitMultFactorCfgID = 0
	BEGIN
		INSERT INTO Un_RepContestUnitMultFactorCfg (
			RepContestCfgID,
			StartDate,
			EndDate,
			RecruitUnitMultFactor,
			NonRecruitUnitMultFactor)
		VALUES (
			@RepContestCfgID,
			@StartDate,
			@EndDate,
			@RecruitUnitMultFactor,
			@NonRecruitUnitMultFactor)

		IF @@ERROR = 0
		BEGIN
			SET @RepContestUnitMultFactorCfgID = IDENT_CURRENT('Un_RepContestUnitMultFactorCfg')
			EXEC IMo_Log @ConnectID, 'Un_RepContestUnitMultFactorCfg', @RepContestUnitMultFactorCfgID, 'I', ''
		END
	END
	ELSE
	BEGIN
		UPDATE Un_RepContestUnitMultFactorCfg 
		SET
			RepContestCfgID = @RepContestCfgID,
			StartDate = @StartDate,
			EndDate = @EndDate,
			RecruitUnitMultFactor = @RecruitUnitMultFactor,
			NonRecruitUnitMultFactor = @NonRecruitUnitMultFactor
		WHERE RepContestUnitMultFactorCfgID = @RepContestUnitMultFactorCfgID

		IF @@ERROR = 0
			EXEC IMo_Log @ConnectID, 'Un_RepContestUnitMultFactorCfg', @RepContestUnitMultFactorCfgID, 'U', ''
		ELSE
			SET @RepContestUnitMultFactorCfgID = 0
	END

	RETURN @RepContestUnitMultFactorCfgID
END

