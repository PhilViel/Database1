/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionHoldPayment
Description         :	Recherche des conventions qui sont en arrêt de paiements pendant une journée de la 
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
Note                :	ADX0000831	IA	2006-04-06	Bruno Lapointe			Création
								ADX0001185	IA	2006-11-30	Bruno Lapointe			Optimisation
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionHoldPayment] (	
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME,  -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@RepID INTEGER = 0 ) -- Limiter les résultats selon un représentant, 0 pour tous
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
	INSERT #tRep
		EXECUTE SL_UN_BossOfRep @RepID

	CREATE TABLE #tConvBreaking (
		ConventionID INTEGER PRIMARY KEY,
		EstimatedAmount MONEY NOT NULL )

	-- Retrouve les montants théoriques (estimés) par convention
	INSERT INTO #tConvBreaking
		SELECT 
			U.ConventionID,  
			EstimatedAmount = SUM(dbo.fn_Un_EstimatedCotisationANDFee(U.InForceDate, GETDATE(), DAY(C.FirstPmtDate), U.UnitQty, M.PmtRate, M.PmtByYearID, M.PmtQty, U.InForceDate))  
		FROM dbo.Un_Convention C  
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Breaking B ON B.ConventionID = C.ConventionID
		WHERE	(	( B.BreakingStartDate < @StartDate
					AND ISNULL(B.BreakingEndDate, @StartDate) >= @StartDate
					)
				OR ( B.BreakingStartDate >= @StartDate
					AND B.BreakingStartDate <= @EndDate
					)
				)
			AND ISNULL(U.TerminatedDate, 0) < 1
			AND ISNULL(U.IntReimbDate,0) < 1
		GROUP BY U.ConventionID

	-- Retourne les conventions qui sont en arrêt de paiement pendant une journée de la période 
	SELECT   
		C.ConventionID,  
		C.ConventionNo,  
		C.SubscriberID,  
		SubscriberName = 
			CASE 
				WHEN H.IsCompany = 1 THEN H.LastName
			ELSE H.LastName + ', ' + H.FirstName
			END,
		BreakingStartDate = dbo.fn_Mo_DateNoTime(B.BreakingStartDate),  
		BreakingEndDate = dbo.fn_Mo_DateNoTime(B.BreakingEndDate),  
		B.BreakingReason,  
		Cotisation = ISNULL(SUM(Ct.Cotisation),0),  
		RealAmount = ISNULL(SUM(Ct.Cotisation + Ct.Fee),0),  
		T.EstimatedAmount 
	FROM #tConvBreaking T
	JOIN dbo.Un_Convention C ON C.ConventionID = T.ConventionID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN #tRep R ON S.RepID = R.RepID OR R.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN Un_Breaking B ON B.ConventionID = C.ConventionID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	LEFT JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	WHERE	ISNULL(U.TerminatedDate,0) < 1
		AND ISNULL(U.IntReimbDate,0) < 1
	GROUP BY 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		H.LastName, 
		H.FirstName,
		H.IsCompany, 
		B.BreakingStartDate, 
		B.BreakingEndDate, 
		B.BreakingReason, 
		T.EstimatedAmount 
	ORDER BY 
		C.ConventionNo  

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
				'Recherche de conv. en arrêt de paiement entre le '+CAST(@StartDate AS VARCHAR)+' et le '+CAST(@EndDate AS VARCHAR),
				'SL_UN_SearchConventionHoldPayment',
				'EXECUTE SL_UN_SearchConventionHoldPayment @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @StartDate = '+CAST(@StartDate AS VARCHAR)+
					', @EndDate = '+CAST(@EndDate AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


