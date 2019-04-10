/***********************************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchSubscriber
Description         :	Procédure de recherche de souscripteur.
Valeurs de retours  :	Dataset :
							 SubscriberID	INTEGER			ID du tuteur, correspond au HumanID.
							 FirstName		VARCHAR(35)		Prénom du tuteur
							 LastName		VARCHAR(50)		Nom
							 SocialNumber	VARCHAR(75)		Numéro d’assurance sociale
							 Address		VARCHAR(75)		# civique, rue et # d’appartement.
							 City 		VARCHAR(100)	     Ville
							 Statename		VARCHAR(75)		Province
							 ZipCode		VARCHAR(10)		Code postal
							 Phone1		VARCHAR(27)		Tél. résidence
							 IsCompany		BIT				Indique s'il s'agit d'une compagnie
							 tiCESPState	TINYINT			État des pré-validations PCEE
							 AddressLost	BIT				Indique si l'adresse est perdu
							 RepID		Integer			Id du représentant

Historique des modifications :

                    Date            Programmeur                 Description
                    ----------      ------------------------    ---------------------------------------------------------------
IA	               2004-05-05	 Dominic Létourneau		    Migration de l'ancienne procedure selon les nouveaux standards
ADX0000826	IA	2006-03-20	 Bruno Lapointe		    Géré le prénom NULL des souscripteurs-compagnies et retourner le champ IsCompany 
ADX0000831	IA	2006-03-21	 Bruno Lapointe		    Adaptation des conventions pour PCEE 4.3
ADX0001185	IA	2006-11-22	 Bruno Lapointe		    Optimisation
ADX0001235	IA	2007-03-14	 Alain Quirion			    Ajout de champs pour la recherche dans la fusion
ADX0001241	IA	2007-04-11	 Alain Quirion			    Suppresion de Initial
ADX0001413	IA	2007-06-08	 Alain Quirion			    Ajout du champ AddressLost
				2008-11-17	 Donald Huppé			    Recherche par "PHO" : On recherche maintenant dans tous les champs de numéro de téléphone
				2008-12-11	 Pierre-Luc Simard		    Recherche par nom et prénom sans tenir compte des accents
				2010-01-28	 Donald Huppé	  		    Recherche par code postal : enlever les espaces dans le critère de recherche et dans le champs zipcode
				2010-01-29	 Jean-François Gauthier      Ajout du critère de recherche IDs afin de chercher avec l'identifiant du souscripteur
				2011-06-07	 Jean-Francois Arial	    Ajout du RepID dans le dataset de retour qui représente le ID du représentant du souscripteur ainsi que le nombre de convention active
				2011-07-28	 Christian Chénard		    Ajout de la recherche par date de naissance et par courriel, Ajout du courriel dans les champs de données retournées
				2014-05-27	 Donald Huppé			    Recherche par no de téléphone : recherche directement dans tblGENE_Telephone
				2014-08-04	 Maxime Martel			    Supprime les caractères non affichable lors de copier coller
        2015-12-01      Steeve Picard               Utilisation de la nouvelle fonction «fntCONV_ObtenirStatutConventionEnDate_PourTous»
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchSubscriber] (
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
	SET @Search = dbo.fnGENE_RetirerCaracteresNonAffichable(@Search)
	
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
		SELECT DISTINCT s.SubscriberID 
		FROM dbo.tblGENE_Telephone t
		JOIN dbo.Un_Subscriber s ON t.iID_Source = s.SubscriberID
		WHERE
			LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10) BETWEEN t.dtDate_Debut AND ISNULL(t.dtDate_Fin,'9999-12-31')
			and t.vctelephone like @Search	
		/*
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
				*/
	-- Date de naissance
	ELSE IF @SearchType = 'BDa'
		INSERT INTO @tSearchSubs
			SELECT HumanID
			FROM dbo.Mo_Human 
			WHERE BirthDate 	BETWEEN CONVERT(DATETIME, LEFT(@Search, 10))
								AND CONVERT(DATETIME, RIGHT(@Search, 10))
	-- Courrier électronique
	ELSE IF @SearchType = 'Mai'
		INSERT INTO @tSearchSubs
			SELECT HumanID
			FROM dbo.Mo_Human H
			JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
			WHERE A.EMail like '%' + @Search + '%'		
	-- Code postal
	ELSE IF @SearchType = 'Zip'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM dbo.Mo_Adr A
			JOIN dbo.Mo_Human H ON A.AdrID = H.AdrID
			WHERE LTRIM(RTRIM(REPLACE(A.ZipCode,' ',''))) LIKE LTRIM(RTRIM(REPLACE(@Search,' ','')))
	-- Identifiant souscripteur -- 2010-01-29 : JFG : Ajout
	ELSE IF @SearchType = 'IDs'
		INSERT INTO @tSearchSubs
		(HumanID)
		VALUES
		(CAST(@Search AS INT))

	SELECT @iConvActive = COUNT(*)
	FROM dbo.Un_Convention c JOIN @tSearchSubs tSS ON (c.SubscriberID = tSS.HumanID)
          JOIN dbo.fntCONV_ObtenirStatutConventionEnDate_PourTous(GetDate(), NULL) s ON s.conventionID = c.ConventionID
     WHERE s.ConventionStateID <> 'FRM'

	-- Recherche des souscripteurs selon les critères passés en paramètre
	SELECT 
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
		EMail = ISNULL(A.EMail, ''),
		CountryName = ISNULL(Co.CountryName, ''),
		H.IsCompany,
		S.tiCESPState,
		S.AddressLost,
		S.RepID,
		@iConvActive AS NbConvActive
	FROM @tSearchSubs tS
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.HumanID
	JOIN dbo.Mo_Human H ON H.HumanID = S.SubscriberID
	LEFT JOIN dbo.Mo_Adr A ON H.AdrID = A.AdrID
	LEFT JOIN Mo_Country Co ON Co.CountryID = A.CountryID
	JOIN #tRep R ON S.RepID = R.RepID OR R.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant		
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
		A.EMail,
		Co.CountryName,
		H.IsCompany,
		S.tiCESPState,
		S.AddressLost,
		S.RepID
	ORDER BY 
		CASE @SearchType
			WHEN 'LNa' THEN H.LastName
			WHEN 'Pho' THEN A.Phone1
			WHEN 'SNu' THEN H.SocialNumber
			WHEN 'FNa' THEN H.FirstName
			WHEN 'Zip' THEN A.ZipCode
			WHEN 'BDa' THEN CONVERT(VARCHAR(10), H.BirthDate, 126)
		END,
		CASE @SearchType
			WHEN 'LNa' THEN H.FirstName
			ELSE H.LastName
		END,
		CASE
			WHEN @SearchType IN ('LNa', 'FNa') THEN H.SocialNumber
			ELSE H.FirstName
		END,
		H.SocialNumber

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
						WHEN 'BDa' THEN 'date de naissance : '
						WHEN 'Mai' THEN 'courriel : '
					END + @Search,
				'SL_UN_SearchSubscriber',
				'EXECUTE SL_UN_SearchSubscriber @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END
