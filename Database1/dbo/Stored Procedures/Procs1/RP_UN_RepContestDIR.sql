/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	RP_UN_RepContestDIR
Description         :	Procédure stockée du rapport : Concours des directeurs
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
										2008-11-18  Patrick Robitaille	Intégrer le calcul des rétentions sur le nb. d'unités brutes
										2009-01-30	Patrick Robitaille	Correction sur le calcul du brut et du calcul des résiliations d'unités.  
																		Si une partie ou toutes les unités résiliées ont été réutilisées, le nb. 
																		d'unités résiliées est diminué du nb d'unités réutilisées.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepContestDIR] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepContestCfgID INTEGER ) -- ID Unique du concours
AS
BEGIN
	DECLARE 
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@StartDate DATETIME,
		@EndDate DATETIME

	SET @dtBegin = GETDATE()

	SELECT
		@StartDate = StartDate,
		@EndDate = EndDate
	FROM Un_RepContestCfg
	WHERE RepContestCfgID = @RepContestCfgID;

	SELECT
		U.UnitID,
		U.RepID,
		UnitQty =	SUM(CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(S1.fUnitQtyUse, 0)
						END
						)
	INTO #NewSales
	FROM dbo.Un_Unit U
		LEFT JOIN (
			SELECT 
				U1.UnitID,
				U1.UnitQty - SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
				fUnitQtyUse = SUM(A.fUnitQtyUse)
			FROM Un_AvailableFeeUse A
			JOIN Un_Oper O ON O.OperID = A.OperID
			JOIN Un_Cotisation C ON C.OperID = O.OperID
			JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
			WHERE O.OperTypeID = 'TFR'
			  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
			GROUP BY
				U1.UnitID,
				U1.UnitQty
			) AS S1 ON (S1.UnitID = U.UnitID)
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			WHERE UR.ReductionDate >= @StartDate
			GROUP BY UR.UnitID
			) UR ON UR.UnitID = U.UnitID

	WHERE U.dtFirstDeposit >= @StartDate 
		AND( @EndDate IS NULL
			OR U.dtFirstDeposit <= @EndDate
			)
	GROUP BY
		U.UnitID,
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

	SELECT
		U.UnitID,
		U.RepID,
		UnitQty =	 
			SUM(
				CASE
					WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
						UR.UnitQty - RU.NbReUsedUnits
				ELSE UR.UnitQty
				END)
	INTO #Terminated
	FROM Un_UnitReduction UR
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
		AND UR.ReductionDate >= @StartDate 
		AND( @EndDate IS NULL
			OR UR.ReductionDate <= @EndDate
			)
		AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY
		U.UnitID,
		U.RepID

	-- Création de la table temporaire des facteurs de multiplication pour chacun
	-- des groupes d'unités pour chacun des représentants selon s'il sont des
	-- recrus ou pas à la date de chaque premier dépôt.
	SELECT
		U.UnitID,
		R.RepID,
		UnitQty = 
			SUM(
				CASE
					WHEN dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit) = 1 THEN
						ROUND((ISNULL(N.UnitQty,0) - ISNULL(T.UnitQty,0)) * ((C.RecruitUnitMultFactor/100) -1),4)
				ELSE ROUND((ISNULL(N.UnitQty,0) - ISNULL(T.UnitQty,0)) * ((C.NonRecruitUnitMultFactor/100) -1),4)
				END )
	INTO #MultFactor
	FROM dbo.Un_Unit U
	LEFT JOIN #NewSales N ON U.RepID = N.RepID AND U.UnitID = N.UnitID
	LEFT JOIN #Terminated T ON U.RepID = T.RepID AND U.UnitID = T.UnitID
	JOIN Un_RepContestUnitMultFactorCfg C ON C.RepContestCfgID = @RepContestCfgID AND (C.StartDate <= U.dtFirstDeposit) AND (C.EndDate IS NULL OR C.EndDate >= U.dtFirstDeposit)
	JOIN Un_Rep R ON R.RepID = U.RepID
	WHERE U.dtFirstDeposit >= @StartDate 
		AND (@EndDate IS NULL OR U.dtFirstDeposit <= @EndDate)
	GROUP BY
		U.UnitID,
		R.RepID

	SELECT
		M.UnitID,
		BossID = MAX(RBH.BossID)
	INTO #MaxPctBoss
	FROM (
		SELECT
			U.UnitID,
			U.RepID,
			RepBossPct = MAX(RBH.RepBossPct)
		FROM dbo.Un_Unit U
		JOIN Un_RepBossHist RBH ON (RBH.RepID = U.RepID) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
		JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
		JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
		JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
		GROUP BY
			U.UnitID,
			U.RepID
		) M
	JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
	JOIN Un_RepBossHist RBH ON (RBH.RepID = M.RepID) AND (RBH.RepBossPct = M.RepBossPct) AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
	GROUP BY M.UnitID;

	SELECT
		V.RepID,
		V.LastName,
		V.FirstName,
		V.Agency,
		V.Brut,
		V.Terminated,
		V.Net,
		V.UnitOfMultFactor,
		V.NetAndUnitOfMultFactor,
		ContestPriceName = ISNULL(P.ContestPriceName,''),
		SectionColor = ISNULL(P.SectionColor, 16777215)
	FROM (
		SELECT
			RepID = M.BossID,
			B.LastName,
			B.FirstName,
			Agency = B.FirstName + ' ' + B.LastName,
			Brut = ISNULL(SUM(N.UnitQty),0),
			Terminated = ISNULL(SUM(T.UnitQty),0),
			Net = ISNULL(SUM(N.UnitQty),0) - ISNULL(SUM(T.UnitQty),0),
			UnitOfMultFactor = ISNULL(SUM(F.UnitQty),0),
			NetAndUnitOfMultFactor = ISNULL(SUM(N.UnitQty),0) - ISNULL(SUM(T.UnitQty),0) + ISNULL(SUM(F.UnitQty),0)
		FROM dbo.Un_Unit U
		JOIN Un_Rep R ON U.RepID = R.RepID
		JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
		JOIN #MaxPctBoss M ON U.UnitID = M.UnitID
		JOIN dbo.Mo_Human B ON B.HumanID = M.BossID
		LEFT JOIN #NewSales N ON R.RepID = N.RepID AND U.UnitID = N.UnitID
		LEFT JOIN #Terminated T ON R.RepID = T.RepID AND U.UnitID = T.UnitID
		LEFT JOIN #MultFactor F ON R.RepID = F.RepID AND U.UnitID = F.UnitID
		WHERE N.UnitID IS NOT NULL 
			OR T.UnitID IS NOT NULL
		GROUP BY
			M.BossID,
			B.FirstName,
			B.LastName
		) V
	LEFT JOIN (
		SELECT
			P.RepContestPriceCfgID,
			P.ContestPriceName,
			P.MinUnitQty,
			P.SectionColor,
			MaxUnitQty = MIN(P2.MinUnitQty)
		FROM Un_RepContestPriceCfg P
		LEFT JOIN Un_RepContestPriceCfg P2 ON (P2.MinUnitQty > P.MinUnitQty) AND P2.RepContestCfgID = @RepContestCfgID
		WHERE P.RepContestCfgID = @RepContestCfgID
		GROUP BY
			P.RepContestPriceCfgID,
			P.ContestPriceName, 
			P.MinUnitQty, 
			P.SectionColor
		) P ON (P.MinUnitQty <= V.NetAndUnitOfMultFactor) AND (P.MaxUnitQty IS NULL OR P.MaxUnitQty > V.NetAndUnitOfMultFactor)
	ORDER BY
		V.NetAndUnitOfMultFactor DESC

	DROP TABLE #NewSales
	DROP TABLE #Terminated
	DROP TABLE #MultFactor
	DROP TABLE #MaxPctBoss

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
		-- Insère une trace de l'ewxécution si la durée de celle-ci a dépassé le temps minimum défini dans Un_Def.siTraceReport.
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
				'Concours des directeurs',
				'RP_UN_RepContestDIR',
				'EXECUTE RP_UN_RepContestDIR @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepContestCfgID = '+CAST(@RepContestCfgID AS VARCHAR)
END


