/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_SearchConventionNotValidated
Description         :	Recherche des conventions non validés.
Valeurs de retours  :	Dataset :
						ConventionID		INTEGER		ID de la convention.
						ConventionNo		VARCHAR(75)	Numéro de convention.
						SubscriberID		INTEGER		ID du souscripteur.
						SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
						InForceDate		DATETIME	Date d'entrée en vigueur 
 
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
						2006-11-29	Alain Quirion		Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionNotValidated] (	
	@ConnectID INTEGER,
	@SearchType CHAR(3), 	-- Type de recherche par ConventionNo (CNo) ou souscripteur (SNa)  
	@Search VARCHAR(75), 	-- Filtre de recherche
	@RepID INTEGER = 0 ) 	-- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	-- Création d'une table temporaire
	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXECUTE SL_UN_BossOfRep @RepID
	
	-- Recherche de convention avec groupes d'unités non validés 
	SELECT  
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName =
			CASE 
				WHEN H.IsCompany = 1 THEN ISNULL(H.LastName, '')
			ELSE ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END,
		VD.InforceDate      
	FROM dbo.Un_Convention C  
	JOIN dbo.Un_Subscriber S	ON C.SubscriberID = S.SubscriberID
	JOIN #TB_Rep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN (-- Retourne la date de début de régime
		SELECT  
			U.ConventionID,   
			InForceDate = MIN (InForceDate)  
		FROM dbo.Un_Unit U  
		WHERE U.ActivationConnectID IS NULL
		GROUP BY ConventionID    
		) VD ON VD.ConventionID = C.ConventionID
	WHERE	CASE @SearchType  
				WHEN 'CNo' THEN C.ConventionNo  
				WHEN 'SNa' THEN ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END LIKE @Search
	ORDER BY CASE @SearchType  
				WHEN 'CNo' THEN C.ConventionNo  
				ELSE ISNULL(H.LastName, '') + ', ' + ISNULL(H.FirstName, '')
			END
	
	DROP TABLE #TB_Rep 
	
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
				'Recherche de convention avec groupe d''unité non validé par '+
						CASE @SearchType
							WHEN 'SNa' THEN 'souscripteur : ' 
							WHEN 'CNo' THEN 'convention : '
						END + @Search,
				'SL_UN_SearchConventionNotValidated',
				'EXECUTE SL_UN_SearchConventionNotValidated @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @SearchType='+@SearchType+
					', @Search='+@Search+
					', @RepID'+CAST(@RepID AS VARCHAR)			
	END	
	
	-- FIN DES TRAITEMENTS
	RETURN 0
END


