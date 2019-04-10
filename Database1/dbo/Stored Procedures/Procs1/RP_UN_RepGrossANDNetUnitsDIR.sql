/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepGrossANDNetUnitsDIR
Description         :	Rapport des units brutes et nettes vendus dans une priode par directeurs
Valeurs de retours  :	Dataset 
Note                :	ADX0001285	BR	2006-12-08	Bruno Lapointe		Optimisation.
						ADX0002398	BR	2007-04-20	Bruno Lapointe		Bogue de tri.
						2008-07-31 Patrick Robitaille		Utiliser le champ bReduitTauxConservationRep de la table
															Un_UnitReductionReason au lieu d'une liste d'IDs
						2008-11-18 Patrick Robitaille		Intégrer le calcul des rétentions sur le nb. d'unités brutes
						2008-12-22 Patrick Robitaille		Utiliser COALESCE pour tester le RepID au lieu d'un OR.
						2008-01-14 Patrick Robitaille		Correction d'un bug qui faisait en sorte qu'on avait un écart entre la version Rep
															et directeur au niveau des différents nombres d'unités dans les colonnes.
						2009-01-30 Patrick Robitaille		Correction sur le calcul du Cumulatif brut sur 24 mois et du calcul
															des résiliations d'unités.  Si une partie ou toutes les unités résiliées
															ont été réutilisées, le nb d'unités résiliées est diminué du nb d'unités réutilisées.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepGrossANDNetUnitsDIR] (
	@ConnectID INTEGER,
	@RepTreatmentID INTEGER,
	@RepID INTEGER )
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@RepTreatmentDate DATETIME,
		@LastRepTreatmentDate DATETIME,
		@LastRepTreatmentDateCum DATETIME,
		@TreatmentYear INTEGER

	SET @dtBegin = GETDATE()

	SELECT
		@RepTreatmentDate = RepTreatmentDate,
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
			AND R.RepTreatmentDate <= @RepTreatmentDate
		GROUP BY 
			R.RepTreatmentID,
			R.RepTreatmentDate

	SELECT @LastRepTreatmentDate = MAX(RepTreatmentDate)
	FROM Un_RepTreatment 
	WHERE RepTreatmentID < @ReptreatmentID

	SET @LastRepTreatmentDateCum = 0

	SELECT @LastRepTreatmentDateCum = MAX(T2.RepTreatmentDate)
	FROM Un_RepTreatment T 
	JOIN Un_RepTreatment T2 ON (YEAR(T2.RepTreatmentDate) < YEAR(T.RepTreatmentDate))
	WHERE T.RepTreatmentID = @ReptreatmentID

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
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
			JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
			JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
	      JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
			GROUP BY
				U.UnitID,
				U.RepID,
				U.UnitQty
		) M 
		JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
		JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
		GROUP BY
			M.UnitID, 
			M.UnitQty
		HAVING @RepID = 0 OR @RepID = MAX(RBH.BossID)

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
		JOIN @tMaxPctBoss M ON M.UnitID = U.UnitID
		WHERE (U.RepID = @RepID OR @RepID = 0 OR @RepID = M.BossID) --COALESCE(@RepID, U.RepID)
			  AND U.RepID IS NOT NULL
			  AND U.dtFirstDeposit IS NOT NULL

	--Unitees brutes REP
	SELECT
		MB.BossID, 
		U.RepID,
		RepTreatmentID = @RepTreatmentID,
		UnitQty =		SUM(
							CASE
								WHEN F.FirstDepositDate > @LastRepTreatmentDate THEN
									CASE
										WHEN NbUnitesAjoutees > 0 THEN
											NbUnitesAjoutees
										ELSE 
											U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(fUnitQtyUse, 0)
									END
							ELSE 0
							END), -- Unites brutes
		UnitQtyCum =	SUM(
							CASE 
								WHEN F.FirstDepositDate > @LastRepTreatmentDateCum THEN
									CASE
										WHEN NbUnitesAjoutees > 0 THEN
											NbUnitesAjoutees
										ELSE
											U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(fUnitQtyUse, 0)
									END
								ELSE 0
							END),
		UnitQty24 =		SUM(
							CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
								ELSE
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(fUnitQtyUse, 0)
							END) -- Unites brutes sur 24 mois
	INTO #NewSales   
	FROM @tFirstDeposit F 
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	JOIN @tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN (
        SELECT 
			U1.UnitID,
			U1.UnitQty - SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
			fUnitQtyUse = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN @tFirstDeposit FD ON FD.UnitID = U1.UnitID,
		@tYearRepTreatment T
		WHERE O.OperTypeID = 'TFR'
		  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
		  AND (FD.FirstDepositDate BETWEEN DATEADD(DAY, -6, T.RepTreatmentDate) AND T.RepTreatmentDate)
		GROUP BY
			U1.UnitID,
			U1.UnitQty
		) AS S1 ON (S1.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	WHERE
		( F.FirstDepositDate > DATEADD(MONTH,-24,@RepTreatmentDate)
		AND F.FirstDepositDate <= @RepTreatmentDate)
	GROUP BY
		MB.BossID, 
		U.RepID

	-- Table temporaire contenant le total des ré-utilisation de frais disponibles par résiliation (UnitReduction)
	DECLARE @tReUsedUnits TABLE (
		UnitReductionID INTEGER PRIMARY KEY,
		NbReUsedUnits MONEY NOT NULL )

	INSERT INTO @tReUsedUnits
		SELECT 
			UnitReductionID,
			NbReUsedUnits = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		GROUP BY
			UnitReductionID
		ORDER BY UnitReductionID

	-- Retraits frais non couverts 
	SELECT
		MB.BossID, 
		U.RepID,
		RepTreatmentID = @RepTreatmentID, 
		UnitQty =
			SUM(
				CASE 
					WHEN UR.ReductionDate > @LastRepTreatmentDate THEN 
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END),
		UnitQtyCum =
			SUM(
				CASE 
					WHEN UR.ReductionDate > @LastRepTreatmentDateCum THEN 
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END),
		UnitQty24 = 
			SUM(
				CASE
					WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
						UR.UnitQty - RU.NbReUsedUnits
				ELSE UR.UnitQty
				END)
	INTO #Terminated
	FROM Un_UnitReduction UR 
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN @tMaxPctBoss MB ON U.UnitID = MB.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
		AND UR.ReductionDate > DATEADD(MONTH,-24,@RepTreatmentDate)
		AND UR.ReductionDate <= @RepTreatmentDate
	    AND (URR.bReduitTauxConservationRep = 1
			OR bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY
		MB.BossID, 
		U.RepID

	--Unitees brutes DIR
	SELECT 
		BossID,
		RepTreatmentID,
		UnitQty = SUM(UnitQty),
		UnitQtyCum = SUM(UnitQtyCum),
		UnitQty24 = SUM(UnitQty24)
	INTO #NewSalesDIR
	FROM #NewSales NS
	GROUP BY
		BossID,
		RepTreatmentID

	-- Retraits frais non couverts DIR
	SELECT 
		BossID,
		RepTreatmentID,
		UnitQty = SUM(UnitQty),
		UnitQtyCum = SUM(UnitQtyCum),
		UnitQty24 = SUM(UnitQty24)
	INTO #TerminatedDIR
	FROM #Terminated
	GROUP BY
		BossID,
		RepTreatmentID

	SELECT
		V.RepID,
		V.BossID,
		RepName = H.LastName + ',' + H.FirstName,
		V.RepTreatmentID,
		U.RepTreatmentDate,
		Brut = SUM(V.Brut),
		Retraits = SUM(V.Retraits),
		Net = SUM(V.Brut) - SUM(V.Retraits),
		BrutDIR = SUM(V.BrutDIR),
		RetraitsDIR = SUM(V.RetraitsDIR),
		NetDIR = SUM(V.BrutDIR) - SUM(V.RetraitsDIR),
		CumBrut = SUM(V.BrutCum),
		CumRetraits = SUM(V.RetraitsCum),
		CumNet = SUM(V.BrutCum) - SUM(V.RetraitsCum),
		CumBrutDIR = SUM(V.BrutDIRCum),
		CumRetraitsDIR = SUM(V.RetraitsDIRCum),
		CumNetDIR = SUM(V.BrutDIRCum) - SUM(V.RetraitsDIRCum),
		Brut24 = SUM(V.Brut24),
		Retraits24 = SUM(V.Retraits24),
		Net24 = SUM(V.Brut24) - SUM(V.Retraits24), 
		Brut24DIR = SUM(V.Brut24DIR),
		Retraits24DIR = SUM(V.Retraits24DIR),
		Net24DIR = SUM(V.Brut24DIR) - SUM(V.Retraits24DIR),
		Cons =
			CASE  
				WHEN SUM(V.Brut24) <= 0 THEN 0
			ELSE ROUND((SUM(V.Brut24) - SUM(V.Retraits24)) / SUM(V.Brut24) * 100,2)
			END,
		ConsDIR =
			CASE  
				WHEN SUM(V.Brut24DIR) <= 0 THEN 0
			ELSE ROUND((SUM(V.Brut24DIR) - SUM(V.Retraits24DIR)) / SUM(V.Brut24DIR) * 100,2)
			END
	FROM (
		SELECT
			RepID,
			BossID,
			RepTreatmentID,
			Brut = UnitQty,
			Retraits = 0,
			BrutDIR = 0,
			RetraitsDIR = 0,
			BrutCum = UnitQtyCum,
			RetraitsCum = 0,
			BrutDIRCum = 0,
			RetraitsDIRCum = 0,
			Brut24 = UnitQty24,
			Retraits24 = 0,
			Brut24DIR = 0,
			Retraits24DIR = 0
		FROM #NewSales
		WHERE RepTreatmentID = @RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT
			RepID,
			BossID,
			RepTreatmentID,
			Brut = 0,
			Retraits = UnitQty,
			BrutDIR = 0,
			RetraitsDIR = 0,
			BrutCum = 0,
			RetraitsCum = UnitQtyCum,
			BrutDIRCum = 0,
			RetraitsDIRCum = 0,
			Brut24 = 0,
			Retraits24 = UnitQty24,
			Brut24DIR = 0,
			Retraits24DIR = 0
		FROM #Terminated 
		WHERE RepTreatmentID = @RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT
			RepID = BossID,
			BossID,
			RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			BrutDIR = UnitQty,
			RetraitsDIR = 0,
			BrutCum = 0,
			RetraitsCum = 0,
			BrutDIRCum = UnitQtyCum,
			RetraitsDIRCum = 0,
			Brut24 = 0,
			Retraits24 = 0,
			Brut24DIR = UnitQty24,
			Retraits24DIR = 0
		FROM #NewSalesDIR
		WHERE RepTreatmentID = @RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT
			RepID = BossID,
			BossID,
			RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			BrutDIR = 0,
			RetraitsDIR = UnitQty,
			BrutCum = 0,
			RetraitsCum = 0,
			BrutDIRCum = 0,
			RetraitsDIRCum = UnitQtyCum,
			Brut24 = 0,
			Retraits24 = 0,
			Brut24DIR = 0,
			Retraits24DIR = UnitQty24
		FROM #TerminatedDIR 
		WHERE RepTreatmentID = @RepTreatmentID
       ) V
	JOIN Un_RepTreatment U ON U.RepTreatmentID = V.RepTreatmentID
	JOIN dbo.Mo_Human H ON V.RepID = H.HumanID
	WHERE V.RepID IS NOT NULL
	GROUP BY 
		V.RepID,
		V.BossID,
		H.LastName,
		H.FirstName,
		V.RepTreatmentID,
		U.RepTreatmentDate
	ORDER BY
		V.BossID,
		H.LastName,
		H.FirstName,
		V.RepID,
		V.RepTreatmentID,
		U.RepTreatmentDate

	DROP TABLE #NewSales   
	DROP TABLE #Terminated
	DROP TABLE #NewSalesDIR
	DROP TABLE #TerminatedDIR

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'exécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de lusager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps dexcution de la procdure
				dtStart, -- Date et heure du dbut de lexcution.
				dtEnd, -- Date et heure de la fin de lexcution.
				vcDescription, -- Description de lexcution (en texte)
				vcStoredProcedure, -- Nom de la procdure stocke
				vcExecutionString ) -- Ligne dexcution (inclus les paramtres)
			SELECT
				@ConnectID,
				2,
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Units brutes et nettes',
				'RP_UN_RepGrossANDNetUnitsDIR',
				'EXECUTE RP_UN_RepGrossANDNetUnitsDIR @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @ReptreatmentID = '+CAST(@ReptreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


