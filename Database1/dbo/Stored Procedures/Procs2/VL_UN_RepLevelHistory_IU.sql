/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	VL_UN_RepLevelHistory_IU
Description         :	Fait les validations supérieur de représentant
Valeurs de retours  :	Dataset :
									Code		VARCHAR(3)	Code d'erreur
									Info1		VARCHAR(100)	Premier champ d'information
									Info2		VARCHAR(100)	Deuxième champ d'information
									Info3		VARCHAR(100)	Troisième champ d'information
Note                :						2006-07-17	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[VL_UN_RepLevelHistory_IU] (
@RepLevelHistID INTEGER,
@RepLevelID INTEGER,
@RepID INTEGER,
@StartDate DATETIME,
@EndDate DATETIME)
AS
BEGIN
	DECLARE @MaxDate DATETIME,
		@Total INTEGER,
		@OldStartDate DATETIME,
		@OldEndDate DATETIME,
		@OldRepID INTEGER,
		@OldRepLevelID CHAR(3),
		@RepRoleID VARCHAR(3)

	SELECT @RepRoleID = RepRoleID
	FROM Un_RepLevel
	WHERE RepLevelID = @RepLevelID

	-- L01 -> La date de début n’est pas identique au lendemain de la date de fin du niveau précédent.
	-- L02 -> Il ne peut pas y avoir plus d’un niveau actif pour une même période.  
	-- L03 -> Vous allez modifier l’historique dans le passé.
	CREATE TABLE #WngAndErr(
		Code VARCHAR(3),
		Info1 VARCHAR(100),
		Info2 VARCHAR(100),
		Info3 VARCHAR(100)
	)

	-- L01 -> La date de début n’est pas identique au lendemain de la date de fin du niveau précédent.
	SELECT @MaxDate = MAX(RH.EndDate)
	FROM Un_RepLevelHist RH
	JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID
	WHERE RH.RepID = @RepID
		AND RL.RepRoleID = @RepRoleID
		AND RH.RepLevelHistID <> @RepLevelHistID
		--AND RepLevelHistID = 0		-- Lors d'ajout seulement

	SET @MaxDate = @MaxDate + 1

	IF @MaxDate <> @StartDate
	BEGIN
		INSERT INTO #WngAndErr
				SELECT 
					'L01',
					'',
					'',
					''
	END

	-- L02 -> Il ne peut pas y avoir plus d’un niveau actif pour une même période.  
	IF EXISTS(	SELECT RH.RepLevelHistID
			FROM Un_RepLevelHist RH			
			JOIN Un_RepLevel RL ON RL.RepLevelID = RH.RepLevelID
			WHERE RepID = @RepID	
				AND RL.RepRoleID = @RepRoleID	
				AND ( (RH.StartDate <= @StartDate
						AND ISNULL(RH.EndDate, 0) = 0)	-- Supérieur en cours
					OR (RH.StartDate <= @StartDate
						AND RH.EndDate >= @StartDate)	-- Supérieur durant une partie de la période
					OR (ISNULL(EndDate, 0) = 0
						AND ISNULL(@EndDate, 0) = 0))
				AND RH.RepLevelHistID <> @RepLevelHistID	)	-- Exclusion lors de mise a jour
							INSERT INTO #WngAndErr
								SELECT 
									'L02',
									'',
									'',
									''

	-- L03 -> Vous allez modifier l’historique dans le passé.	
	SELECT  @OldStartDate = StartDate,
		@OldEndDate = EndDate,
		@OldRepID = RepID,
		@OldRepLevelID = RepLevelID
	FROM un_RepLevelHist
	WHERE RepLevelHistID = @RepLevelHistID	
	
	IF ((@StartDate < dbo.FN_CRQ_DateNoTime(GetDate())
		AND  @OldStartDate <> @StartDate )				-- Lorsqu’on aura modifié la date de début pour une date antérieure à la date du jour.
		OR (@StartDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @RepLevelHistID =0)					-- Lors d’ajout quand la date de début sera antérieure à la date du jour.
		OR (@OldStartDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND ( @OldRepID <> @RepID
				OR @OldRepLevelID <> @RepLevelID)
			AND @RepLevelHistID > 0)				-- Lorsqu’on aura modifié n’importe laquelle des valeurs sauf la date de fin et que la date de début sera, avant modification, antérieure à la date du jour.
		OR (@EndDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @OldEndDate <> @EndDate
			AND @EndDate <> -2
			AND @RepLevelHistID > 0)				-- Lorsqu’on aura modifié la date de fin pour une date antérieure à la date du jour.
		OR (@EndDate < dbo.FN_CRQ_DateNoTime(GetDate())
			AND @OldEndDate IS NULL
			AND @RepLevelHistID > 0
			AND @EndDate <> -2)					-- Lorsqu’on aura modifié la date de fin pour une date antérieure à la date du jour. Take 2
		OR (@OldEndDate < dbo.FN_CRQ_DateNoTime(GetDate())	
			AND @OldEndDate <> @EndDate
			AND @RepLevelHistID > 0)				-- Lorsqu’on aura modifié la date de fin et qu’elle sera, avant modification, antérieure à la date du jour.	
		)
	BEGIN
		INSERT INTO #WngAndErr
			SELECT 
				'L03',
				'',
				'',
				''
	END

	
	SELECT *
	FROM #WngAndErr

	DROP TABLE #WngAndErr
END

