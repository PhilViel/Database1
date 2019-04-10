/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_RP_UN_RepNewValidatedSales
Description         :	Rapport des nouvelles ventes validés
Valeurs de retours  :	Dataset 
Note                :						2004-06-14	Bruno Lapointe		Migration et User Problem ADX0000199
								ADX0001014	UP	2006-11-01	Bruno Lapointe		Exclus les BEC
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_RP_UN_RepNewValidatedSales] (
	@Type VARCHAR(3), -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@StartDate DATETIME, -- Date de début de l'interval
	@EndDate DATETIME, -- Date de fin de l'interval
	@RepID INTEGER) -- ID Unique du rep
AS
BEGIN
	-- Préparation du filtre des représetants 
	CREATE TABLE #tRep (
		RepID INTEGER PRIMARY KEY
	)

	IF @Type = 'ALL' -- Si tout les représentants
		INSERT INTO #tRep
			SELECT 
				RepID
			FROM Un_Rep
	ELSE IF @Type = 'DIR' -- Si agence
		INSERT INTO #tRep
			EXEC SP_SL_UN_RepOfBoss @RepID
	ELSE IF @Type = 'REP' -- Si un représentant
		INSERT INTO #tRep
		VALUES (@RepID)
	-- Fin de la préparation du filtre des représetants 

	-- Va chercher la date du premier dépôt de chaque convention
	CREATE TABLE #tUn_ConventionFirstDepositDate (
		ConventionID INTEGER PRIMARY KEY,
		FirstDepositDate DATETIME )

	INSERT INTO #tUn_ConventionFirstDepositDate
		SELECT 
			U.ConventionID, 
			FirstDepositDate =
				CASE 
					WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
				ELSE MIN(O.OperDate) 
				END
		FROM #tRep F -- Filtre des représentants
		JOIN dbo.Un_Unit U ON F.RepID = U.RepID
		JOIN Un_Cotisation Ct ON U.UnitID = Ct.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperTypeID <> 'BEC' -- Exclus les opérations BEC
		GROUP BY 
			U.ConventionID

	-- Va chercher le montant de frais provenant de transfert de frais par groupe d'unités
	CREATE TABLE #tUn_RealFeeByUnit (
		UnitID INTEGER PRIMARY KEY,
		FeeTFR MONEY NOT NULL )

	INSERT INTO #tUn_RealFeeByUnit
		SELECT 
			Ct.UnitID, 
			FeeTFR = SUM(Ct.Fee) 
		FROM #tRep F -- Filtre des représentants
		JOIN dbo.Un_Unit U ON F.RepID = U.RepID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperTypeID = 'TFR'
			AND (Ct.Fee > 0)
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
		FROM #tRep F -- Filtre des représentants
		JOIN dbo.Un_Unit U ON F.RepID = U.RepID
		JOIN Un_UnitReduction UR ON U.UnitID = UR.UnitID
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
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN #tUn_RealFeeByUnit V ON V.UnitID = U.UnitID
		LEFT JOIN #tUnitReductionAfterPeriod UR ON UR.UnitID = U.UnitID
		WHERE U.ValidationConnectID IS NOT NULL
		GROUP BY 
			U.UnitID, 
			U.UnitQty, 
			UR.UnitQty, 
			V.UnitID
		HAVING (MIN(O.OperDate) > = @StartDate)
			AND (MIN(O.OperDate) < = @EndDate)

	SELECT 
		RepName = HR.LastName + ', ' + HR.FirstName, 
		R.RepCode,
		Status = dbo.fn_Un_RepStatus(R.BusinessStart, R.BusinessEnd, @EndDate),
		BossName = 
			CASE ISNULL(B.LastName,'') 
				WHEN '' THEN ''
			ELSE B.LastName + ', ' + B.FirstName 
			END, 
		SubscriberName = HS.LastName + ', ' + HS.FirstName, 
		C.ConventionNo,
		P.PlanDesc,
		FirstPmtDate = FD.FirstDepositDate,
		InForceDate = MIN(U.InForceDate),
		ActiveUnitQty = ROUND(SUM(ISNULL(AU.ActiveUnitQty,0)-ISNULL(AU.FeeTransferUnitQty,0)),3),
		TerminatedUnitQty = SUM(ISNULL(TU.TerminatedUnitQty,0)),
		Terminated60UnitQty = SUM(ISNULL(T60U.Terminated60UnitQty,0)),
		PartialTerminatedUnitQty = SUM(ISNULL(TUP.PartialTerminatedUnitQty,0)),
		ReductionUnitQty = SUM(ISNULL(UR.ReductionUnitQty,0)),
		FeeTransferUnitQty = SUM(ISNULL(AU.FeeTransferUnitQty,0))
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human HR ON HR.HumanID = U.RepID
	JOIN #tUn_ConventionFirstDepositDate FD ON FD.ConventionID = C.ConventionID
	LEFT JOIN (
		SELECT 
			RB.RepID, 
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN #tRep F ON F.RepID = RB.RepID -- Filtre des représentants
		JOIN (
			SELECT 
				RepID, 
				RepBossPct = MAX(RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
			  AND (StartDate IS NOT NULL)
			  AND (StartDate <= @EndDate)
			  AND ((EndDate IS NULL) OR (EndDate >= @EndDate))
			GROUP BY 
				RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
		  AND (RB.StartDate IS NOT NULL)
		  AND (RB.StartDate < = @EndDate)
		  AND ((RB.EndDate IS NULL) OR (RB.EndDate > = @EndDate))
		GROUP BY 
			RB.RepID
		) RB ON RB.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human B ON B.HumanID = RB.BossID
	LEFT JOIN #tUn_ActiveUnit AU ON AU.UnitID = U.UnitID
	LEFT JOIN (
		SELECT
			U.UnitID,
			SUM(UR.UnitQty) AS Terminated60UnitQty
		FROM dbo.Un_Unit U
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE (U.ValidationConnectID IS NOT NULL)
		  AND (UR.ReductionDate >= @StartDate)
		  AND (UR.ReductionDate <= @EndDate)
		  AND (UR.FeeSumByUnit = 0)
		GROUP BY 
			U.UnitID
		) T60U ON T60U.UnitID = U.UnitID
	LEFT JOIN (
		SELECT
			U.UnitID,
			TerminatedUnitQty = SUM(UR.UnitQty)
		FROM dbo.Un_Unit U
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE (U.ValidationConnectID IS NOT NULL)
		  AND (UR.ReductionDate > = @StartDate)
		  AND (UR.ReductionDate < = @EndDate)
		  AND (M.FeeByUnit < = UR.FeeSumByUnit)
		GROUP BY 
			U.UnitID
		) TU ON TU.UnitID = U.UnitID
	LEFT JOIN (
		SELECT
			U.UnitID,
			PartialTerminatedUnitQty = SUM(UR.UnitQty)
		FROM dbo.Un_Unit U
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID AND ISNULL(U.TerminatedDate,0) = UR.ReductionDate
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE (U.ValidationConnectID IS NOT NULL)
		  AND (UR.ReductionDate >= @StartDate)
		  AND (UR.ReductionDate <= @EndDate)
		  AND (M.FeeByUnit > UR.FeeSumByUnit)
		  AND (UR.FeeSumByUnit > 0)
		GROUP BY 
			U.UnitID
		) TUP ON TUP.UnitID = U.UnitID
	LEFT JOIN (
		SELECT
			U.UnitID,
			ReductionUnitQty = SUM(UR.UnitQty)
		FROM dbo.Un_Unit U
		JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID AND ISNULL(U.TerminatedDate,0) <> UR.ReductionDate
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE (U.ValidationConnectID IS NOT NULL)
		  AND (UR.ReductionDate > = @StartDate)
		  AND (UR.ReductionDate < = @EndDate)
		GROUP BY 
			U.UnitID
		) UR ON (UR.UnitID = U.UnitID)
	WHERE (AU.UnitID IS NOT NULL)
		OR (T60U.UnitID IS NOT NULL)
		OR (TU.UnitID IS NOT NULL)
		OR (TUP.UnitID IS NOT NULL)
		OR (UR.UNitID IS NOT NULL)
	GROUP BY 
		C.ConventionNo, 
		R.RepID, 
		HR.LastName, 
		HR.FirstName, 
		R.RepCode,
		R.BusinessStart, 
		R.BusinessEnd, 
		B.LastName, 
		B.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		FD.FirstDepositDate, 
		P.PlanDesc
	ORDER BY 
		B.LastName, 
		B.FirstName, 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		C.ConventionNo

	DROP TABLE #tUn_ConventionFirstDepositDate
	DROP TABLE #tUnitReductionAfterPeriod
	DROP TABLE #tUn_RealFeeByUnit
	DROP TABLE #tUn_ActiveUnit
END


