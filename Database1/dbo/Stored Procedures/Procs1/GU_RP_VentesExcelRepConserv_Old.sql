/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepConserv
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants et par directeurs pour la création du fichier Excel
Valeurs de retours  :	Dataset 
Note                :	Pierre-Luc Simard	2008-01-11 	Création selon le rapport des unités brutes et nettes RP_UN_RepGrossANDNetUnits
                        Pierre-Luc Simard   2018-10-29  N'est plus utilisée
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepConserv_Old](
	@ReptreatmentID INTEGER) -- ID du traitement de commissions)

AS
BEGIN
    
    SELECT 1/0
    /*
	SET NOCOUNT ON
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@LastTreatmentDate DATETIME,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER

	SELECT 
		@CurrentTreatmentDate = RepTreatmentDate,
		@TreatmentYear = YEAR(RepTreatmentDate)
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @ReptreatmentID

	DECLARE @tYearRepTreatment TABLE (
		RepTreatmentID INTEGER PRIMARY KEY,
		RepTreatmentDate DATETIME NOT NULL,
		LastRepTreatmentDate DATETIME NULL )

	INSERT INTO @tYearRepTreatment
		SELECT
			R.RepTreatmentID,
			R.RepTreatmentDate,
			LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0))
		FROM Un_RepTreatment R
		LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
		WHERE YEAR(R.RepTreatmentDate) = @TreatmentYear
			AND R.RepTreatmentDate <= @CurrentTreatmentDate
		GROUP BY 
			R.RepTreatmentID,
			R.RepTreatmentDate

	--Unit DIR
	DECLARE @tMaxPctBoss TABLE (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL,
		BossID INTEGER NOT NULL )

	INSERT INTO @tMaxPctBoss
		SELECT 
			M.UnitID,
			M.UnitQty,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
				U.UnitQty,
				U.RepID,
				RepBossPct = MAX(RBH.RepBossPct)
			FROM dbo.Un_Unit U
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
			JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
			JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
			GROUP BY U.UnitID, U.RepID, U.UnitQty
			) M
		JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY 
			M.UnitID,
			M.UnitQty
		--HAVING @RepID = 0 OR MAX(RBH.BossID) = @RepID

	--Premier depot
	DECLARE @tFirstDeposit TABLE (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER NOT NULL,
		FirstDepositDate DATETIME NOT NULL )

	INSERT INTO @tFirstDeposit
		SELECT 
			U.UnitID,
			U.RepID,
			FirstDepositDate = U.dtFirstDeposit
		FROM dbo.Un_Unit U
		LEFT JOIN @tMaxPctBoss M ON M.UnitID = U.UnitID
		WHERE	--( @RepID = 0
		--		OR @RepID = U.RepID
		--		OR M.BossID IS NOT NULL
		--		)
			--AND 
			U.RepID IS NOT NULL
			AND U.dtFirstDeposit IS NOT NULL
	--Unitees brutes REP
	SELECT 
		U.RepID,
		T.RepTreatmentID,
		UnitQty = 
			SUM(
				CASE 
					WHEN F.FirstDepositDate > T.LastRepTreatmentDate THEN U.UnitQty + ISNULL(UR.UnitQty,0)
				ELSE 0
				END), -- Unitees brutes
		UnitQty24 = SUM(U.UnitQty + ISNULL(UR.UnitQty,0)) -- Unitees brutes
	INTO #NewSales
	FROM @tFirstDeposit F
	JOIN @tYearRepTreatment T ON (F.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (F.FirstDepositDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	--WHERE @RepID = 0
	--	OR @RepID = U.RepID
	GROUP BY 
		U.RepID,
		T.RepTreatmentID

	-- Retraits frais non couverts REP
	SELECT 
		U.RepID,
		T.RepTreatmentID,
		UnitQty = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN UR.UnitQty
				ELSE 0
				END), 
		UnitQty24 = SUM(UR.UnitQty)
	INTO #Terminated
	FROM Un_UnitReduction UR
	JOIN @tYearRepTreatment T ON (UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
	--	AND( @RepID = 0
	--		OR @RepID = U.RepID
	--		)
	GROUP BY 
		U.RepID,
		T.RepTreatmentID

	--Unitees brutes DIR
	SELECT 
		M.BossID,
		T.RepTreatmentID,
		UnitQty = 
			SUM(
				CASE 
					WHEN F.FirstDepositDate > T.LastRepTreatmentDate THEN U.UnitQty + ISNULL(UR.UnitQty,0)
				ELSE 0
				END), -- Unitees brutes
		UnitQty24 = SUM(U.UnitQty + ISNULL(UR.UnitQty,0)) -- Unitees brutes
	INTO #NewSalesDIR
	FROM @tMaxPctBoss M
	JOIN @tFirstDeposit F ON M.UnitID = F.UnitID
	JOIN @tYearRepTreatment T ON (F.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (F.FirstDepositDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	GROUP BY 
		M.BossID,
		T.RepTreatmentID

	-- Retraits frais non couverts DIR
	SELECT 
		MP.BossID,
		T.RepTreatmentID,
		UnitQty = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN UR.UnitQty
				ELSE 0
				END), 
		UnitQty24 = SUM(UR.UnitQty)
	INTO #TerminatedDir
	FROM @tMaxPctBoss MP
	JOIN Un_UnitReduction UR ON MP.UnitID = UR.UnitID
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN @tYearRepTreatment T ON (UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	WHERE UR.FeeSumByUnit < M.FeeByUnit
	GROUP BY 
		MP.BossID,
		T.RepTreatmentID

	SELECT 
		V.RepID,
		V.RepTreatmentID,
		U.RepTreatmentDate,
		Brut = SUM(V.Brut),
		Retraits = SUM(V.Retraits),
		Net = SUM(V.Brut) - SUM(V.Retraits),
		BrutDIR = SUM(V.BrutDIR),
		RetraitsDIR = SUM(V.RetraitsDIR),
		NetDIR = SUM(V.BrutDIR) - SUM(V.RetraitsDIR),
		Brut24 = SUM(V.Brut24),
		Retraits24 = SUM(V.Retraits24),
		Net24 = SUM(V.Brut24) - SUM(V.Retraits24),
		Brut24DIR = SUM(V.Brut24DIR),
		Retraits24DIR = SUM(V.Retraits24DIR),
		Net24DIR = SUM(V.Brut24DIR) - SUM(V.Retraits24DIR)
  INTO #Temp
  FROM (
		SELECT
			NS.RepID,
         NS.RepTreatmentID,
         Brut = NS.UnitQty,
         Retraits = 0,
         BrutDIR = 0,
         RetraitsDIR = 0,
         Brut24 = NS.UnitQty24,
         Retraits24 = 0,
         Brut24DIR = 0,
         Retraits24DIR = 0
		FROM @tYearRepTreatment Y
		JOIN #NewSales NS ON NS.RepTreatmentID = Y.RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT 
			T.RepID,
			T.RepTreatmentID,
			Brut = 0,
			Retraits = T.UnitQty,
         BrutDIR = 0,
         RetraitsDIR = 0,
         Brut24 = 0,
         Retraits24 = T.UnitQty24,
         Brut24DIR = 0,
         Retraits24DIR = 0
		FROM @tYearRepTreatment Y
		JOIN #Terminated T ON Y.RepTreatmentID = T.RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT 
			RepID = NS.BossID,
			NS.RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			BrutDIR = NS.UnitQty,
         RetraitsDIR = 0,
         Brut24 = 0,
         Retraits24 = 0,
         Brut24DIR = NS.UnitQty24,
         Retraits24DIR = 0
		FROM @tYearRepTreatment Y
		JOIN #NewSalesDIR NS ON NS.RepTreatmentID = Y.RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT 
			RepID = T.BossID,
			T.RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			BrutDIR = 0,
			RetraitsDIR = T.UnitQty,
         Brut24 = 0,
         Retraits24 = 0,
         Brut24DIR = 0,
         Retraits24DIR = T.UnitQty24
		FROM @tYearRepTreatment Y
		JOIN #TerminatedDir T ON Y.RepTreatmentID = T.RepTreatmentID
       ) V
	JOIN Un_RepTreatment U ON U.RepTreatmentID = V.RepTreatmentID
	GROUP BY 
		V.RepID,
		V.RepTreatmentID,
		U.RepTreatmentDate
	ORDER BY 
		V.RepID,
		V.RepTreatmentID

--------------------------------------------------
------------------- MAIN -------------------------
--------------------------------------------------
	SELECT 
		SequenceID = 0,
		T.RepID,
		H.FirstName,
		H.LastName,
		R.RepCode,
		YearTreatment = YEAR(MAX(T.RepTreatmentDate)),
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		CumBrut = SUM(T2.Brut),
		CumBrutDIR = SUM(T2.BrutDIR),
		T.Brut24,
		T.Brut24DIR,
		T.Retraits,
		T.RetraitsDIR,
		CumRetraits = SUM(T2.Retraits),
		CumRetraitsDIR = SUM(T2.RetraitsDIR),
		T.Retraits24,
		T.Retraits24DIR,
		T.Net,
		T.NetDIR,
		CumNet = SUM(T2.Net),
		CumNetDIR = SUM(T2.NetDIR),
		T.Net24,
		T.Net24DIR,
		Cons = 
			CASE
				WHEN T.Brut24 <= 0 THEN 0
			ELSE ROUND((T.Net24  * 100.00) / T.Brut24,2)
			END,
		ConsDIR = 
			CASE
				WHEN T.Brut24DIR <= 0 THEN 0
			ELSE ROUND((T.Net24DIR * 100.00) / T.Brut24DIR,2)
			END
	INTO #Finale
	FROM #Temp T
	JOIN #Temp T2 On T.RepID = T2.RepID AND T.RepTreatmentDate >= T2.RepTreatmentDate
	JOIN dbo.Mo_Human H ON H.HumanID = T.RepID
	JOIN Un_Rep R ON R.RepID = T.RepID
	WHERE T.RepTreatmentID = @ReptreatmentID
	GROUP BY 
		T.RepID,
		T.RepTreatmentID,
		T.RepTreatmentDate,
		T.Brut,
		T.BrutDIR,
		T.Retraits,
		T.RetraitsDIR,
		T.Net,
		T.NetDIR,
		T.Net24,
		T.Net24DIR,
		T.Retraits24,
		T.Retraits24DIR,
		T.Brut24,
		T.Brut24DIR,
		H.FirstName,
		H.LastName,
		R.RepCode

	/*SELECT
		SequenceID = 1,
		RepID = 0,
		LastName = 'Grands totaux',
		FirstName = ' ',
		RepCode = ' ',
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut = SUM(Brut),
		BrutDIR = SUM(BrutDIR),
		CumBrut = SUM(CumBrut),
		CumBrutDIR = SUM(CumBrutDIR),
		Brut24 = SUM(Brut24),
		Brut24DIR = SUM(Brut24DIR),
		Retraits = SUM(Retraits),
		RetraitsDIR = SUM(RetraitsDIR),
		CumRetraits = SUM(CumRetraits),
		CumRetraitsDIR = SUM(CumRetraitsDIR),
		Retraits24 = SUM(Retraits24),
		Retraits24DIR = SUM(Retraits24DIR),
		Net = SUM(Net),
		NetDIR = SUM(NetDIR),
		CumNet = SUM(CumNet),
		CumNetDIR = SUM(CumNetDIR),
		Net24 = SUM(Net24),
		Net24DIR = SUM(Net24DIR),
		Cons = 
			CASE 
				WHEN SUM(Brut24) = 0 THEN 0
			ELSE ROUND((SUM(Net24)*100) / SUM(Brut24),2) 
			END,
		ConsDIR =
			CASE
				WHEN SUM(Brut24DIR) = 0 THEN 0
			ELSE ROUND((SUM(Net24DIR)*100) / SUM(Brut24DIR),2)
			END
	INTO #FinaleTotal
	FROM #Finale
	GROUP BY
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate*/

	SELECT
		SequenceID,
		RepID,
		RepName = FirstName+' '+LastName,
		FirstName,
		LastName,
		RepCode,
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut,
		BrutDIR,
		CumBrut,
		CumBrutDIR,
		Brut24,
		Brut24DIR,
		Retraits,
		RetraitsDIR,
		CumRetraits,
		CumRetraitsDIR,
		Retraits24,
		Retraits24DIR,
		Net,
		NetDIR,
		CumNet,
		CumNetDIR,
		Net24,
		Net24DIR,
		Cons,
		ConsDIR
	FROM #Finale
	/*---------
	UNION ALL
	---------
	SELECT
		SequenceID,
		RepID,
		RepName = FirstName+' '+LastName,
		FirstName,
		LastName,
		RepCode,
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate,
		Brut,
		BrutDIR,
		CumBrut,
		CumBrutDIR,
		Brut24,
		Brut24DIR,
		Retraits,
		RetraitsDIR,
		CumRetraits,
		CumRetraitsDIR,
		Retraits24,
		Retraits24DIR,
		Net,
		NetDIR,
		CumNet,
		CumNetDIR,
		Net24,
		Net24DIR,
		Cons,
		ConsDIR
	FROM #FinaleTotal
	ORDER BY 
		SequenceID,
		LastName,
		FirstName,
		RepID,
		RepTreatmentDate,
		RepTreatmentID*/

	DROP TABLE #Temp
	DROP TABLE #Finale
	--DROP TABLE #FinaleTotal
	DROP TABLE #NewSales
	DROP TABLE #Terminated
	DROP TABLE #NewSalesDIR
	DROP TABLE #TerminatedDIR
*/
END
GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GU_RP_VentesExcelRepConserv_Old] TO [Rapport]
    AS [dbo];

