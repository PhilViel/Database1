/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionWithSchedule
Description         :	Recherche de convention avec horaire de prelevement.
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
									InforceDate			DATETIME		Date d'entrée en vigueur de l'horaire de prélèvement
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionWithSchedule] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche par ConventionNo (CNo) ou souscripteur (SNa)  
	@Search VARCHAR(75), -- Filtre de recherche
	@RepID INTEGER = 0 ) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	-- Création d'une table temporaire
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #tRep
		EXECUTE SL_UN_BossOfRep @RepID
	
	SELECT  
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName =
			CASE 
				WHEN H.IsCompany = 1 THEN ISNULL(H.LastName, '')
			ELSE ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END,
		VA.InforceDate
	FROM dbo.Un_Convention C  
	JOIN dbo.Un_Subscriber S	ON C.SubscriberID = S.SubscriberID
	JOIN #tRep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN (-- Retourne la plus petite date d'entrée en vigueur pour lse conventions avec horaire de prélèvements actif
		SELECT 
			U.ConventionID,  
			InForceDate = MIN(U.InForceDate)
		FROM Un_AutomaticDeposit A  
		JOIN dbo.Un_Unit U ON U.UnitID = A.UnitID
		-- La date du jour est incluse entre la date de debut et la date de fin  
		WHERE dbo.fn_Mo_DateNoTime(GETDATE()) BETWEEN A.StartDate AND ISNULL(dbo.fn_Mo_IsDateNull(A.EndDate),GETDATE()+7300)  
		GROUP BY U.ConventionID 
		) VA ON VA.ConventionID = C.ConventionID
	WHERE CASE @SearchType  
				WHEN 'CNo' THEN C.ConventionNo  
				WHEN 'SNa' THEN ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END LIKE @Search
	ORDER BY CASE @SearchType
				WHEN 'CNo' THEN C.ConventionNo  
				ELSE ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END
	
	DROP TABLE #tRep 
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceSearch = siTraceSearch FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceSearch
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceSearch.
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
				DATEDIFF(SECOND, @dtBegin, @dtEnd), -- Temps en seconde
				@dtBegin,
				@dtEnd,
				'Recherche de convention avec horaire de prélèvement par '+
					CASE @SearchType
						WHEN 'SNa' THEN 'souscripteur : ' 
						WHEN 'CNo' THEN 'convention : '
					END + @Search,
				'SL_UN_SearchConventionWithSchedule',
				'EXECUTE SL_UN_SearchConventionWithSchedule @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


