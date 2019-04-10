/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_SalesSources
Description         :	Procédure stockée du rapport : Ventes par sources de ventes
Valeurs de retours  :	Dataset 
Note                :	ADX0000199	UP	2004-06-14	Bruno Lapointe		Migration et User Problem ADX0000199
								ADX0001206	IA	2007-01-08	Bruno Lapointe		Optimisation.
												2008-04-29	Pierre-Luc Simard	Utilisation de la date de premier dépôt au lieu de la date d'entrée en vigueur
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SalesSources] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@SaleSourceID INTEGER = -1, -- Id unique d'une source de vente, 0 = pas de source de vente
	@StartDate DATETIME,  -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@RepID INTEGER = 0) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE 
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	-- Préparation du filtre des représetants 
	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY
	)

	IF @Type = 'ALL' -- Si tout les représentants
		INSERT INTO #TB_Rep
			SELECT 
				RepID
			FROM Un_Rep
	ELSE IF @Type = 'DIR' -- Si agence
		INSERT INTO #TB_Rep
			EXEC SP_SL_UN_RepOfBoss @RepID
	ELSE IF @Type = 'REP' -- Si un représentant
		INSERT INTO #TB_Rep
		VALUES (@RepID)
	-- Fin de la préparation du filtre des représetants 

	-- Retourne les données aux rapport "Sources de ventes par représentants" 
	SELECT
		R.RepID,
		P.PlanDesc,
		C.ConventionNo,
		U.SignatureDate,
		Unit_Total = U.UnitQty,
		RepName = H.LastName + ', ' + H.FirstName,
		BossName =	
			CASE ISNULL(B.LastName,'')
				WHEN '' THEN ''
			ELSE B.LastName + ', ' + B.FirstName
			END,
		RB.BossID
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN #TB_Rep F ON F.RepID = R.RepID -- Filtre des représentants
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	LEFT JOIN (
		SELECT
			RB.RepID,
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT
				RepID,
				RepBossPct = MAX(RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND StartDate IS NOT NULL
				AND StartDate < = @EndDate
				AND ISNULL(EndDate, @EndDate) >= @EndDate
			GROUP BY RepID
		   ) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
		  AND RB.StartDate IS NOT NULL
		  AND RB.StartDate < = @EndDate
		  AND ISNULL(RB.EndDate, @EndDate) > = @EndDate
		GROUP BY RB.RepID
		) RB ON RB.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human B ON B.HumanID = RB.BossID
	WHERE ISNULL(U.SaleSourceID,0) = @SaleSourceID
	  AND dtFirstDeposit > = @StartDate -- U.InForceDate > = @StartDate
	  AND dtFirstDeposit < @EndDate + 1 -- U.InForceDate < @EndDate + 1
	ORDER BY
		B.LastName,
		B.FirstName,
		RB.BossID,
		H.LastName,
		H.FirstName,
		R.RepID,
		C.ConventionNo,
		P.PlanDesc,
		Unit_Total

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Ventes par sources de ventes',
				'RP_UN_SalesSources',
				'EXECUTE RP_UN_SalesSources @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @Type = '+@Type+
					', @SaleSourceID = '+CAST(@SaleSourceID AS VARCHAR)+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @RepID = '+CAST(@RepID AS VARCHAR)

	-- FIN DES TRAITEMENTS 
	RETURN 0
END

/*  Sequence de test - par: JJL - 09-05-2008
    exec [dbo].[RP_UN_SalesSources] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@Type = 'ALL', -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@SaleSourceID  = 132, -- Id unique d'une source de vente, 0 = pas de source de vente
	@StartDate = '2008-01-01',  -- Date de début de la période
	@EndDate = '2008-05-01', -- Date de fin de la période
	@RepID  = 0 -- Limiter les résultats selon un représentant, 0 pour tous
*/


