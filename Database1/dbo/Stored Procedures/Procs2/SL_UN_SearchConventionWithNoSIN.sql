/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionWithNoSIN
Description         :	Recherche des conventions sans NAS.
Valeurs de retours  :	Dataset :
							ConventionID	INTEGER			ID de la convention.
							InForceDate		DATETIME		Date d’entrée en vigueur de la convention
							ConventionNo	VARCHAR(75)		Numéro de convention.
							SubscriberID	INTEGER			ID du souscripteur.
							SubscriberName	VARCHAR(87)		Nom, prénom du souscripteur.
							RepID			INTEGER			ID du représentant.
							RepName			VARCHAR(87)		Nom, prénom du représentant du souscripteur.

Note                :	
ADX0001344	IA	2007-04-17	Alain Quirion		Création
ADX0003061	UR	2007-09-12	Bruno Lapointe		Ajout des trois colonnes FirstPmtDate, PmtQty, PmtByYearID
				2012-09-28	Donald Huppé		glpi 7338

exec SL_UN_SearchConventionWithNoSIN 1,'VIG','2011-05-06'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionWithNoSIN] (
	@ConnectID INTEGER,		--ID de connexion de l’usager qui fait la recherche	
	@cSearchType CHAR(3),	--Type de recherche : VIG = Date d’entrée en vigueur de la convention
	@vcSearch VARCHAR(87))	--Critères de recherche

AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceSearch SMALLINT,
		@Today DATETIME

	SET @dtBegin = GETDATE()
	SET @Today = GETDATE()

	-- Table des conventions transitoire (sans NAS)
	CREATE TABLE #tConventionNoSIN(
		ConventionID INTEGER PRIMARY KEY,
		InforceDate DATETIME,
		PmtQty INT,
		PmtByYearID INT,
		DateVigueurLegale DATETIME)

	-- Type de recherche : VIG = Date d’entrée en vigueur de la convention
	IF @cSearchType = 'VIG'
		INSERT INTO #tConventionNoSIN
			SELECT 
				C.ConventionID,
				U.InforceDate,
				U.PmtQty,
				U.PmtByYearID,
				DateVigueurLegale = dbo.fnCONV_ObtenirEntreeVigueurObligationLegale(C.ConventionID)
			FROM dbo.Un_Convention C
			JOIN (	
				SELECT 
					U.ConventionID,
					InForceDate = MIN(U.InforceDate),
					PmtQty = MAX(M.PmtQty),
					PmtByYearID = MAX(M.PmtByYearID)
				FROM dbo.Un_Unit U
				JOIN Un_Modal M ON M.ModalID = U.ModalID
				GROUP BY U.ConventionID
				) U ON U.ConventionID = C.ConventionID
			JOIN (	
				SELECT
					ConventionID,
					ConventionConventionStateID = MAX(ConventionConventionStateID)
				FROM Un_ConventionConventionState 
				GROUP BY ConventionID
				) CCS ON CCS.ConventionID = C.ConventionID
			JOIN Un_ConventionConventionState CCS2 ON CCS2.ConventionConventionStateID = CCS.ConventionConventionStateID
			LEFT JOIN Un_Breaking BR ON BR.ConventionID = C.ConventionID
										AND BR.BreakingStartDate <= @Today
										AND ISNULL(BR.BreakingEndDate, '9999-12-31') >= @Today
										AND BR.BreakingTypeID = 'RNA'
			WHERE 
					CCS2.ConventionStateID = 'TRA'
					AND BR.BreakingID IS NULL
					--AND U.InforceDate <= CAST(@vcSearch AS DATETIME)

	SELECT 
		C.ConventionID,
		InforceDate = DateVigueurLegale,
		C.ConventionNo,
		S.SubscriberID,
		SubscriberName = CASE
							WHEN HS.isCompany = 1 THEN HS.LastName 
							ELSE HS.LastName + ', ' + HS.FirstName
						END,
		S.RepID,
		RepName = HR.LastName + ', ' + HR.FirstName,
		C.FirstPmtDate,
		CS.PmtQty,
		CS.PmtByYearID
		--,DateVigueurLegale
	FROM #tConventionNoSIN CS
	JOIN dbo.Un_Convention C ON C.ConventionID = CS.ConventionID	
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	LEFT JOIN dbo.Mo_Human HR ON HR.HumanID = S.RepID
	WHERE CS.DateVigueurLegale <= CAST(@vcSearch AS DATETIME)
	ORDER BY 
		CS.InForceDate,
		C.ConventionNo

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
				'Recherche de convention sans NAS dont le type de recherche est '+ CAST(@cSearchType AS VARCHAR) + ' et le critère est' + CAST(@vcSearch AS VARCHAR),
				'SL_UN_SearchConventionWithNoSIN',
				'EXECUTE SL_UN_SearchConventionWithNoSIN @ConnectID =' + CAST(@ConnectID AS VARCHAR)+
					', @cSearchType =' + CAST(@cSearchType AS VARCHAR)+	
					', @vcSearch =' + CAST(@vcSearch AS VARCHAR)
	END	

	-- FIN DES TRAITEMENTS
	RETURN 0
END


