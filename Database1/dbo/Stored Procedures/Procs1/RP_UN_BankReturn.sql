/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	RP_UN_BankReturn
Description         :	RAPPORT DES EFFETS RETOURNÉS
Valeurs de retours  :	
				
Note                :	ADX0001206	IA	2006-12-18	Alain Quirion		Optimisation
										2014-06-18	Maxime Martel		BankReturnTypeID varchar(3) -> varchar(4)
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BankReturn] (	
	@ConnectID INTEGER,
	@BankReturnTypeID VARCHAR(4), -- ID des types d'effets retournés
	@StartDate DATETIME,  -- Date de début de la période
	@EndDate DATETIME, -- Date de fin de la période
	@RepID INTEGER = 0 -- Limiter les résultats selon un représentant, 0 pour tous
)
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()

	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	INSERT #TB_Rep
		EXEC SL_UN_BossOfRep @RepID

	SELECT 
		SubscriberName = H.LastName + ' ' + H.FirstName, 
		C.ConventionNo, 
		InforceDate = MIN(U.InForceDate) , 
		UnitQty = SUM(U.UnitQty), 
		V2.Cotisation, 	
		V2.Fee,
		Deposit = SUM(ROUND(M.PmtRate * U.UnitQty,2)),
		Interruption = CASE 
					WHEN V3.ConventionID IS NULL THEN 'Non' 
					ELSE 'Oui' 
				END,
		V.NbNSF
	FROM dbo.Un_Unit U
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN dbo.Un_Subscriber S ON C.SubscriberID = S.SubscriberID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN ( --Va chercher le nombre de NSF de la convention
		SELECT 
			U.ConventionID,
			NbNSF = COUNT(DISTINCT O.OperID)
		FROM Mo_BankReturnLink R
		JOIN Un_Oper O ON O.OperID = R.BankReturnCodeID
		JOIN Un_Cotisation Ct ON Ct.OperID = O.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		WHERE R.BankReturnTypeID = @BankReturnTypeID
			AND O.OperDate BETWEEN @StartDate AND @EndDate
		GROUP BY U.ConventionID	) V ON V.ConventionID = C.ConventionID
	
	JOIN ( --Va chercher l'épargnes et les frais accumulés
			SELECT 
				U.ConventionID,
				Cotisation = SUM(Ct.Cotisation),
				Fee = SUM(Ct.Fee)
			FROM Un_Cotisation Ct 
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			GROUP BY U.ConventionID	)V2 ON V2.ConventionID = C.ConventionID	
	LEFT JOIN ( --Détermine si la convention est actuellement en interruption
			SELECT DISTINCT ConventionID
			FROM Un_Breaking
			WHERE BreakingStartDate <= GETDATE()
				AND ISNULL(BreakingEndDate, GETDATE()) >= GETDATE()) V3 ON V3.ConventionID = C.ConventionID
	LEFT JOIN #TB_Rep B ON S.RepID = B.RepID
	WHERE (B.RepID IS NOT NULL OR @RepID = 0) -- selon le rep
	GROUP BY H.LastName, H.FirstName, C.ConventionNo, V.NbNSF, V2.Cotisation, V2.Fee, V3.ConventionID
	ORDER BY V.NbNSF, H.LastName, H.FirstName
	
	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
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
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport des effets retournés selon le type : ' + CAST(@BankReturnTypeID AS VARCHAR) + ' entre le ' + CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR),
				'RP_UN_BankReturn',
				'EXECUTE RP_UN_BankReturn @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @BankReturnTypeID ='+CAST(@BankReturnTypeID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+	
				', @RepID ='+CAST(@RepID AS VARCHAR)
	END	
END


