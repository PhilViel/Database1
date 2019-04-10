/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionLatePmtByChq
Description         :	Recherche des conventions payant par chèque et qui  sont en retard.
Valeurs de retours  :	Dataset :
									ConventionID		INTEGER		ID de la convention.
									ConventionNo		VARCHAR(75)	Numéro de convention.
									SubscriberID		INTEGER		ID du souscripteur.
									LastName				VARCHAR(50)	Nom du souscripteur.
									FirstName			VARCHAR(35)	Prénom du souscripteur.
									Prelevement 		DATETIME		Date estimée du prochain prélèvement
									MntRetard			MONEY			Montant en retard sur les dépôts 
									MntDepot			 	MONEY			Montant d'un dépôt 
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe		Création
												2013-07-16	Maxime martel		Ajouts des paramètres de dates
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionLatePmtByChq] (
	@ConnectID INTEGER, -- Identifiant unique de la connection	
	@SearchType CHAR(3), -- Type de recherche : LNa (Nom, Prénom), FNa (Prénom, Nom), CNo (ConventionNo)
	@Search VARCHAR(75), -- Chaîne de caractère servant de critère à la recherche
	@dateDebut datetime = null,
	@dateFin datetime = null) 
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT
	
	SET @dtBegin = GETDATE()

	IF @dateDebut is null or @dateFin is null
	BEGIN
		SET @dateDebut = '1950-01-01'
		SET @dateFin = '2050-12-31'
	END

	DECLARE @tSearchConvPmtByChq TABLE (
		ConventionID INTEGER PRIMARY KEY,
		SubscriberID INTEGER NOT NULL)

	INSERT INTO @tSearchConvPmtByChq
		SELECT ConventionID, SubscriberID
		FROM dbo.Un_Convention 
		WHERE PmtTypeID = 'CHQ' -- payée par chèque

	DECLARE @tSearchConv TABLE (
		ConventionID INTEGER PRIMARY KEY)

	-- Nom, prénom
	IF @SearchType = 'LNa'
		INSERT INTO @tSearchConv
			SELECT tC.ConventionID
			FROM @tSearchConvPmtByChq tC
			JOIN dbo.Mo_Human H ON H.HumanID = tC.SubscriberID
			WHERE H.LastName + ', ' + H.FirstName LIKE @Search
	-- Prénom, nom
	ELSE IF @SearchType = 'FNa'
		INSERT INTO @tSearchConv
			SELECT tC.ConventionID
			FROM @tSearchConvPmtByChq tC
			JOIN dbo.Mo_Human H ON H.HumanID = tC.SubscriberID
			WHERE H.FirstName + ', ' + H.LastName LIKE @Search
	-- Numéro de convention
	ELSE IF @SearchType = 'CNo'
		INSERT INTO @tSearchConv
			SELECT tC.ConventionID
			FROM @tSearchConvPmtByChq tC
			JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
			WHERE C.ConventionNo LIKE @Search

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
			FROM @tSearchConv C
			JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
			)
		GROUP BY Ct.UnitID

	-- Conventions avec retard de paiement par nombre de paiement annuels et date du prochain paiement  
	SELECT 
		C.ConventionNo,
		C.ConventionID, 
		C.SubscriberID,
		H.LastName,
		H.FirstName, 
		Prelevement = convert(varchar(11),dbo.FN_UN_GetNextDepositDate ( -- fonction qui retourne la date du prochain paiement
			GETDATE(), -- Date du jour
			U.InForceDate, -- Date de départ
			M.PmtByYearID, -- Nombre de dépôt par année 
			DAY(C.FirstPmtDate)), 120), -- Jour de paiement
		MntRetard = SUM(dbo.FN_UN_EstimatedCotisationAndFee( -- fonction qui retourne le montant théorique de cotisation et de frais à payer
				U.InForceDate, -- Date de départ
				GETDATE(), -- Date de fin
				DAY(C.FirstPmtDate), -- Jour de paiement
				U.UnitQty, -- Nombre d'unités
				M.PmtRate, -- Montant de paiement par unité
				M.PmtByYearID, -- Nombre de dépôt par année 
				M.PmtQty, -- Nombre de dépôt total pour un groupe d'unité
				U.InForceDate)) -  -- Date vigueur )
			(SUM(ISNULL(Cotisation, 0)) + SUM(ISNULL(Fee, 0))), -- on soustrait les cotisations et les frais déjà payés
		MntDepot = SUM(ROUND(M.PmtRate*U.UnitQty,2)) -- montant à déposer périodiquement
	FROM @tSearchConv tC
	JOIN dbo.Un_Convention C ON C.ConventionID = tC.ConventionID
	JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON U.ModalID = M.ModalID
	JOIN dbo.Mo_Human H ON C.SubscriberID = H.HumanID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	LEFT JOIN #tCotisation S ON U.UnitID = S.UnitID -- Retrouve les sommes réelles de cotisations et de frais 
	WHERE ISNULL(U.TerminatedDate, GETDATE() + 1) > GETDATE() -- non-résiliée
		AND U.IntReimbDate IS NULL -- sans RI
		AND U.ActivationConnectID IS NOT NULL -- Activées
		AND P.PlanTypeID <> 'IND' -- Exclus les individuels
		and dbo.FN_UN_GetNextDepositDate (GETDATE(), U.InForceDate, M.PmtByYearID, DAY(C.FirstPmtDate)) between @dateDebut and @dateFin
	GROUP BY C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID,
		H.LastName,
		H.FirstName,
		M.PmtByYearID, -- nb de paiement par année
		dbo.FN_UN_GetNextDepositDate ( -- fonction qui retourne la date du prochain paiement
			GETDATE(), -- Date du jour
			U.InForceDate, -- Date de départ
			M.PmtByYearID, -- Nombre de dépôt par année 
			DAY(C.FirstPmtDate))
	HAVING -- Qui sont en retard de paiement 
		SUM(ISNULL(Cotisation, 0)) + SUM(ISNULL(Fee, 0)) < 
		SUM(dbo.FN_UN_EstimatedCotisationAndFee( -- fonction qui retourne le montant théorique de cotisation et de frais à payer
			U.InForceDate, -- Date de départ
			GETDATE(), -- Date de fin
			DAY(C.FirstPmtDate), -- Jour de paiement
			U.UnitQty, -- Nombre d'unités
			M.PmtRate, -- Montant de paiement par unité
			M.PmtByYearID, -- Nombre de dépôt par année 
			M.PmtQty, -- Nombre de dépôt total pour un groupe d'unité
			U.InForceDate)) -- Date vigueur )
	ORDER BY CASE @SearchType
					WHEN 'LNa' THEN H.LastName
					WHEN 'FNa' THEN H.FirstName 
					ELSE C.ConventionNo
				END,
		CASE @SearchType
			WHEN 'FNa' THEN H.LastName
			WHEN 'LNa' THEN H.FirstName 
		END

/*
	SET @dtEnd = @DateFin 

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
				'Recherche de conv. payant par chèque en retard par '+
					CASE @SearchType
						WHEN 'LNa' THEN 'nom, prénom : ' 
						WHEN 'FNa' THEN 'prénom, nom : ' 
						WHEN 'CNo' THEN 'no convention : '
					END + @Search,
				'SL_UN_SearchConventionLatePmtByChq',
				'EXECUTE SL_UN_SearchConventionLatePmtByChq @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @SearchType = '+@SearchType+
					', @Search = '+@Search*/
END


