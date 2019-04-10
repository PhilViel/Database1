/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchSubscriberAddressLost
Description         :	Procédure de recherche des souscripteurs dont on a perdue l'adresse.

Exemple d'appel		:
						EXECUTE dbo.SL_UN_SearchSubscriberAddressLost 2,'FNa','%',0

Valeurs de retours  :	Dataset :
									SubscriberID	INTEGER			ID du souscripteur, correspond au HumanID.
									LastName			VARCHAR(50)		Nom
									FirstName		VARCHAR(35)		Prénom
									HoldPayment		VARCHAR(3)		Arrêt de paiement (oui ou non)
									DepositAmount	MONEY				Montant de dépôt (épargne et frais seulement)
									DiffAmount		MONEY				Retard (épargne et frais seulement s’il y a lieu)
									Modal				VARCHAR(15)		Mode de dépôt (mensuel, annuel ou unique)
									Phone1			VARCHAR(27)		Téléphone maison
									Phone2			VARCHAR(27)		Téléphone bureau
Note                :					IA	2004-05-31	Bruno Lapointe		Création point 10.8.7.2 (1.1)
								ADX0001185	IA	2006-11-22	Bruno Lapointe		Optimisation, normalisation
												2008-12-11	Pierre-Luc Simard	Recherche par nom et prénom sans tenir compte des accents
												2010-02-16	Jean-François Gauthier  Ajout du critère de recherche IDs afin de chercher avec l'identifiant du souscripteur
												2010-02-22	Jean-François Gauthier	Modification pour afficher uniquement les conventions actives (sans date de résiliationo)
																					dont la date du RIN est inférieure à 3 ans
																					Ajout du critère de recherche sur la date de mise en fonction de l'adresse invalide (DTf)
												2010-02-25	Jean-François Gauthier	Modification afin de retourner la date de mise en fonction dans le dataset
																					Élimination du type de recherche DTf
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchSubscriberAddressLost] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@SearchType CHAR(3), -- Type de recherche: LNa(Nom, prénom), FNa(Prénom, nom), Pho(Telephone)
	@Search VARCHAR(87), -- Critère de recherche
	@RepID INTEGER = 0) -- Identifiant unique du représentant (0 pour tous)
AS
BEGIN
	DECLARE 
		@Today DATETIME,
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT

	SET @dtBegin = GETDATE()
	SET @Today = GETDATE()

	DECLARE @tSearchSubsLost TABLE (
		HumanID INTEGER PRIMARY KEY)

	INSERT INTO @tSearchSubsLost
		SELECT SubscriberID
		FROM dbo.Un_Subscriber 
		WHERE AddressLost = 1
			AND( @RepID = 0
				OR @RepID = RepID
				)

	DECLARE @tSearchSubs TABLE (
		SubscriberID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @SearchType = 'LNa'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM @tSearchSubsLost S
			JOIN dbo.Mo_Human H ON H.HumanID = S.HumanID
			WHERE H.LastName + ', ' + H.FirstName COLLATE French_CI_AI LIKE @Search
	-- Prénom, nom
	ELSE IF @SearchType = 'FNa'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM @tSearchSubsLost S
			JOIN dbo.Mo_Human H ON H.HumanID = S.HumanID
			WHERE H.FirstName + ', ' + H.LastName COLLATE French_CI_AI LIKE @Search
	-- Téléphone résidentiel
	ELSE IF @SearchType = 'Pho'
		INSERT INTO @tSearchSubs
			SELECT H.HumanID
			FROM @tSearchSubsLost S
			JOIN dbo.Mo_Human H ON H.HumanID = S.HumanID
			JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
			WHERE A.Phone1 LIKE @Search
	-- 2010-02-16 : JFG : Ajout : Recherche par identifiant
	ELSE IF @SearchType = 'IDs'
		BEGIN
			INSERT INTO @tSearchSubs
			(SubscriberID)
			VALUES
			(CAST(@Search AS INT))
		END
		
	CREATE TABLE #tCotisation (
		UnitID INTEGER PRIMARY KEY,
		Cotisation MONEY NOT NULL,
		Fee MONEY NOT NULL )

	INSERT INTO #tCotisation
		SELECT
			Ct.UnitID,
			SUM(Ct.Cotisation),
			SUM(Ct.Fee)
		FROM Un_Cotisation Ct
		WHERE Ct.UnitID IN (
			SELECT U.UnitID
			FROM @tSearchSubs S
			JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			)
		GROUP BY Ct.UnitID

	-- Recherche des souscripteurs selon les critères passés en paramètre
	SELECT 
		S.SubscriberID,
		H.LastName, -- Nom
		H.FirstName, -- Prénom
		V.HoldPayment,-- Arrêt de paiement (oui ou non)
		DepositAmount = SUM(V.DepositAmount), -- Montant de dépôt (épargne et frais seulement)
		DiffAmount = SUM(V.DiffAmount), -- Retard (épargne et frais seulement s’il y a lieu)
		V.Modal, -- Mode de dépôt (mensuel, annuel ou unique)
		Phone1 = ISNULL(A.Phone1, ''), -- Téléphone maison
		Phone2 = ISNULL(A.Phone2, ''), -- Téléphone bureau
		A.InForce					   -- Date de mise en fonction : Ajout : JFG : 2010-02-25
	FROM	
		@tSearchSubs S
		JOIN dbo.Mo_Human H 
			ON H.HumanID = S.SubscriberID
		LEFT JOIN dbo.Mo_Adr A 
			ON H.AdrID = A.AdrID
		LEFT JOIN dbo.Un_Convention C 
			ON C.SubscriberID = S.SubscriberID 
		LEFT OUTER JOIN dbo.Un_Unit u				-- AJOUT : JFG : 2010-02-22
			ON u.ConventionID = C.ConventionID
		LEFT JOIN (
					SELECT 
						U.ConventionID,
						Modal = 
							CASE 
								WHEN M.PmtQty = 1 THEN 'Unique'
								WHEN M.PmtByYearID = 1 THEN 'Annuel'
								WHEN M.PmtByYearID = 2 THEN 'Semi-Annuel'
								WHEN M.PmtByYearID = 3 THEN 'Trimestriel'
								WHEN M.PmtByYearID = 12 THEN 'Mensuel'
							ELSE 'Inconnu'
							END,
						DiffAmount =
							dbo.FN_UN_EstimatedCotisationAndFee (
								U.InForceDate,
								@Today,
								DAY(C.FirstPmtdate),
								U.UnitQty,
								M.PmtRate,
								M.PmtByYearID,
								M.PmtQty,
								U.InForceDate) -
							(ISNULL(Ct.Cotisation,0)+ISNULL(Ct.Fee,0)),
						DepositAmount = ROUND(M.PmtRate * U.UnitQty,2),
						HoldPayment = 
							CASE 
								WHEN CB.ConventionID IS NOT NULL OR UHP.UnitID IS NOT NULL THEN 'Oui'
							ELSE 'Non'
							END
					FROM 
							@tSearchSubs S
							JOIN dbo.Un_Convention C ON C.SubscriberID = S.SubscriberID
							JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
							JOIN Un_Modal M ON M.ModalID = U.ModalID
							LEFT JOIN #tCotisation Ct ON Ct.UnitID = U.UnitID
							LEFT JOIN (
										SELECT DISTINCT
											UnitID
										FROM Un_UnitHoldPayment  
										WHERE @Today BETWEEN StartDate AND ISNULL(EndDate, @Today+1)
										) UHP ON UHP.UnitID = U.UnitID
			LEFT JOIN (
				SELECT DISTINCT
					ConventionID
				FROM Un_Breaking  
				WHERE @Today BETWEEN BreakingStartDate AND ISNULL(BreakingEndDate, @Today+1)
				) CB ON CB.ConventionID = U.ConventionID
		) V ON V.ConventionID = C.ConventionID
	WHERE					-- AJOUT : JFG : 2010-02-22
		u.TerminatedDate IS NULL
		AND
		DATEDIFF(mm,u.IntReimbDate, GETDATE()) < 36
	GROUP BY 
		S.SubscriberID, 
		H.LastName, 
		H.FirstName, 
		V.HoldPayment,
		V.Modal,
		A.Phone1,
		A.Phone2,
		A.InForce		
	ORDER BY 
		CASE @SearchType
			WHEN 'LNa' THEN H.LastName + ', ' + H.FirstName
			WHEN 'FNa' THEN H.FirstName + ', ' + H.LastName
			WHEN 'Pho' THEN A.Phone1
			WHEN 'IDs' THEN CAST(S.SubscriberID AS VARCHAR(255))
		END,
		CASE @SearchType
			WHEN 'LNa' THEN H.FirstName
			ELSE H.LastName
		END,
		CASE 
			WHEN @SearchType IN ('LNa', 'FNa') THEN A.Phone1
			ELSE H.FirstName
		END

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
				'Recherche de sous. avec adresse perdue par '+
					CASE @SearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'Pho' THEN 'téléphone : ' 
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'IDs' THEN 'identifiant du souscripteur : '
					END + CAST(@Search AS VARCHAR(255)),
				'SL_UN_SearchSubscriberAddressLost',
				'EXECUTE SL_UN_SearchSubscriberAddressLost @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


