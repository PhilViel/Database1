/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepNewValidatedSales
Description         :	Rapport des nouvelles ventes validés
Valeurs de retours  :	Dataset 
Note                :						2004-06-14	Bruno Lapointe		Migration et User Problem ADX0000199
								ADX0001014	UP	2006-11-01	Bruno Lapointe		Exclus les BEC
								ADX0001206	IA	2006-11-06	Bruno Lapointe		Optimisation.
								ADX0001285	BR	2007-01-08	Bruno Lapointe		Optimisation.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepNewValidatedSalesPLS] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@StartDate DATETIME, -- Date de début de l'interval
	@EndDate DATETIME, -- Date de fin de l'interval
	@RepID INTEGER) -- ID Unique du rep
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT

	SET @dtBegin = GETDATE()
	-- Préparation du filtre des représetants 
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY )

	IF @Type = 'ALL' -- Si tout les représentants
		INSERT INTO #tRep
			SELECT 
				RepID
			FROM Un_Rep
	ELSE IF @Type = 'DIR' -- Si agence
		INSERT INTO #tRep
			EXECUTE SP_SL_UN_RepOfBoss @RepID
	ELSE IF @Type = 'REP' -- Si un représentant
		INSERT INTO #tRep
		VALUES (@RepID)
	-- Fin de la préparation du filtre des représetants 

	CREATE TABLE #tTFROper (
		OperID INTEGER PRIMARY KEY )

	INSERT INTO #tTFROper
		SELECT OperID
		FROM Un_Oper
		WHERE OperTypeID = 'TFR'

	-- Va chercher le montant de frais provenant de transfert de frais par groupe d'unités
	CREATE TABLE #tUn_RealFeeByUnit (
		UnitID INTEGER PRIMARY KEY,
		FeeTFR MONEY NOT NULL )

	INSERT INTO #tUn_RealFeeByUnit
		SELECT 
			Ct.UnitID, 
			FeeTFR = SUM(Ct.Fee) 
		FROM #tTFROper O
		JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE Ct.Fee > 0
		GROUP BY 
			Ct.UnitID

	-- Va chercher le nombre d'unités qui ont été réduit après la période choisi
	CREATE TABLE #tUnitReductionAfterPeriod (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL )

	INSERT INTO #tUnitReductionAfterPeriod
		SELECT 
			UR.UnitID, 
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE UR.ReductionDate > @EndDate
		GROUP BY 
			UR.UnitID

	-- Va chercher le nombre d'unités active à la fin de la période pour chaque groupe d'unités ainsi que le montant de frais provenant de transfert de frais
	CREATE TABLE #tUn_ActiveUnit (
		UnitID INTEGER PRIMARY KEY,
		ActiveUnitQty MONEY NOT NULL,
		FeeTransferUnitQty MONEY NOT NULL )

	INSERT INTO #tUn_ActiveUnit
		SELECT 
			U.UnitID,
			ActiveUnitQty = U.UnitQty + ISNULL(UR.UnitQty,0),
			FeeTransferUnitQty = 
				CASE
					WHEN ISNULL(V.UnitID,0) = 0 THEN 0
				ELSE U.UnitQty + ISNULL(UR.UnitQty,0) 
				END
		FROM #tRep F -- Filtre des représentants
		JOIN dbo.Un_Unit U ON F.RepID = U.RepID
		LEFT JOIN #tUn_RealFeeByUnit V ON V.UnitID = U.UnitID
		LEFT JOIN #tUnitReductionAfterPeriod UR ON UR.UnitID = U.UnitID
		WHERE U.ValidationConnectID IS NOT NULL
			AND U.dtFirstDeposit BETWEEN @StartDate AND @EndDate

	CREATE TABLE #tNewValidatedSales (
		RepID INTEGER NOT NULL,
		ConventionID INTEGER NOT NULL,
		FirstPmtDate DATETIME NULL,
		InForceDate DATETIME NOT NULL,
		ActiveUnitQty MONEY NOT NULL,
		TerminatedUnitQty MONEY NOT NULL,
		Terminated60UnitQty MONEY NOT NULL,
		PartialTerminatedUnitQty MONEY NOT NULL,
		ReductionUnitQty MONEY NOT NULL,
		FeeTransferUnitQty MONEY NOT NULL,
		CONSTRAINT PK_#tNewValidatedSales PRIMARY KEY (RepID, ConventionID) )

	INSERT INTO #tNewValidatedSales
		SELECT
			U.RepID,
			U.ConventionID,
			FirstPmtDate = MIN(U.dtFirstDeposit),
			InForceDate = MIN(U.InForceDate),
			ActiveUnitQty = ROUND(SUM(V.ActiveUnitQty),3),
			TerminatedUnitQty = SUM(V.TerminatedUnitQty),
			Terminated60UnitQty = SUM(V.Terminated60UnitQty),
			PartialTerminatedUnitQty = SUM(V.PartialTerminatedUnitQty),
			ReductionUnitQty = SUM(V.ReductionUnitQty),
			FeeTransferUnitQty = SUM(V.FeeTransferUnitQty)
		FROM dbo.Un_Unit U
		JOIN (
			SELECT
				UnitID,
				ActiveUnitQty = ActiveUnitQty - FeeTransferUnitQty,
				TerminatedUnitQty = 0,
				Terminated60UnitQty = 0,
				PartialTerminatedUnitQty = 0,
				ReductionUnitQty = 0,
				FeeTransferUnitQty
			FROM #tUn_ActiveUnit
			---------
			UNION ALL
			---------
			SELECT
				U.UnitID,
				ActiveUnitQty = 0,
				TerminatedUnitQty = UR.UnitQty,
				Terminated60UnitQty = 0,
				PartialTerminatedUnitQty = 0,
				ReductionUnitQty = 0,
				FeeTransferUnitQty = 0
			FROM #tRep F
			JOIN dbo.Un_Unit U ON F.RepID = U.RepID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID 
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE U.ValidationConnectID IS NOT NULL
				AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND M.FeeByUnit <= UR.FeeSumByUnit
			---------
			UNION ALL
			---------
			SELECT
				U.UnitID,
				ActiveUnitQty = 0,
				TerminatedUnitQty = 0,
				Terminated60UnitQty = UR.UnitQty,
				PartialTerminatedUnitQty = 0,
				ReductionUnitQty = 0,
				FeeTransferUnitQty = 0
			FROM #tRep F
			JOIN dbo.Un_Unit U ON F.RepID = U.RepID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID
			WHERE U.ValidationConnectID IS NOT NULL
				AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND UR.FeeSumByUnit = 0
			---------
			UNION ALL
			---------
			SELECT
				U.UnitID,
				ActiveUnitQty = 0,
				TerminatedUnitQty = 0,
				Terminated60UnitQty = 0,
				PartialTerminatedUnitQty = UR.UnitQty,
				ReductionUnitQty = 0,
				FeeTransferUnitQty = 0
			FROM #tRep F
			JOIN dbo.Un_Unit U ON F.RepID = U.RepID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID 
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			WHERE U.ValidationConnectID IS NOT NULL
				AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND M.FeeByUnit > UR.FeeSumByUnit
				AND UR.FeeSumByUnit > 0
			---------
			UNION ALL
			---------
			SELECT
				U.UnitID,
				ActiveUnitQty = 0,
				TerminatedUnitQty = 0,
				Terminated60UnitQty = 0,
				PartialTerminatedUnitQty = 0,
				ReductionUnitQty = UR.UnitQty,
				FeeTransferUnitQty = 0
			FROM #tRep F
			JOIN dbo.Un_Unit U ON F.RepID = U.RepID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID 
			WHERE U.ValidationConnectID IS NOT NULL
				AND ISNULL(U.TerminatedDate,0) <> UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
			) V ON V.UnitID = U.UnitID	
	GROUP BY 
		U.RepID,
		U.ConventionID

	UPDATE #tNewValidatedSales
	SET 
		FirstPmtDate = V.FirstPmtDate/*,
		InForceDate = V.InForceDate*/
	FROM #tNewValidatedSales N
	JOIN (
		SELECT
			U.ConventionID,
			FirstPmtDate = MIN(U.dtFirstDeposit),
			InForceDate = MIN(U.InForceDate)
		FROM #tNewValidatedSales N
		JOIN dbo.Un_Unit U ON U.ConventionID = N.ConventionID
		JOIN #tRep R ON R.RepID = U.RepID
		WHERE U.dtFirstDeposit IS NOT NULL
		GROUP BY 
			U.ConventionID,
			N.FirstPmtDate,
			N.InForceDate
		HAVING N.FirstPmtDate <> MIN(U.dtFirstDeposit)
			OR N.FirstPmtDate IS NULL
--			OR N.InForceDate <> MIN(U.InForceDate)
		) V ON V.ConventionID = N.ConventionID

	SELECT
		RepName = HR.LastName + ', ' + HR.FirstName, 
		R.RepCode,
		--Status = dbo.fn_Un_RepStatus(R.BusinessStart, R.BusinessEnd, @EndDate),
		--BossName = 
		--	CASE ISNULL(B.LastName,'') 
		--		WHEN '' THEN ''
		--	ELSE B.LastName + ', ' + B.FirstName 
		--	END, 
		--SubscriberName = HS.LastName + ', ' + HS.FirstName, 
		--C.ConventionNo,
		--P.PlanDesc,
		--UR.FirstPmtDate,
		--UR.InForceDate,
		Sum(UR.ActiveUnitQty) AS Active,
		Sum(UR.TerminatedUnitQty) AS Terminated,
		Sum(UR.Terminated60UnitQty) AS Terminated60,
		Sum(UR.PartialTerminatedUnitQty) AS PartialTerminated,
		Sum(UR.ReductionUnitQty) AS Reduction,
		Sum(UR.FeeTransferUnitQty) AS FeeTransfert
	FROM #tRep F
	JOIN #tNewValidatedSales UR ON F.RepID = UR.RepID
	JOIN dbo.Un_Convention C ON UR.ConventionID = C.ConventionID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN Un_Rep R ON R.RepID = F.RepID
	JOIN dbo.Mo_Human HR ON HR.HumanID = F.RepID
	LEFT JOIN (
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM #tRep F
		JOIN Un_RepBossHist RB ON F.RepID = RB.RepID -- Filtre des représentants
		JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM #tRep F
			JOIN Un_RepBossHist RB ON F.RepID = RB.RepID
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDate
				AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
			GROUP BY 
				RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
			AND RB.StartDate <= @EndDate
			AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
		GROUP BY 
			RB.RepID
		) RB ON RB.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human B ON B.HumanID = RB.BossID
	GROUP BY 
		HR.LastName, 
		HR.FirstName,
		R.RepCode
	ORDER BY 
		HR.LastName, 
		HR.FirstName

END


