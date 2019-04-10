/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepGrossANDNetUnits
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants et par directeurs
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2006-11-06	Bruno Lapointe		Optimisation.
						ADX0001285	BR	2006-12-07	Bruno Lapointe		Optimisation.
						2008-07-31 Patrick Robitaille		Utiliser le champ bReduitTauxConservationRep de la table
															Un_UnitReductionReason au lieu d'une liste d'IDs
						2008-11-18 Patrick Robitaille		Intégrer le calcul des rétentions sur le nb. d'unités brutes
						2008-12-22 Patrick Robitaille		Utiliser une table temporaire pour les rétentions de clients
															Utiliser COALESCE pour tester le RepID au lieu d'un OR.
						2009-01-14 Patrick Robitaille		Correction d'un bug qui faisait en sorte qu'on avait un écart entre la version Rep
															et directeur au niveau des différents nombres d'unités dans les colonnes.
						2009-01-30 Patrick Robitaille		Correction sur le calcul du Cumulatif brut sur 24 mois et du calcul
															des résiliations d'unités.  Si une partie ou toutes les unités résiliées
															ont été réutilisées, le nb d'unités résiliées est diminué du nb d'unités réutilisées.
						2012-01-23	Donald Huppé			Mettre un Return au début car cette sp est utilisé seulement par le rapport via Delphi.
															Et on ne veut plus qu'il soit utilisé.
															
exec RP_UN_RepGrossANDNetUnits 1,500,1
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepGrossANDNetUnits] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@ReptreatmentID INTEGER, -- ID du traitement de commissions
	@RepID INTEGER) -- ID du représentant
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER

	return

	SET @dtBegin = GETDATE()

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
		HAVING @RepID = 0 OR MAX(RBH.BossID) = @RepID

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
		WHERE (U.RepID = @RepID OR @RepID = 0 OR M.BossID IS NOT NULL)--COALESCE(@RepID, U.RepID)
		    AND U.RepID IS NOT NULL
			AND U.dtFirstDeposit IS NOT NULL

	-- Unités disponibles transférées (rétention de client)
	DECLARE @tTransferedUnits TABLE (
		UnitID INTEGER PRIMARY KEY,
		NbUnitesAjoutees MONEY NOT NULL,
		RepTreatmentID INTEGER NOT NULL,
		fUnitQtyUse MONEY NOT NULL )

	INSERT INTO @tTransferedUnits
		SELECT 
			U1.UnitID,
			U1.UnitQty - SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
			RT.RepTreatmentID,
			fUnitQtyUse = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN @tFirstDeposit FD ON FD.UnitID = U1.UnitID,
		@tYearRepTreatment RT 
		WHERE O.OperTypeID = 'TFR'
		  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
		  AND (FD.FirstDepositDate BETWEEN DATEADD(DAY, -6, RT.RepTreatmentDate) AND RT.RepTreatmentDate) 
		GROUP BY
			U1.UnitID,
			U1.UnitQty,
			RepTreatmentID

	--Unites brutes REP
	SELECT 
		U.RepID,
		T.RepTreatmentID,
		UnitQty = SUM(
					CASE
						WHEN F.FirstDepositDate > T.LastRepTreatmentDate THEN
							CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
								ELSE 
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END), -- Unites brutes
		UnitQty24 = SUM(
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) -- Unites brutes sur 24 mois
	INTO #NewSales
	FROM @tFirstDeposit F
	JOIN @tYearRepTreatment T ON (F.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (F.FirstDepositDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN @tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	WHERE (U.RepID = @RepID) OR (@RepID = 0)--COALESCE(@RepID, U.RepID)
	GROUP BY 
		U.RepID,
		T.RepTreatmentID 

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

	-- Retraits frais non couverts REP
	SELECT 
		U.RepID,
		T.RepTreatmentID,
		UnitQty = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN 
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
	JOIN @tYearRepTreatment T ON (UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID	
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
		AND (U.RepID = @RepID OR @RepID = 0)--COALESCE(@RepID, U.RepID)
	    AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY 
		U.RepID,
		T.RepTreatmentID

	--Unites brutes DIR
	SELECT 
		M.BossID,
		T.RepTreatmentID,
		UnitQty =	SUM(
						CASE
							WHEN F.FirstDepositDate > T.LastRepTreatmentDate THEN
								CASE
									WHEN NbUnitesAjoutees > 0 THEN
										NbUnitesAjoutees
									ELSE 
										U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
									END
								ELSE 0
						END), -- Unites brutes
		UnitQty24 = SUM(
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) -- Unites brutes sur 24 mois
	INTO #NewSalesDIR
	FROM @tMaxPctBoss M
	JOIN @tFirstDeposit F ON M.UnitID = F.UnitID
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN @tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID,
    @tYearRepTreatment T 
    WHERE (F.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (F.FirstDepositDate <= T.RepTreatmentDate)
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
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN 
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
	INTO #TerminatedDir
	FROM @tMaxPctBoss MP
	JOIN Un_UnitReduction UR ON MP.UnitID = UR.UnitID
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN @tYearRepTreatment T ON (UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
	  AND (URR.bReduitTauxConservationRep = 1
			OR bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
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
			ELSE ROUND((T.Net24 / T.Brut24) * 100, 2)
			END,
		ConsDIR = 
			CASE
				WHEN T.Brut24DIR <= 0 THEN 0
			ELSE ROUND((T.Net24DIR / T.Brut24DIR) * 100, 2)
			END
	INTO #Finale
	FROM #Temp T
	JOIN #Temp T2 On T.RepID = T2.RepID AND T.RepTreatmentDate >= T2.RepTreatmentDate
	JOIN dbo.Mo_Human H ON H.HumanID = T.RepID
	JOIN Un_Rep R ON R.RepID = T.RepID
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

	SELECT
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
			ELSE ROUND((SUM(Net24) / SUM(Brut24) * 100), 2) 
			END,
		ConsDIR =
			CASE
				WHEN SUM(Brut24DIR) = 0 THEN 0
			ELSE ROUND((SUM(Net24DIR) / SUM(Brut24DIR) * 100), 2)
			END
	INTO #FinaleTotal
	FROM #Finale
	GROUP BY
		YearTreatment,
		RepTreatmentID,
		RepTreatmentDate

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
	---------
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
		RepTreatmentID

	DROP TABLE #Temp
	DROP TABLE #Finale
	DROP TABLE #FinaleTotal
	DROP TABLE #NewSales
	DROP TABLE #Terminated
	DROP TABLE #NewSalesDIR
	DROP TABLE #TerminatedDIR

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'exécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
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
				DATEDIFF(MILLISECOND, @dtBegin, @dtEnd)/1000,
				@dtBegin,
				@dtEnd,
				'Unités brutes et nettes',
				'RP_UN_RepGrossANDNetUnits',
				'EXECUTE RP_UN_RepGrossANDNetUnits @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @ReptreatmentID = '+CAST(@ReptreatmentID AS VARCHAR)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END


