/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchSubscriberWithResilie
Description         :	Procédure de recherche de souscripteur
Valeurs de retours  :	Dataset :
							 SubscriberID	INTEGER			ID du tuteur, correspond au HumanID.
							 FirstName		VARCHAR(35)		Prénom du tuteur
							 LastName		VARCHAR(50)		Nom
							 SocialNumber	VARCHAR(75)		Numéro d’assurance sociale
							 Address			VARCHAR(75)		# civique, rue et # d’appartement.
							 City 			VARCHAR(100)	Ville
							 Statename		VARCHAR(75)		Province
							 ZipCode			VARCHAR(10)		Code postal
							 Phone1			VARCHAR(27)		Tél. résidence
							 IsCompany		BIT				Indique s'il s'agit d'une compagnie
							 tiCESPState		TINYINT			État des pré-validations PCEE
							 AddressLost		BIT				Indique si l'adresse est perdu
							 RepID			Integer			Id du représentant

Historique des modifications :

        Date            Programmeur                     Description
        ----------      ----------------------------    ---------------------------------------------------------------
        2011-09-22      Christian Chénard		      Création de la procédure
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchSubscriberWithResilie] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche: LNa(Nom, prénom), FNa(Prénom, nom), SNu(Nas), Pho(Telephone), Zip(Code postal), IDs (Identifiant de souscripteur)
	@Search VARCHAR(87), -- Critère de recherche
	@RepID INTEGER = 0) -- Identifiant unique du représentant (0 pour tous)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT,	
		@iConvActive INTEGER

	SET @dtBegin = GETDATE()

	-- Création d'une table temporaire
	CREATE TABLE #tRep (
	RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #tRep
	EXECUTE SL_UN_BossOfRep @RepID	

	DECLARE @tSearchSubs TABLE (
		HumanID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @SearchType = 'LNa'
		INSERT INTO @tSearchSubs
			SELECT HumanID
			FROM dbo.Mo_Human 
			WHERE LastName + ', ' + ISNULL(FirstName,'') COLLATE French_CI_AI LIKE @Search
	-- Prénom, nom
	ELSE IF @SearchType = 'FNa'
		INSERT INTO @tSearchSubs
			SELECT HumanID
			FROM dbo.Mo_Human 
			WHERE ISNULL(FirstName,'') + ', ' + LastName COLLATE French_CI_AI LIKE @Search
				OR ( IsCompany = 1
					AND LastName LIKE @Search
					)
	-- Numéro d'assurance social
	ELSE IF @SearchType = 'SNu'
		INSERT INTO @tSearchSubs
			SELECT HumanID
			FROM dbo.Mo_Human 
			WHERE SocialNumber LIKE @Search
	-- Téléphone
	ELSE IF @SearchType = 'Pho'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE A.Phone1 LIKE @Search 
				or A.Phone2 like @Search 
				or A.Fax like @Search 
				or A.Mobile like @Search 
				or A.WattLine like @Search 
				or A.OtherTel like @Search 
				or A.Pager like @Search
	-- Code postal
	ELSE IF @SearchType = 'Zip'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE LTRIM(RTRIM(REPLACE(A.ZipCode,' ',''))) LIKE LTRIM(RTRIM(REPLACE(@Search,' ','')))
	-- Identifiant souscripteur
	ELSE IF @SearchType = 'IDs'
		INSERT INTO @tSearchSubs
		(HumanID)
		VALUES
		(CAST(@Search AS INT))

	SELECT @iConvActive = COUNT(*)
	FROM dbo.Un_Convention c JOIN @tSearchSubs tSS ON (c.SubscriberID = tSS.HumanID)
          JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GetDate(), NULL) s ON s.conventionID = c.ConventionID
     WHERE s.ConventionStateID <> 'FRM'

	-- Recherche des souscripteurs qui respectent les critères passés en paramètre ET qui tiennent compte du critère du représentant
	Select * from
	(SELECT 
		S.SubscriberID,
		H.OrigName,
		H.LastName,
		H.FirstName,
		H.SocialNumber,
		Address = ISNULL(A.Address, ''),
		City = ISNULL(A.City, ''),
		Statename = ISNULL(A.Statename, ''),
		ZipCode = ISNULL(A.ZipCode, ''),
		Phone1 = ISNULL(A.Phone1, ''),
		Phone2 = ISNULL(A.Phone2, ''),
		BirthDate = dbo.FN_CRQ_IsDateNull(H.BirthDate),
		DeathDate = dbo.FN_CRQ_IsDateNull(H.DeathDate),
		CountryName = ISNULL(Co.CountryName, ''),
		H.IsCompany,
		S.tiCESPState,
		S.AddressLost,
		S.RepID,
		@iConvActive AS NbConvActive,
		Case when @RepID = 0 or S.RepID in (select RepID from #tRep) then 1 else 3 End as IndSubClient
	FROM @tSearchSubs tS
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.HumanID
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
	LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
	union
	-- Recherche des souscripteurs qui respectent les critères passés en paramètre ET qui ne tiennent pas compte du critère du représentant
	-- ET dont les conventions ont le statut "RÉSILIÉ"
	Select 
		S.SubscriberID,
		H.OrigName,
		H.LastName,
		H.FirstName,
		H.SocialNumber,
		Address = ISNULL(A.Address, ''),
		City = ISNULL(A.City, ''),
		Statename = ISNULL(A.Statename, ''),
		ZipCode = ISNULL(A.ZipCode, ''),
		Phone1 = ISNULL(A.Phone1, ''),
		Phone2 = ISNULL(A.Phone2, ''),
		BirthDate = dbo.FN_CRQ_IsDateNull(H.BirthDate),
		DeathDate = dbo.FN_CRQ_IsDateNull(H.DeathDate),
		CountryName = ISNULL(Co.CountryName, ''),
		H.IsCompany,
		S.tiCESPState,
		S.AddressLost,
		S.RepID,
		@iConvActive AS NbConvActive,
		2 as IndSubClient
	FROM @tSearchSubs tS
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.HumanID
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
	LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
	where 
	-- Nombre total de conventions du souscripteur
	(SELECT count(C.ConventionID) FROM dbo.Un_Convention C where C.SubscriberID = S.SubscriberID)
	=
	-- Nombre de conventions résiliées du souscripteur
	(SELECT count(C.ConventionID) FROM dbo.Un_Convention C 
	 where 
		-- Nombre total d'unité de la convention 
		(SELECT count(U.UnitID) FROM dbo.Un_Unit U WHERE U.ConventionID = C.ConventionID) = 
		-- Nombre d'unité résiliées
		(SELECT count(U.UnitID) FROM dbo.Un_Unit U WHERE U.ConventionID = C.ConventionID AND U.TerminatedDate IS NOT NULL 
																					 AND U.TerminatedDate < DATEADD(mm, -1, GETDATE())
																					 AND U.IntReimbDate IS NULL)
																					 AND C.SubscriberID = S.SubscriberID)
	GROUP BY 
		S.SubscriberID, 
		H.OrigName,
		H.LastName, 
		H.FirstName, 
		H.SocialNumber, 
		A.Address, 
		A.City, 
		A.Statename, 
		A.ZipCode, 
		H.BirthDate,
		H.DeathDate,
		A.Phone1,
		A.Phone2,
		Co.CountryName,
		H.IsCompany,
		S.tiCESPState,
		S.AddressLost,
		S.RepID) t
		
	ORDER BY 
		CASE @SearchType
			WHEN 'LNa' THEN LastName
			WHEN 'Pho' THEN Phone1
			WHEN 'SNu' THEN SocialNumber
			WHEN 'FNa' THEN FirstName
			WHEN 'Zip' THEN ZipCode
		END,
		CASE @SearchType
			WHEN 'LNa' THEN FirstName
			ELSE LastName
		END,
		CASE
			WHEN @SearchType IN ('LNa', 'FNa') THEN SocialNumber
			ELSE FirstName
		END,
		SocialNumber

	-- Suppression table temporaire
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
				'Recherche de souscripteur par '+
					CASE @SearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'SNu' THEN 'NAS : '
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'Zip' THEN 'code postal : '
					END + @Search,
				'SL_UN_SearchSubscriberWithResilie',
				'EXECUTE SL_UN_SearchSubscriberWithResilie @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END
