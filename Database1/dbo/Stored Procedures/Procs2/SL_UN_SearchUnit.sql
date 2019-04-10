/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchUnit
Description         :	Recherche des groupes d'unités.
Valeurs de retours  :	Dataset :
									UnitID				INTEGER		ID du groupe d'unités.
									InForceDate			DATETIME	Date d'entrée en vigueur
									UnitQty				MONEY		Nombre d'unités.
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									SubscriberName		VARCHAR(87)	Nom, prénom du souscripteur.
									BeneficiaryID		INTEGER		ID du bénéficiaire.
									BeneficiaryName		VARCHAR(87)	Nom, prénom du bénéficiaire.
Note                :					
											IA	2004-07-12	Bruno Lapointe		Création
								ADX0001185	IA	2006-12-05	Bruno Lapointe		Optimisation
								ADX0001357	IA	2007-06-08	Alain Quirion		Ajout de bIsContestWinner
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchUnit] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType VARCHAR(3),  -- Type de recherche
	@Search VARCHAR(100), -- Chaîne de caractères recherchée
	@RepID INTEGER = 0 ) -- Filtre des représentants 0 = tous les représentants
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
	IF @RepID = 0
		INSERT #tRep
			SELECT RepID
			FROM Un_Rep
	ELSE
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
			WHERE ISNULL(LastName, '') + ', ' + ISNULL(FirstName, '') LIKE @Search

		SELECT 
			U.UnitID,
			U.InForceDate,
			U.UnitQty,
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
			bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
		FROM @tSearchSubs tS
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = tS.HumanID
		LEFT JOIN #tRep B ON S.RepID = B.RepID -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN dbo.Un_Convention C ON C.SubscriberID = tS.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		WHERE B.RepID IS NOT NULL 
			OR S.RepID IS NULL
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
			WHERE ISNULL(LastName, '') + ', ' + ISNULL(FirstName, '') LIKE @Search

		SELECT 
			U.UnitID,
			U.InForceDate,
			U.UnitQty,
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
			bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
		FROM @tSearchBenef HB
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = HB.HumanID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #tRep B ON S.RepID = B.RepID -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		WHERE B.RepID IS NOT NULL 
			OR S.RepID IS NULL
		ORDER BY C.ConventionNo
	END
	ELSE IF @SearchType = 'CNo'
	BEGIN
		DECLARE @tSearchConv TABLE (
			ConventionID INTEGER PRIMARY KEY )

		-- Nom, prénom
		INSERT INTO @tSearchConv
			SELECT 
				ConventionID
			FROM dbo.Un_Convention 
			WHERE ConventionNo LIKE @Search

		SELECT 
			U.UnitID,
			U.InForceDate,
			U.UnitQty,
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
			bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
		FROM @tSearchConv tC
		JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
		JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
		LEFT JOIN #tRep B ON S.RepID = B.RepID -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
		JOIN dbo.Mo_Human HS ON C.SubscriberID = HS.HumanID
		JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
		WHERE B.RepID IS NOT NULL 
			OR S.RepID IS NULL
		ORDER BY C.ConventionNo
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
				'Recherche de groupe d''unités par '+
					CASE @SearchType
						WHEN 'BNa' THEN 'bénéficiaire : ' 
						WHEN 'SNa' THEN 'souscripteur : ' 
						WHEN 'CNo' THEN 'convention : '
					END + @Search,
				'SL_UN_SearchUnit',
				'EXECUTE SL_UN_SearchUnit @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


