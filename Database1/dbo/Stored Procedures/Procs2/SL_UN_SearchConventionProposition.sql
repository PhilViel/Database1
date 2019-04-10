/****************************************************************************************************
Nom                 :	SL_UN_SearchConventionProposition
Description         :	Recherche des conventions non validés.
Valeurs de retours  :	Dataset :
						ConventionID		INTEGER		ID de la convention.
						ConventionNo		VARCHAR(75)	Numéro de convention.
						SubscriberID		INTEGER		ID du souscripteur.
						SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
						InForceDate			DATETIME	Date d'entrée en vigueur 

Note                :	2011-09-21	Christian Chénard		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionProposition] (	
	@ConnectID INTEGER,
	@SearchType CHAR(3), 	-- Type de recherche par ConventionNo (CNo), souscripteur (SNa), BNa(bénéficiaire) ou IDs(identifiant de convention) 
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
				WHEN HS.IsCompany = 1 THEN ISNULL(HS.LastName, '')
			ELSE ISNULL(HS.LastName, '') + ', ' + ISNULL(HS.FirstName, '')
			END,
		C.BeneficiaryID,
		BeneficiaryName = ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, ''),
		B.RepID,
		RepName =  ISNULL(HR.LastName, '') + ', ' + ISNULL(HR.FirstName, ''),
		C.dtInforceDateTIN,
		C.FirstPmtDate,
		SignatureDate = (Select min(U.SignatureDate) from dbo.Un_Unit U where U.ConventionID = C.ConventionID),
		LastUpdateDate = (Select max(L.LogTime)
						  from dbo.Mo_Connect CO
						  Join dbo.CRQ_Log L ON CO.ConnectID = L.ConnectID
						  where CO.ConnectID = C.LastUpdateConnectID and L.LogTableName = 'Un_Convention')		
	FROM dbo.Un_Convention C 
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN #TB_Rep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	Left JOIN dbo.Mo_Human HR ON HR.HumanID = B.RepID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		
	-- Jointure à une sous-requête qui retourne les conventions dont le dernier statut est 'PRP'
	Join (Select ConventionID from dbo.Un_ConventionConventionState
		  where ConventionConventionStateID in (Select max(ConventionConventionStateID) as ConventionConventionStateID
											from dbo.Un_ConventionConventionState
											Group by ConventionID)
		  and ConventionStateID = 'PRP') CCS On CCS.ConventionID = C.ConventionID	
	WHERE	CASE @SearchType  
				WHEN 'IDs' THEN cast(C.ConventionID as varchar)
				WHEN 'CNo' THEN cast(C.ConventionNo as varchar)
				WHEN 'SNa' THEN ISNULL(HS.LastName, '') + ', ' + ISNULL(HS.FirstName, '')
				WHEN 'BNa' THEN ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
			END LIKE @Search
	
	ORDER BY CASE @SearchType  
				WHEN 'IDs' THEN cast(C.ConventionID as varchar)
				WHEN 'CNo' THEN cast(C.ConventionNo as varchar)
				WHEN 'SNa' THEN ISNULL(HS.LastName, '') + ', ' + ISNULL(HS.FirstName, '')
				WHEN 'BNa' THEN ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
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
							WHEN 'IDs' THEN 'Identifiant de convention : ' 
							WHEN 'CNo' THEN 'Numéro de convention : '
							WHEN 'SNa' THEN 'Souscripteur : '
							WHEN 'BNa' THEN 'Bénéficiaire : '
							
						END + @Search,
				'SL_UN_SearchConventionProposition',
				'EXECUTE SL_UN_SearchConventionProposition @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
					', @SearchType='+@SearchType+
					', @Search='+@Search+
					', @RepID'+CAST(@RepID AS VARCHAR)			
	END	
	
	-- FIN DES TRAITEMENTS
	RETURN 0
END


