/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_RepBossHistory_IU
Description         :	Fait les validations supérieur de représentant
Valeurs de retours  :	Dataset :
									Code		VARCHAR(3)		Code d'erreur
									Info1		VARCHAR(100)	Premier champ d'information
									Info2		VARCHAR(100)	Deuxième champ d'information
									Info3		VARCHAR(100)	Troisième champ d'information
Note                :						2006-07-12	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_RepBossHistory_IU] (
@RepBossHistID INTEGER,
@RepID INTEGER,
@BossID INTEGER, 
@RepRoleID CHAR(3),
@RepBossPct DECIMAL(10,4),
@StartDate DATETIME,
@EndDate DATETIME)
AS
BEGIN
	DECLARE @MaxDate DATETIME,
		@Total DECIMAL(10,4),
		@OldStartDate DATETIME,
		@OldEndDate DATETIME,
		@OldRepID INTEGER,
		@OldBossID INTEGER,
		@OldRepRoleID CHAR(3),
		@OldRepBossPct FLOAT

	-- R01 -> La date de début n’est pas identique au lendemain de la date de fin du supérieur précédent de même rôle.
	-- R02 -> Le pourcentage de commission pour une période est supérieure à 100,00%. 
	-- R03 -> Vous allez modifier l’historique dans le passé.
	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- R01 -> La date de début n’est pas identique au lendemain de la date de fin du supérieur précédent de même rôle
	SELECT @MaxDate = MAX(EndDate)
	FROM Un_RepBossHist
	WHERE RepID = @RepID
		AND RepRoleID = @RepRoleID
		AND RepBossHistID <> @RepBossHistID
		--AND RepBossHistID = 0		-- Lors d'ajout seulement

	SET @MaxDate = @MaxDate + 1

	IF @MaxDate <> @StartDate
	BEGIN
		INSERT INTO #WngAndErr
				SELECT 
					'R01',
					'',
					'',
					''
	END

	-- R02 -> Le pourcentage de commission pour une période est supérieure à 100,00%. 
	SELECT @Total = SUM(RepBossPct)
	FROM Un_RepBossHist
	WHERE RepID = @RepID
		AND RepRoleID = @RepRoleID			-- Même rôle
		AND ( (StartDate <= @StartDate
				AND ISNULL(EndDate, 0) = 0)	-- Supérieur en cours
			OR (StartDate <= @StartDate
				AND EndDate >= @StartDate)	
			OR (ISNULL(EndDate, 0) = 0
				AND ISNULL(@EndDate, 0) = 0))	-- Supérieur durant une partie de la période
		AND RepBossHistID <> @RepBossHistID 		-- Exclusion lors de mise a jour

	SET @Total = @Total + @RepBossPct

	IF @Total > 100
	BEGIN		
		INSERT INTO #WngAndErr
			SELECT 
				'R02',
				'',
				'',
				''
	END

	-- R03 -> Vous allez modifier l’historique dans le passé.	
	SELECT  @OldStartDate = StartDate,
		@OldEndDate = EndDate,
		@OldRepID = RepID,
		@OldBossID = BossID,
		@OldRepRoleID = RepRoleID,
		@OldRepBossPct = RepBossPct
	FROM un_RepBossHist
	WHERE RepBossHistID = @RepBossHistID	
	
	IF ((@StartDate < dbo.FN_CRQ_DateNoTime(GetDate())
		AND  @OldStartDate <> @StartDate )			-- Lorsqu’on aura modifié la date de début pour une date antérieure à la date du jour.
		OR (@StartDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @RepBossHistID = 0)				-- Lors d’ajout quand la date de début sera antérieure à la date du jour.
		OR (@OldStartDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND ( @OldRepID <> @RepID
				OR @OldBossID <> @BossID
				OR @OldRepRoleID <> @RepRoleID
				OR @OldRepBossPct <> @RepBossPct))	-- Lorsqu’on aura modifié n’importe laquelle des valeurs sauf la date de fin et que la date de début sera, avant modification, antérieure à la date du jour.
		OR (@EndDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @OldEndDate <> @EndDate
			AND @EndDate <> -2
			AND @RepBossHistID > 0)				-- Lorsqu’on aura modifié la date de fin pour une date antérieure à la date du jour.
		OR (@EndDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @OldEndDate IS NULL
			AND @EndDate <> -2
			AND @RepBossHistID > 0)				-- Lorsqu’on aura modifié la date de fin pour une date antérieure à la date du jour. Take 2
		OR (@OldEndDate < dbo.FN_CRQ_DateNoTime(GetDate())	
			AND @OldEndDate <> @EndDate
			AND @RepBossHistID > 0)				-- Lorsqu’on aura modifié la date de fin et qu’elle sera, avant modification, antérieure à la date du jour.	
		)
	BEGIN
		INSERT INTO #WngAndErr
			SELECT 
				'R03',
				'',
				'',
				''
	END

	
	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END


