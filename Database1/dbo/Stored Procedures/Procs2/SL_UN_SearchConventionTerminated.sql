/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionTerminatedTest2
Description         :	Procedure de recherche des conventions résiliées.
Valeurs de retours  :	Dataset :
					ConventionID		INTEGER		ID de la convention.
					ConventionNo		VARCHAR(75)	Numéro de convention.
					SubscriberID		INTEGER		ID du souscripteur.
					SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
					NbUnitsBeforeReduction 	INTEGER		Nombre d'unités avant la résiliation,  
					Cotisation		MONEY		Épargne résiliés
					Fee			MONEY		Frais résiliés
					TerminatedReason	VARCHAR(75)	Raison de la résiliation
					ConventionState		VARCHAR(75) 	État de la convention

Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
						2006-12-04	Alain Quirion		Optimisation
						2011-06-02	Frédérick Thibault	Mise en commentaire du filtre de type d'opération (FT1)
                        2017-02-22  Pierre-Luc Simard   Retirer PEE de la validation pour les cotisations même si plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionTerminated] (	
	@ConnectID INTEGER,
	@StartDate DATETIME, -- date de début pour la recherche
	@EndDate DATETIME, -- date de fin pour la recherche
	@RepID INTEGER = 0) -- ID du représentant, 0 pour ne pas appliquer ce critère
AS

BEGIN
	-- GRAND GAGNANT DE L'OPTIMISATION
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	CREATE TABLE #TB_Rep (RepID int) -- Création table temporaire pour recherche par représentant

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXEC SL_UN_BossOfRep @RepID

	CREATE TABLE #tRESUnit(
		UnitID INTEGER PRIMARY KEY,
		ConventionID INTEGER)

	INSERT INTO #tRESUnit
		SELECT 
			U.UnitID,
			U.ConventionID
		FROM dbo.Un_Convention C 
		JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
		LEFT JOIN (
				SELECT ConventionID 
				FROM dbo.Un_Unit 
				WHERE ISNULL(TerminatedDate,0) < 1
			) TR ON TR.ConventionID = C.ConventionID
		WHERE TR.ConventionID IS NULL
			AND U.TerminatedDate >= @StartDate
			AND U.TerminatedDate < @EndDate + 1

	CREATE TABLE #tRESConvention(
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #tRESConvention
		SELECT DISTINCT ConventionID
		FROM #tRESUnit

	CREATE TABLE #tUnitReduction(
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY,
		UnitReductionID INTEGER,
		UnitReductionReasonID INTEGER)

	INSERT INTO #tUnitReduction
		SELECT 
			R.UnitID,
			R.UnitQty,
			R.UnitReductionID,
			R.UnitReductionReasonID
		FROM (-- Retrouve la plus récente réduction par groupe d'unité
			SELECT 
				RU.UnitID, 
				UnitReductionID = MAX(UnitReductionID) 
			/*FROM (-- Retrouve la plus grande date de reduction par groupe d'unités
				SELECT  
					UR.UnitID,
					ReductionDate = MAX(UR.ReductionDate)
				FROM #tRESUnit RU
				JOIN Un_UnitReduction UR ON UR.UnitID = RU.UnitID
				GROUP BY UR.UnitID
				) U*/
			FROM #tRESUnit RU
			JOIN Un_UnitReduction UR ON RU.UnitID = UR.UnitID
			GROUP BY RU.UnitID
			) T
		JOIN Un_UnitReduction R ON T.UnitReductionID = R.UnitReductionID
		
	CREATE TABLE #tSumCotisationFee(
		UnitID INTEGER PRIMARY KEY,
		Cotisation MONEY,
		Fee MONEY)

	INSERT INTO #tSumCotisationFee-- Sommarise les frais et les cotisations par groupe d'unités
		SELECT  
			UnitID = RU.UnitID,  
			Cotisation = SUM(C.Cotisation),  
			Fee = SUM(C.Fee) 
		FROM #tRESUnit RU
		JOIN Un_Cotisation C ON C.UnitID = RU.UnitID
		JOIN Un_Oper O ON O.OperID = C.OperID
		-- FT1
		--WHERE O.OperTypeID IN ('RES', 'OUT', 'TRA') -- certains types d'opération -- PLS: 2017-02-22
		GROUP BY RU.UnitID 

	CREATE TABLE #tConventionState(
		ConventionID INTEGER PRIMARY KEY,
		ConventionStateName VARCHAR(75))

	INSERT INTO #tConventionState
		SELECT 
			T.ConventionID,
			CS.ConventionStateName
		FROM (-- Retourne la plus grande date de début d'un état par convention
			SELECT 
				RC.ConventionID,
				MaxDate = MAX(CCS.StartDate)
			FROM #tRESConvention RC
			JOIN Un_ConventionConventionState CCS ON RC.ConventionID = CCS.ConventionID
			WHERE CCS.StartDate <= GETDATE() -- État actif
			GROUP BY RC.ConventionID
			) T
		JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
		JOIN Un_ConventionState CS ON CCS.ConventionStateID = CS.ConventionStateID -- Pour retrouver la description de l'état
		
	-- Retourne les conventions terminées
	SELECT   
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName = 
			CASE 
				WHEN H.IsCompany = 1 THEN H.LastName
			ELSE H.LastName + ', ' + H.FirstName
			END,
		NbUnitsBeforeReduction = SUM(U.UnitQty + ISNULL(UR.UnitQty,0)),  
		Cotisation = ISNULL(SUM(T.Cotisation),0),  
		Fee = ISNULL(SUM(T.Fee),0),
		TerminatedReason = MIN(URR.UnitReductionReason),
		ConventionState = MIN(CS.ConventionStateName)
	FROM #tRESConvention RC
	JOIN dbo.Un_Convention C ON C.ConventionID = RC.ConventionID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	LEFT JOIN #TB_Rep B ON S.RepID = B.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID	
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	LEFT JOIN #tUnitReduction UR ON U.UnitID = UR.UnitID
	LEFT JOIN Un_UnitReductionReason URR ON UR.UnitReductionReasonID = URR.UnitReductionReasonID
	LEFT JOIN #tSumCotisationFee T ON U.UnitID = T.UnitID
	LEFT JOIN #tConventionState CS ON C.ConventionID = CS.ConventionID	
	WHERE B.RepID IS NOT NULL OR @RepID = 0
	GROUP BY 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		H.LastName, 
		H.FirstName,
		H.IsCompany
	ORDER BY 
		C.ConventionNo 

	DROP TABLE #TB_Rep -- Libère la table temporaire
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
	BEGIN
		-- Insère un log de l'objet inséré.
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
				1,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Recherche de convention résilié entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'SL_UN_SearchConventionTerminated',
				'EXECUTE SL_UN_SearchConventionTerminated @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @StartDate ='+CAST(@StartDate AS VARCHAR)+	
					', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
					', @RepID ='+CAST(@RepID AS VARCHAR)	
	END	

	DROP TABLE #tRESConvention
	DROP TABLE #tRESUnit
	
	-- FIN DES TRAITEMENTS
	RETURN 0
END