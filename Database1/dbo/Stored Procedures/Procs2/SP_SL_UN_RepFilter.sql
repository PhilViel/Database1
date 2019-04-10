/****************************************************************************************************
	Liste les représentants sous un représentant, pour savoir appliquer un 
	filtre sur les dossiers.
 ******************************************************************************
	2004-10-27 Bruno Lapointe
		Création
		BR-ADX0001124
		
	2010-05-12	Donald Huppé	Modification du calcul de @CurrentDate.  On prend la date SANS les heures et minutes
 ******************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_RepFilter](
	@RepID INTEGER) -- ID du représentant
AS
BEGIN
	DECLARE 
		@CurrentDate DATETIME

	-- Sauvegarde la date courante SANS LES HEURES
	
	SELECT @CurrentDate = CAST(ROUND(CAST(getdate() AS real),0,1) AS datetime)

	PRINT @CurrentDate
	
	CREATE TABLE #RepFilter (
		RepID INTEGER,
		RepType CHAR(3), -- 'ALL' = Tous, 'DIR' = Agence, 'REP' = Représentant
		RepName VARCHAR(152),
		Actif BIT) 

	-- Vérifie s'il s'agit d'un directeur des ventes
	IF EXISTS (
		SELECT 
			H.RepID
		FROM Un_RepLevelHist H 
		JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
		WHERE L.RepRoleID IN ('PRO', 'PRS')
		  AND H.RepID = @RepID
		  AND H.StartDate <= @CurrentDate
		  AND (H.EndDate IS NULL OR
				 H.EndDate >= @CurrentDate)) OR
		@RepID = 0 -- Usager normal
	BEGIN
		-- Ajoute l'option tous
		INSERT INTO #RepFilter
		VALUES(0, 'ALL', 'Tous', 1)

		-- Ajoute la liste de tous les agences depuis le début
		INSERT INTO #RepFilter
			SELECT DISTINCT
				LH.RepID,
				'DIR',
				H.LastName+', '+H.FirstName,
				CASE 
					WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
				ELSE 0
				END
			FROM Un_RepLevelHist LH 
			JOIN Un_RepLevel L ON L.RepLevelID = LH.RepLevelID
			JOIN dbo.Mo_Human H ON H.HumanID = LH.RepID
			JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE L.RepRoleID IN ('DIR', 'DIS')

		-- Ajoute la liste de tous les représentants depuis le début
		INSERT INTO #RepFilter
			SELECT DISTINCT
				LH.RepID,
				'REP',
				H.LastName+', '+H.FirstName,
				CASE 
					WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
				ELSE 0
				END
			FROM Un_RepLevelHist LH 
			JOIN Un_RepLevel L ON L.RepLevelID = LH.RepLevelID
			JOIN dbo.Mo_Human H ON H.HumanID = LH.RepID
			JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE L.RepRoleID IN ('REP', 'VES')
	END
	-- Vérifie s'il s'agit d'un directeur
	ELSE IF EXISTS (
		SELECT 
			H.RepID
		FROM Un_RepLevelHist H 
		JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
		WHERE L.RepRoleID IN ('DIR', 'DIS')
		  AND H.RepID = @RepID
		  AND H.StartDate <= @CurrentDate
		  AND (H.EndDate IS NULL OR
				 H.EndDate >= @CurrentDate))
	BEGIN
		-- Ajoute l'agence
		INSERT INTO #RepFilter
			SELECT
				@RepID,
				'DIR',
				H.LastName+', '+H.FirstName,
				CASE 
					WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
				ELSE 0
				END
			FROM dbo.Mo_Human H
			JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE HumanID = @RepID

		-- Ajoute la liste de tous les représentants de l'agence 
		INSERT INTO #RepFilter
			SELECT DISTINCT
				B.RepID,
				'REP',
				H.LastName+', '+H.FirstName,
				CASE 
					WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
				ELSE 0
				END			
			FROM Un_RepBossHist B 
			JOIN dbo.Mo_Human H ON H.HumanID = B.RepID
			JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE B.RepRoleID IN ('DIR', 'DIS')
			  AND B.BossID = @RepID
			  AND B.RepBossPct > 50
			  AND B.StartDate <= @CurrentDate
			  AND (B.EndDate IS NULL
				 OR B.EndDate >= @CurrentDate)
	END
	-- Cas représentant
	ELSE
	BEGIN
		-- Ajoute le représentant
		INSERT INTO #RepFilter
			SELECT
				@RepID,
				'REP',
				H.LastName+', '+H.FirstName,
				CASE 
					WHEN ISNULL(R.BusinessEnd, DATEADD(DAY,1,GETDATE())) > GETDATE() THEN 1
				ELSE 0
				END
			FROM dbo.Mo_Human H
			JOIN Un_Rep R ON R.RepID = H.HumanID
			WHERE H.HumanID = @RepID
	END

	SELECT
		RepID,
		RepType,
		RepName,
		Actif
	FROM #RepFilter
	ORDER BY RepType, RepName

	DROP TABLE #RepFilter
END


