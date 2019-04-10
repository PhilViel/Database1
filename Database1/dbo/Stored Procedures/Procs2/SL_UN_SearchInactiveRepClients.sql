/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchInactiveRepClients
Description         :	Recherche de clients de représentants inactifs 
								période.
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
									BreakingStartDate DATETIME		Date de début de l'arrêt de paiement  
									BreakingEndDate	DATETIME		Date de fin de l'arrêt de paiement
									BreakingReason		VARCHAR(75)	Raison de l'arrêt
									Cotisation 			MONEY			Solde réel des épargnes
									RealAmount			MONEY			Solde réel des épargnes et des frais 
									EstimatedAmount 	MONEY			Montant théorique d'épargnes et de frais 
Note                :					IA	2004-06-03	Bruno Lapointe			Création
								ADX0001185	IA	2006-11-30	Bruno Lapointe			Optimisation
												2008-05-12	Pierre-Luc Simard		Ajout du directeur dans le nom du représentant
												2010-02-17	Jean-François Gauthier	Ajout du critère de recherche IDs afin de chercher avec l'identifiant du représentant
												2010-02-19	Jean-François Gauthier	Correction afin de convertir le IDs en varchar en raison d'un conversion implicite que fait SQL
												2010-10-15	Donald Huppé			Ajout d'un champ "Actif" indiquant si le sousc est actif
																			
exec SL_UN_SearchInactiveRepClients 1,'LNS','%tremblay%', 0
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchInactiveRepClients] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType VARCHAR(3), -- Type de recherche: LNS(Nom, prénom souscripteur), FNS(Prénom, nom souscripteur), SNu(Nas), Pho(Telephone), CTy (Ville), Zip (Code postal), LNR(Nom, prénom représentant), FNR(Prénom et nom représentant)
	@Search VARCHAR(100), -- Critère de recherche
	@RepID INTEGER = 0) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()

	-- Préparation du filtre des représetants 
	-- Création d'une table temporaire
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	IF @RepID = 0 -- Si tout les représentants
		INSERT INTO #tRep	
			SELECT 
				RepID
			FROM Un_Rep
	ELSE -- Si un représentant
		INSERT #tRep
			EXECUTE SL_UN_BossOfRep @RepID
	-- Fin de la préparation du filtre des représetants 

	SELECT
		H.LastName,
		H.FirstName, 
		S.SubscriberID,
		H.SocialNumber,
		A.Phone1,
		A.City,
		A.ZipCode,
		RepName = CASE WHEN HD.HumanID IS NOT NULL THEN LEFT(HD.FirstName,1) + '' + HD.LastName + ' - ' ELSE 'SSocial - ' END -- Nom du directeur
			+ '' + HR.LastName + ', ' + HR.FirstName + '' -- Nom du représentant
		,ACTIF = CASE WHEN ACTIF.SUBSCRIBERID IS NOT NULL THEN 1 ELSE 0 END
	FROM Un_Rep R
	JOIN #tRep F ON R.RepID = F.RepID -- Filtre des représentants
	JOIN dbo.Un_Subscriber S	ON R.RepID = S.RepID
	LEFT JOIN (
		SELECT -- Sousc avec au moins une convention ouverte
			C2.SUBSCRIBERID
		FROM 
			UN_CONVENTION C2
			JOIN dbo.Un_Unit U2 ON C2.CONVENTIONID = U2.CONVENTIONID
			JOIN dbo.Un_Subscriber S2 ON C2.SUBSCRIBERID = S2.SUBSCRIBERID
			JOIN #tRep F ON F.RepID = S2.RepID
		WHERE
			U2.TERMINATEDDATE IS NULL
		GROUP BY 
			C2.SUBSCRIBERID
				)ACTIF ON ACTIF.SUBSCRIBERID = S.SUBSCRIBERID
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
	JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID
-- Trouve le directeur du représentant en date d'aujourd'hui
	LEFT JOIN (
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= GETDATE()
				AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= GETDATE()
			AND ISNULL(RB.EndDate,GETDATE()) >= GETDATE()
		GROUP BY 
			RB.RepID
		) RD ON RD.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
	WHERE (ISNULL(R.BusinessEnd, GETDATE()+1) <= GETDATE() /*OR R.RepID = 680904*/)
		AND CASE @SearchType
				WHEN 'LNS' THEN H.LastName + ', ' + H.FirstName
				WHEN 'FNS' THEN H.FirstName + ', ' + H.LastName
				WHEN 'SNu' THEN H.SocialNumber
				WHEN 'Pho' THEN A.Phone1
				WHEN 'CTy' THEN A.City
				WHEN 'Zip' THEN A.ZipCode
				WHEN 'LNR' THEN HR.LastName + ', ' + HR.FirstName
				WHEN 'FNR' THEN HR.FirstName + ', ' + HR.LastName
				WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(75))
			END LIKE @Search
	ORDER BY 
		CASE @SearchType
			WHEN 'LNS' THEN H.LastName
			WHEN 'FNS' THEN H.FirstName
			WHEN 'SNu' THEN H.SocialNumber
			WHEN 'Pho' THEN A.Phone1
			WHEN 'CTy' THEN A.City
			WHEN 'Zip' THEN A.ZipCode
			WHEN 'LNR' THEN HR.LastName
			WHEN 'FNR' THEN HR.FirstName
			WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(75))
		END,
		CASE @SearchType
			WHEN 'LNS' THEN H.FirstName
			WHEN 'FNS' THEN H.LastName
			WHEN 'Pho' THEN H.LastName
			WHEN 'CTy' THEN H.LastName
			WHEN 'Zip' THEN H.LastName
			WHEN 'LNR' THEN HR.FirstName
			WHEN 'FNR' THEN HR.LastName
			WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(75))
		END,
		CASE @SearchType
			WHEN 'LNS' THEN H.SocialNumber
			WHEN 'FNS' THEN H.SocialNumber
			WHEN 'Pho' THEN H.FirstName
			WHEN 'CTy' THEN H.FirstName
			WHEN 'Zip' THEN H.FirstName
			WHEN 'LNR' THEN H.LastName
			WHEN 'FNR' THEN H.LastName
			WHEN 'IDs' THEN CAST(R.RepID AS VARCHAR(75))
		END,
		CASE @SearchType
			WHEN 'Pho' THEN H.SocialNumber
			WHEN 'CTy' THEN H.SocialNumber
			WHEN 'Zip' THEN H.SocialNumber
			WHEN 'LNR' THEN H.FirstName
			WHEN 'FNR' THEN H.FirstName
		END,
		CASE @SearchType
			WHEN 'LNR' THEN H.SocialNumber
			WHEN 'FNR' THEN H.SocialNumber
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
				'Recherche de clients de représentants inactifs par '+
					CASE @SearchType
						WHEN 'LNS' THEN 'nom, prénom souscripteur : ' 
						WHEN 'FNS' THEN 'prénom, nom souscripteur : ' 
						WHEN 'SNu' THEN 'NAS : '
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'CTy' THEN 'ville : '
						WHEN 'Zip' THEN 'code postal : '
						WHEN 'LNR' THEN 'nom, prénom représentant : '
						WHEN 'FNR' THEN 'prénom et nom représentant : '
						WHEN 'IDs' THEN 'identifiant du représentant : '
					END + @Search,
				'SL_UN_SearchInactiveRepClients',
				'EXECUTE SL_UN_SearchInactiveRepClients @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


