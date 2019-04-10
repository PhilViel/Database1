/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConvention
Description         :	Recherche des conventions.
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
									BeneficiaryID		INTEGER		ID du bénéficiaire.
									BeneficiaryName	VARCHAR(87)	Nom, prénom du bénéficiaire.
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
								ADX0001185	IA	2006-11-22	Bruno Lapointe			Optimisation
												2008-12-11	Pierre-Luc Simard		Recherche par nom et prénom sans tenir compte des accents
												2010-01-29	Jean-François Gauthier	Ajout du critère de recherche IDs afin de chercher avec l'identifiant de la convention
												2014-07-09	Maxime Martel			Supprime les caractères non affichable lors de copier coller
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConvention] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche: SNa(souscripteur), BNa(bénéficiaire), CNo(numéro de convention), IDs(identifiant de convention)
	@Search VARCHAR(87), -- Critère de recherche
	@RepID INTEGER = 0) -- Identifiant unique du représentant (0 pour tous)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT
	
	SET @Search = dbo.fnGENE_RetirerCaracteresNonAffichable(@Search)
	
	SET @dtBegin = GETDATE()

	-- Création d'une table temporaire
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #tRep
		EXECUTE SL_UN_BossOfRep @RepID

	IF @SearchType = 'SNa'
	BEGIN
		DECLARE @tSearchSubs TABLE (
			HumanID INTEGER PRIMARY KEY)

		-- Nom, prénom
		INSERT INTO @tSearchSubs
			SELECT 
				HumanID
			FROM dbo.Mo_Human
			WHERE LastName + ', ' + FirstName COLLATE French_CI_AI LIKE @Search

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
			BeneficiaryName = ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
		FROM @tSearchSubs tS
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.HumanID
		JOIN #tRep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN dbo.Un_Convention C ON C.SubscriberID = tS.HumanID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		ORDER BY C.ConventionNo
	END
	ELSE IF @SearchType = 'BNa'
	BEGIN
		DECLARE @tSearchBenef TABLE (
			HumanID INTEGER PRIMARY KEY,
			LastName VARCHAR(50) NULL,
			FirstName VARCHAR(35) NULL )

		-- Nom, prénom
		INSERT INTO @tSearchBenef
			SELECT 
				HumanID,
				LastName,
				FirstName
			FROM dbo.Mo_Human
			WHERE LastName + ', ' + FirstName COLLATE French_CI_AI LIKE @Search

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
			BeneficiaryName = ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
		FROM @tSearchBenef HB
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = HB.HumanID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		JOIN #tRep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		ORDER BY C.ConventionNo
	END
	ELSE IF @SearchType IN ('CNo','IDs')
	BEGIN
		DECLARE @tSearchConv TABLE (
			ConventionID INTEGER PRIMARY KEY )

		-- Recherche avec ConventionNO
		IF @SearchType = 'CNo'
			BEGIN
				INSERT INTO @tSearchConv
				(
					ConventionID
				)
				SELECT 
					ConventionID
				FROM 
					Un_Convention
				WHERE 
					ConventionNo LIKE @Search
			END
		ELSE			-- 2010-01-29 : JFG : AJOUT
			BEGIN
				INSERT INTO @tSearchConv
				(ConventionID)
				VALUES
				(CAST(@Search AS INT))
			END
			
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
			BeneficiaryName = ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
		FROM 
			@tSearchConv tC
			JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
			JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
			JOIN #tRep B ON S.RepID = B.RepID OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
			JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
			JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		ORDER BY 
			C.ConventionNo
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
				'Recherche de convention par '+
					CASE @SearchType
						WHEN 'BNa' THEN 'bénéficiaire : ' 
						WHEN 'SNa' THEN 'souscripteur : ' 
						WHEN 'CNo' THEN 'convention : '
					END + @Search,
				'SL_UN_SearchConvention',
				'EXECUTE SL_UN_SearchConvention @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


