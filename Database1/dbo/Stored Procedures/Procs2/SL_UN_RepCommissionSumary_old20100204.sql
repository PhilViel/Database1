/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepCommissionSumary 
Description         :	Sort le rapport de sommaire des commissions pour qu'on puisse l'insérer dans la table temporaire.
Valeurs de retours  :	
	Dataset :
		RepTreatmentID		INTEGER		ID du traitement de commissions
		RepID			INTEGER		ID du représentant
		TreatmentYear		INTEGER		Année du traitement
		RepCode			VARCHAR(75)	Code du représentant									RepName			VARCHAR(87)	Représentant										RepTreatmentDate	INTEGER		Date du traitement									REPPeriodUnit		MONEY		Nombre d'unités vendus dans la période en tant que représentant
		CumREPPeriodUnit	MONEY		Somme des unités vendus en tant que représentant depuis le début de l'année jusqu'au traitement
									DIRPeriodUnit		MONEY			Nombre d'unités vendus dans la période en tant que directeur
									CumDIRPeriodUnit	MONEY			Somme des unités vendus en tant que directeur depuis le début de l'année jusqu'au traitement
									REPConsPct			MONEY			Pourcentage de conservation en tant que représentant à la date du traitement de commissions
									DIRConsPct			MONEY			Pourcentage de conservation en tant que directeur à la date du traitement de commissions
									ConsPct				MONEY			Pourcentage de conservation à la date du traitement de commissions
									BusinessBonus		MONEY			Bonis d'affaires versés dans ce traitement
									CoveredAdvance		MONEY			Avances couvertes dans ce traitement
									NewAdvance			MONEY			Avance versés dans ce traitement
									CommAndBonus		MONEY			Bonis d'affaires et commissions de service versés dans ce traitement
									Adjustment			MONEY			Ajustements pour ce traitement
									ChqBrut				MONEY			Montant brutes du chèque fait au représentant dans ce traitement (Avances, commissions de service et bonis d'affaires versés dans ce traitement + ajustement de ce traitement)
									CumChqBrut			MONEY			Montant brutes du chèque fait au représentant depuis le début l'année du traitement jusqu'à la date du traitement.
									Retenu				MONEY			Retenus pour ce traitement
									ChqNet				MONEY			Montant nettes du chèque fait au représentant (Chèque brut - retenus)
									Mois					MONEY			Dépense de commissions pour ce traitement fait pour ce représentant
									CumMois				MONEY			Dépense de commissions fait pour ce représentant depuis le début l'année du traitement jusqu'à la date du traitement.
									Advance				MONEY			Avance non-couvertes
									FuturCom				MONEY			Dépense de commissions à venir (commissions de service à venir et avance à couvrir)
									CommPct				MONEY			Pourcentage de commissions à ce traitement
Note                :	ADX0000696	IA	2005-09-06	Bruno Lapointe		Création
						ADX0001205	UP	2007-07-19	Bruno Lapointe		Ne pas tenir compte des transactions BEC
						2008-04-29	Pierre-Luc Simard					Ne pas tenir compte des transferts en régime Univeristas dans les réductions d'unités lors du calcul des taux de conservation	
						2008-07-31	Patrick Robitaille					Utiliser le champ bReduitTauxConservationRep de la table
																		Un_UnitReductionReason au lieu d'une liste d'IDs						
						2009-01-30	Patrick Robitaille					Correction sur le calcul du Cumulatif brut sur 24 mois et du calcul
																		des résiliations d'unités.  Si une partie ou toutes les unités résiliées
																		ont été réutilisées, le nb d'unités résiliées est diminué du nb d'unités réutilisées.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepCommissionSumary_old20100204] (
	@RepTreatmentID INTEGER ) -- ID du traitement de commissions
AS 
BEGIN
	DECLARE 
		@dtRepTreatmentDate DATETIME,
		@dtLastRepTreatmentDate DATETIME,
		@iYearSumary INTEGER

	-- Va chercher la date de traitement et l'année de cette date
	SELECT
		@dtRepTreatmentDate = RepTreatmentDate, -- Date du traitement de commissions
		@iYearSumary = YEAR(RepTreatmentDate) -- Année du traitement de commissions
	FROM Un_RepTreatment 
	WHERE RepTreatmentID = @RepTreatmentID

	-- Table temporaire contenant tous les traitements précédents ce traitement de commissions de la même année et aussi lui-même
	SELECT
		R.RepTreatmentID, -- ID du traitement de commissions
		R.RepTreatmentDate, -- Date du traitement de commissions
		LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0)) -- Date du traitement précédent
	INTO #tbYearRepTreatment
	FROM Un_RepTreatment R
	LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
	WHERE	YEAR(R.RepTreatmentDate) = @iYearSumary 
		AND R.RepTreatmentDate <= @dtRepTreatmentDate
	GROUP BY
		R.RepTreatmentID,
		R.RepTreatmentDate

	-- Table temporaire contenant tous les traitements précédents ce traitement de commissions et aussi lui-même
	SELECT
		R.RepTreatmentID, -- ID du traitement de commissions
		R.RepTreatmentDate, -- Date du traitement de commissions
		LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0)) -- Date du traitement précédent
	INTO #tbRepTreatment
	FROM Un_RepTreatment R
	LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
	GROUP BY
		R.RepTreatmentID,
		R.RepTreatmentDate

	-- Table temporaire contenant le directeur de chaque groupe d'unités
	SELECT
		M.UnitID, -- ID du groupe d'unités
		BossID = MAX(RBH.BossID) -- ID du directeur 
	INTO #tbMaxPctBoss
	FROM (
		-- Va chercher le plus gros pourcentage qu'à un directeur pour chaq1ue groupe d'unités
		SELECT
			U.UnitID, -- ID du groupe d'unités
			U.UnitQty, -- Nombre d'unités
			U.RepID, -- ID du représentant
			RepBossPct = MAX(RBH.RepBossPct) -- Plus gros pourcentage parmis les directeurs
		FROM dbo.Un_Unit U
		JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR' -- Directeurs seulement
		JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
		JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate OR BRLH.EndDate IS NULL)
		JOIN Un_RepBusinessBonusCfg RBB ON (RBB.RepRoleID = RBH.RepRoleID) AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
		GROUP BY
			U.UnitID,
			U.RepID,
			U.UnitQty
		) M 
	JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
	JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
	GROUP BY M.UnitID

	-- Tables temporaire contenant la somme d'avances et la d'avance et commissions de service versées ou à verser par groupe d'unités,
	-- représentants (représentant et supérieur), niveau et pourcentage de commissions
	-- Avant UNION c'est pour les représentants
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		U.RepID, -- ID du représentant
		RL.RepLevelID, -- ID du niveau du représentant
		RepPct = 100.00, -- Pourcentage de commissions
		AdvanceByUnit = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances uniquement
					WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				),
		AdvAndComByUnit = -- Somme des avances et commissions de service versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances et de commissions de service uniquement
					WHEN RLB.RepLevelBracketTypeID IN ('ADV','COM') THEN RLB.AdvanceByUnit
				ELSE 0
				END
				)
	INTO #tbUnitRepAdv
	FROM dbo.Un_Unit U
	JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
	GROUP BY
		U.UnitID,
		U.RepID,
		RL.RepLevelID
	-----
	UNION
	-----
	-- Même chose pour les supérieurs
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		RepID = RBH.BossID, -- ID du représentant(supérieur)
		RL.RepLevelID, -- ID du niveau du représentant
		RepPct = RBH.RepBossPct, -- Pourcentage de commissions
		AdvanceByUnit = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances uniquement
					WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				),
		AdvAndComByUnit = -- Somme des avances et commissions de service versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances et de commissions de service uniquement
					WHEN RLB.RepLevelBracketTypeID IN ('ADV','COM') THEN RLB.AdvanceByUnit
				ELSE 0
				END
				)
	FROM dbo.Un_Unit U
	JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND (RL.RepRoleID <> 'REP')
	JOIN Un_RepLevelHist RLH ON RLH.RepID = RBH.BossID AND RL.RepLevelID = RLH.RepLevelID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
	GROUP BY
		U.UnitID,
		RBH.BossID,
		RL.RepLevelID,
		RBH.RepBossPct

	-- Table temporaire contenant la date du premier dépôt de chaque groupe d'unités
	SELECT 
		C.UnitID, -- ID du groupe d'unités
		FirstDepositDate = -- Date du premier dépôt
			CASE 
				WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
			ELSE MIN(O.OperDate) 
			END 
	INTO #tbFirstDeposit
	FROM #tbUnitRepAdv V
	JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
	JOIN Un_Cotisation C ON V.UnitID = C.UnitID
	JOIN Un_Oper O ON O.OperID = C.OperID
	WHERE O.OperTypeID NOT IN ('BEC') -- Exclus les remboursements intégraux.  Les commissions ne sont pas affectés par les variations de frais du à des remboursements intégraux
	GROUP BY C.UnitID

	-- Table temporaire contenant le traitement ou le groupe d'unités a été une nouvelle vente pour chaque groupe d'unités
	SELECT DISTINCT
		F.UnitID, -- ID du groupe d'unités
		Y.RepTreatmentID -- ID du traitement de commissions
	INTO #tbNewUnit
	FROM #tbFirstDeposit F 
	JOIN #tbRepTreatment Y ON  (F.FirstDepositDate > Y.LastRepTreatmentDate) AND (F.FirstDepositDate <= Y.RepTreatmentDate)

	SELECT DISTINCT
		U.UnitID, -- ID du groupe d'unités
		Y.RepTreatmentID -- ID du traitement de commissions
	INTO #tbRepUnitWithCommNotToPay
	FROM #tbYearRepTreatment Y
	JOIN Un_Oper O ON (O.OperDate <= Y.RepTreatmentDate)
	JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
	JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
	JOIN #tbUnitRepAdv A ON A.UnitID = U.UnitID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID AND OT.CommissionToPay = 0
	WHERE O.OperDate <= Y.RepTreatmentDate
		AND Ct.Fee > 0

	-- Retourne le nombre d'unités réduits après le traitement de commissions, pour chaque groupe d'unités et traitement de commissions
	-- de la table temporaire #tbRepTreatment
	SELECT 
		Y.RepTreatmentID, -- ID du traitement de commissions
		UR.UnitID, -- ID du groupe d'unités
		UnitQty = SUM(UR.UnitQty) -- Nombre d'unités réduit aprés le traitement
	INTO #tbUnitReductionNotApp
	FROM #tbRepTreatment Y
	JOIN Un_UnitReduction UR ON UR.ReductionDate > Y.RepTreatmentDate
	GROUP BY
		Y.RepTreatmentID,
		UR.UnitID

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
		JOIN #tbFirstDeposit FD ON FD.UnitID = U1.UnitID,
		#tbYearRepTreatment RT 
		WHERE O.OperTypeID = 'TFR'
		  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
		  AND (FD.FirstDepositDate BETWEEN DATEADD(DAY, -6, RT.RepTreatmentDate) AND RT.RepTreatmentDate) 
		GROUP BY
			U1.UnitID,
			U1.UnitQty,
			RepTreatmentID

	-- Table temporaire des nouvelles ventes de chaque représentant en tant que directeur ou représentant pour chaque traitement des
	-- 24 derniers mois. Cette table sert au calcul du pourcentage de conservation.
	SELECT
		R.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		REPUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que représentant dans ce traitement
			SUM(
				CASE R.RepRoleID 
					WHEN 'REP' THEN
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END
				ELSE 0
				END
				),
		DIRUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que directeur dans ce traitement 
			SUM(
				CASE R.RepRoleID 
					WHEN 'DIR' THEN
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END
				ELSE 0
				END
				)
	INTO #tbConservPctNewSales   
	FROM #tbYearRepTreatment Y
	JOIN #tbFirstDeposit F ON F.FirstDepositDate BETWEEN DATEADD(MONTH, -24, Y.RepTreatmentDate) AND Y.RepTreatmentDate
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN @tTransferedUnits TU ON (TU.UnitID = U.UnitID AND TU.RepTreatmentID = Y.RepTreatmentID)
	LEFT JOIN (
		-- Somme des unités réduits
		SELECT 
			UnitID, -- ID du groupe d'unités
			UnitQty = SUM(UnitQty)
		FROM Un_UnitReduction 
		GROUP BY UnitID
		) UR ON UR.UnitID = U.UnitID
	JOIN (
		-- Retourne pour chaque groupe d'unités les représentants et directeurs
		SELECT 
			UnitID, -- ID du groupe d'unités
			RepID, -- ID du représentant
			RepRoleID = 'REP' -- Rôle du représentant
		FROM dbo.Un_Unit 
		---------
		UNION ALL
		---------
		SELECT 
			U.UnitID, -- ID du groupe d'unités
			RepID = M.BossID, -- ID du représentant(directeur)
			RepRoleID = 'DIR' -- Rôle du représentant
		FROM dbo.Un_Unit U
		JOIN #tbMaxPctBoss M ON M.UnitID = U.UnitID
		) R ON U.UnitID = R.UnitID
	GROUP BY
		R.RepID,
		Y.RepTreatmentID

	-- Table temporaire des nouvelles ventes de chaque représentant en tant que directeur ou représentant pour chaque traitement de
	-- commissions de la même année que le courant. 
	SELECT
		R.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		REPUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que représentant dans ce traitement
			SUM(
				CASE R.RepRoleID 
					WHEN 'REP' THEN
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END
				ELSE 0
				END
				),
		DIRUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que directeur dans ce traitement 
			SUM(
				CASE R.RepRoleID 
					WHEN 'DIR' THEN
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END
				ELSE 0
				END
				)
	INTO #tbNewSales   
	FROM #tbYearRepTreatment Y
	JOIN #tbFirstDeposit F ON F.FirstDepositDate BETWEEN DATEADD(DAY, 1, Y.LastRepTreatmentDate) AND Y.RepTreatmentDate
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN @tTransferedUnits TU ON (TU.UnitID = U.UnitID AND TU.RepTreatmentID = Y.RepTreatmentID)
	LEFT JOIN (
		-- Somme des unités réduits
		SELECT 
			UnitID, -- ID du groupe d'unités
			UnitQty = SUM(UnitQty)
		FROM Un_UnitReduction 
		GROUP BY UnitID
		) UR ON UR.UnitID = U.UnitID
	JOIN (
		-- Retourne pour chaque groupe d'unités les représentants et directeurs
		SELECT 
			UnitID, -- ID du groupe d'unités
			RepID, -- ID du représentant
			RepRoleID = 'REP' -- Rôle du représentant
		FROM dbo.Un_Unit 
		---------
		UNION ALL
		---------
		SELECT 
			U.UnitID, -- ID du groupe d'unités
			RepID = M.BossID, -- ID du représentant(supérieur)
			RepRoleID = 'DIR' -- Rôle du représentant
		FROM dbo.Un_Unit U
		JOIN #tbMaxPctBoss M ON M.UnitID = U.UnitID
		) R ON U.UnitID = R.UnitID
	GROUP BY
		R.RepID,
		Y.RepTreatmentID

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

	-- Table temporaire des réductions d'unités de chaque représentant en tant que directeur ou représentant pour chaque traitement des
	-- 24 derniers mois. Cette table sert au calcul du pourcentage de conservation.
	SELECT
		R.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		REPUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que représentant dans ce traitement
			SUM(
				CASE R.RepRoleID 
					WHEN 'REP' THEN
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END
				),
		DIRUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que directeur dans ce traitement 
			SUM(
				CASE R.RepRoleID 
					WHEN 'DIR' THEN
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END
				)
	INTO #tbConservPctTerminated
	FROM #tbYearRepTreatment Y
	JOIN Un_UnitReduction UR ON UR.ReductionDate BETWEEN DATEADD(MONTH, -24, Y.RepTreatmentDate) AND Y.RepTreatmentDate
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	JOIN (
		-- Retourne pour chaque groupe d'unités les représentants et directeurs
		SELECT 
			UnitID, -- ID du groupe d'unités
			RepID, -- ID du représentant
			RepRoleID = 'REP' -- Rôle du représentant
		FROM dbo.Un_Unit 
		---------
		UNION ALL
		---------
		SELECT 
			U.UnitID, -- ID du groupe d'unités
			RepID = M.BossID, -- ID du représentant(supérieur)
			RepRoleID = 'DIR' -- Rôle du représentant
		FROM dbo.Un_Unit U
		JOIN #tbMaxPctBoss M ON M.UnitID = U.UnitID
		) R ON U.UnitID = R.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE UR.FeeSumByUnit < M.FeeByUnit -- Compte uniquement les réductions qui ont affectés les frais
		AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY
		R.RepID,
		Y.RepTreatmentID

	-- Table temporaire des réductions d'unités de chaque représentant en tant que directeur ou représentant pour chaque traitement de
	-- commissions de la même année que le courant.
	SELECT
		R.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		REPUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que représentant dans ce traitement
			SUM(
				CASE R.RepRoleID 
					WHEN 'REP' THEN
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END
				),
		DIRUnitQty = -- Nombre d'unités nouvellement vendus pour ce représentant en tant que directeur dans ce traitement 
			SUM(
				CASE R.RepRoleID 
					WHEN 'DIR' THEN
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END
				)
	INTO #tbTerminated
	FROM #tbYearRepTreatment Y
	JOIN Un_UnitReduction UR ON UR.ReductionDate BETWEEN DATEADD(DAY, 1, Y.LastRepTreatmentDate) AND Y.RepTreatmentDate
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	JOIN (
		-- Retourne pour chaque groupe d'unités les représentants et directeurs
		SELECT 
			UnitID, -- ID du groupe d'unités
			RepID, -- ID du représentant
			RepRoleID = 'REP' -- Rôle du représentant
		FROM dbo.Un_Unit 
		---------
		UNION ALL
		---------
		SELECT 
			U.UnitID, -- ID du groupe d'unités
			RepID = M.BossID, -- ID du représentant(supérieur)
			RepRoleID = 'DIR' -- Rôle du représentant
		FROM dbo.Un_Unit U
		JOIN #tbMaxPctBoss M ON M.UnitID = U.UnitID
		) R ON U.UnitID = R.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	WHERE UR.FeeSumByUnit < M.FeeByUnit -- Compte uniquement les réductions qui ont affectés les frais
		AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY
		R.RepID,
		Y.RepTreatmentID

	-- Table temporaire contenant la somme des exceptions de commissions de service par groupe d'unités, représentant, niveau du
	-- représentant et traitement de commissions
	SELECT 
		E.UnitID, -- ID du groupe d'unités
		E.RepID, -- ID du représentant
		E.RepLevelID, -- ID du niveau du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		Exception = SUM(E.RepExceptionAmount) -- Somme des exceptions de commissions
	INTO #tbComException
	FROM #tbYearRepTreatment Y
	JOIN Un_RepException E ON E.RepExceptionDate <= Y.RepTreatmentDate
	JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
	WHERE ET.RepExceptionTypeTypeID = 'COM'
	GROUP BY
		E.UnitID,
		E.RepID,
		E.RepLevelID,
		Y.RepTreatmentID

	-- Table temporaire donnant la somme des avances non couvertes et commissions de service versés avant et dans un traitement de
	-- commissions par représentant et traitement de commissions
	SELECT 
		C.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount), -- Somme des avances non couvertes
		CumComm = SUM(C.CommissionAmount) -- Sommes des commissions de services
	INTO #tbSumRepCommission
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCommission C ON C.RepTreatmentID <= Y.RepTreatmentID
	GROUP BY
		C.RepID,
		Y.RepTreatmentID 

	-- Table temporaire donnant la somme des avances et commissions de service versés et les avances couvertes dans un traitement de
	-- commissions par représentant et traitement de commissions
	SELECT 
		C.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		UnitQty = SUM(C.UnitQty), -- Somme des unités
		PeriodAdvance = SUM(C.AdvanceAmount), -- Somme des avances versés dans ce traitement pour ce représentant
		CoveredAdvance = SUM(C.CoveredAdvanceAmount), -- Somme des avances couvertes dans ce traitement pour ce représentant
		PeriodComm = SUM(C.CommissionAmount) -- Somme des commissions de service versés dans ce traitement pour ce représentant
	INTO #tbPeriodRepCommission
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCommission C ON Y.RepTreatmentID = C.RepTreatmentID
	GROUP BY
		C.RepID,
		Y.RepTreatmentID 

	-- Table temporaire donnant la somme des avances non couvertes et commissions de service versés avant et dans un traitement de
	-- commissions par représentant et traitement de commissions, groupe d'unités et niveau du représentant.
	SELECT 
		C.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		U.UnitID, -- ID du groupe d'unités
		A.RepLevelID, -- ID du niveau du représentant
		CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount), -- Somme des avances non couvertes
		CumComm = SUM(C.CommissionAmount) -- Sommes des commissions de services
	INTO #tbSumRepCommissionByUnit
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCommission C ON C.RepTreatmentID <= Y.RepTreatmentID
	JOIN dbo.Un_Unit U ON U.UnitID = C.UnitID
	JOIN #tbUnitRepAdv A ON A.UnitID = C.UnitID AND A.RepID = C.RepID AND A.RepLevelID = C.RepLevelID
	GROUP BY
		C.RepID,
		Y.RepTreatmentID,
		U.UnitID,
		A.RepLevelID

	-- Table temporaire donnant le montant de commissions de services versés ou à verser en date d'un traitement de commissions par
	-- représentant et traitement de commissions, groupe d'unités et niveau du représentant.
	SELECT 
		A.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		U.UnitID, -- ID du groupe d'unités
		A.RepLevelID, -- ID du niveau du représentant
		ServiceComm = -- Commissions de service versés et à versés
			SUM(
				CASE ISNULL(TF.UnitID,0) 
					WHEN 0 THEN ROUND((A.AdvAndComByUnit - A.AdvanceByUnit)*(U.UnitQty+ISNULL(RUNA.UnitQty,0))*A.RepPct/100,2) + ISNULL(E.Exception,0)
				ELSE ROUND(A.AdvAndComByUnit*(U.UnitQty+ISNULL(RUNA.UnitQty,0))*A.RepPct/100,2) + ISNULL(E.Exception,0)
				END
				) 
	INTO #tbServiceComm
	FROM #tbUnitRepAdv A
	JOIN dbo.Un_Unit U ON A.UnitID = U.UnitID
	JOIN #tbFirstDeposit F ON F.UnitID = U.UnitID
	JOIN #tbYearRepTreatment Y ON F.FirstDepositDate <= Y.RepTreatmentDate
	LEFT JOIN #tbRepUnitWithCommNotToPay TF ON TF.UnitID = A.UnitID AND TF.RepTreatmentID = Y.RepTreatmentID
	LEFT JOIN #tbComException E ON E.UnitID = A.UnitID AND E.RepID = A.RepID AND E.RepLevelID = A.RepLevelID AND E.RepTreatmentID = Y.RepTreatmentID
	LEFT JOIN #tbUnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID AND RUNA.RepTreatmentID = Y.RepTreatmentID
	GROUP BY
		A.RepID,
		Y.RepTreatmentID,
		U.UnitID,
		A.RepLevelID 

	-- Table temporaire donnant les commisions de service à venir dans un traitement de commissions pour chaque représentant et traitement
	-- de commissions
	SELECT 
		S.RepID, -- ID du représentant
		S.RepTreatmentID, -- ID du traitement de commissions
		FuturComm = SUM(S.ServiceComm - ISNULL(R.CumComm,0)) -- Commissions de service à venir
	INTO #tbFuturComm
	FROM #tbYearRepTreatment Y
	JOIN #tbServiceComm S ON S.RepTreatmentID = Y.RepTreatmentID
	JOIN #tbFirstDeposit F ON F.UnitID = S.UnitID AND (F.FirstDepositDate <= Y.RepTreatmentDate)
	LEFT JOIN #tbSumRepCommissionByUnit R ON R.RepID = S.RepID AND R.RepTreatmentID = S.RepTreatmentID AND R.UnitID = S.UnitID AND R.RepLevelID = S.RepLevelID
	JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
	-- Le remboursement intégral ne doit pas avoir été effectué pour le groupe d'unités ou doit être daté ultérieurement à la date du
	-- traitement de commissions en question
	WHERE U.IntReimbDate IS NULL
		OR (U.IntReimbDate > Y.RepTreatmentDate)
	GROUP BY
		S.RepID,
		S.RepTreatmentID

	-- Table temporaire donnant la somme des bonis d'affaire versés dans un traitement de commissions pour chaque représentant et
	-- traitement de commissions
	SELECT 
		BB.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		BusinessBonus = SUM(BB.BusinessBonusAmount) -- Somme des bonis d'affaire
	INTO #tbBusinessBonus
	FROM #tbYearRepTreatment Y 
	JOIN Un_RepBusinessBonus BB ON BB.RepTreatmentID = Y.RepTreatmentID
	GROUP BY
		BB.RepID,
		Y.RepTreatmentID

	-- Table temporaire contenant la somme des ajustements pour chaque représentant, rôle et traitement de commissions
	SELECT 
		C.RepID, -- ID du représentant
		RepRoleID = 'REP', -- ID du rôle
		Y.RepTreatmentID, -- ID du traitement de commissions
		Adjustment = SUM(RepChargeAmount) -- Somme des ajustements
	INTO #tbAjustment  
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCharge C ON C.RepTreatmentID = Y.RepTreatmentID
	JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID AND (CT.RepChargeTypeComm <> 0)
	GROUP BY
		C.RepID,
		Y.RepTreatmentID

	-- Table temporaire contenant la somme des retenus pour chaque représentant, rôle et traitement de commissions
	SELECT 
		C.RepID, -- ID du représentant
		RepRoleID = 'REP', -- ID du rôle
		Y.RepTreatmentID, -- ID du traitement de commissions
		Adjustment = SUM(RepChargeAmount) -- Somme des retenus
	INTO #tbRetenu  
	FROM #tbYearRepTreatment Y
	JOIN Un_RepCharge C ON C.RepTreatmentID = Y.RepTreatmentID
	JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID AND CT.RepChargeTypeComm = 0
	GROUP BY
		C.RepID,
		Y.RepTreatmentID

	-- Préparation du sélect final, on ne fait pas les sommes qui tiennent compte des traitements précédents de l'année.
	SELECT 
		Z.RepID, -- ID du représentant
		Y.RepTreatmentID, -- ID du traitement de commissions
		REPConsPct = -- Pourcentage de conservation en tant que représentant à la date du traitement de commissions
			CASE ISNULL(CS.REPUnitQty,0) 
				WHEN 0 THEN 0
			ELSE ROUND(((ISNULL(CS.REPUnitQty,0)-ISNULL(CT.REPUnitQty,0))*100)/ISNULL(CS.REPUnitQty,0),2)
			END,
		DIRConsPct = -- Pourcentage de conservation en tant que directeur à la date du traitement de commissions
			CASE ISNULL(CS.DIRUnitQty,0) 
				WHEN 0 THEN 0
			ELSE ROUND(((ISNULL(CS.DIRUnitQty,0)-ISNULL(CT.DIRUnitQty,0))*100)/ISNULL(CS.DIRUnitQty,0),2)
			END,
		ConsPct = 0, -- Pourcentage de conservation total
		REPPeriodUnit = ISNULL(NS.REPUnitQty,0)-ISNULL(NT.REPUnitQty,0), -- Nouvelles ventes faites dans la période en tant que représentant
		DIRPeriodUnit = ISNULL(NS.DIRUnitQty,0)-ISNULL(NT.DIRUnitQty,0), -- Nouvelles ventes faites dans la période en tant que directeur
		NewAdvance = ISNULL(P.PeriodAdvance,0), -- Avance versés dans ce traitement
		BusinessBonus = ISNULL(B.BusinessBonus,0), -- Bonis d'affaires versés dans ce traitement
		CoveredAdvance = ISNULL(P.CoveredAdvance,0), -- Avances couvertes dans ce traitement
		CommAndBonus = ISNULL(B.BusinessBonus,0)+ISNULL(P.PeriodComm,0), -- Bonis d'affaires et commissions de service versés dans ce traitement
		Adjustment = ISNULL(J.Adjustment,0), -- Ajustements pour ce traitement
		ChqBrut = ISNULL(P.PeriodAdvance,0)+ISNULL(B.BusinessBonus,0)+ISNULL(P.PeriodComm,0)+ISNULL(J.Adjustment,0), -- Montant brutes du chèque fait au représentant (Avances, commissions de service et bonis d'affaires versés dans ce traitement + ajustement de ce traitement)
		Retenu = ISNULL(R.Adjustment,0), -- Retenus pour ce traitement
		ChqNet = ISNULL(P.PeriodAdvance,0)+ISNULL(B.BusinessBonus,0)+ISNULL(P.PeriodComm,0)+ISNULL(J.Adjustment,0)+ISNULL(R.Adjustment,0), -- Montant nettes du chèque fait au représentant (Chèque brut - retenus)
		Mois = ISNULL(B.BusinessBonus,0)+ISNULL(P.PeriodComm,0)+ISNULL(J.Adjustment,0)+ISNULL(P.CoveredAdvance,0), -- Dépense de commissions pour ce traitement
		Advance = ISNULL(C.CumAdvance,0), -- Avance non-couvertes
		FuturCom = ISNULL(C.CumAdvance,0) + ISNULL(F.FuturComm,0), -- Dépense de commissions à venir (commissions de service à venir et avance à couvrir)
		CommPct = -- Porcentage de commissions à ce traitement
			CASE 
				WHEN ISNULL(C.CumAdvance,0)+ISNULL(F.FuturComm,0) <= 0 THEN 0 
			ELSE
				ISNULL(C.CumAdvance,0)/(ISNULL(C.CumAdvance,0)+ISNULL(F.FuturComm,0))*100 
			END 
	INTO #tbSumaryWithNoSum
	FROM #tbYearRepTreatment Y
	JOIN (
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbSumRepCommission
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbPeriodRepCommission
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbNewSales
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbBusinessBonus
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbAjustment
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbRetenu
		-----
		UNION
		-----
		SELECT
			RepTreatmentID, -- ID du traitement de commissions
			RepID -- ID du représentant
		FROM #tbFuturComm
		) Z ON Z.RepTreatmentID = Y.RepTreatmentID
	LEFT JOIN #tbSumRepCommission C ON C.RepTreatmentID = Y.RepTreatmentID AND C.RepID = Z.RepID
	LEFT JOIN #tbFuturComm F ON F.RepTreatmentID = Y.RepTreatmentID AND F.RepID = Z.RepID
	LEFT JOIN #tbPeriodRepCommission P ON P.RepTreatmentID = Y.RepTreatmentID AND P.RepID = Z.RepID
	LEFT JOIN #tbBusinessBonus B ON B.RepTreatmentID = Y.RepTreatmentID AND B.RepID = Z.RepID
	LEFT JOIN #tbAjustment J ON J.RepTreatmentID = Y.RepTreatmentID AND J.RepID = Z.RepID
	LEFT JOIN #tbRetenu R ON R.RepTreatmentID = Y.RepTreatmentID AND R.RepID = Z.RepID
	LEFT JOIN #tbConservPctTerminated CT ON CT.RepTreatmentID = Y.RepTreatmentID AND CT.RepID = Z.RepID
	LEFT JOIN #tbConservPctNewSales CS ON CS.RepTreatmentID = Y.RepTreatmentID AND CS.RepID = Z.RepID
	LEFT JOIN #tbNewSales NS ON NS.RepTreatmentID = Y.RepTreatmentID AND NS.RepID = Z.RepID
	LEFT JOIN #tbTerminated NT ON NT.RepTreatmentID = Y.RepTreatmentID AND NT.RepID = Z.RepID
	ORDER BY
		Z.RepID,
		Y.RepTreatmentDate
   
	-- Select final, fait des sommes pour les champs qui doitvent faire le solde depuis le début de l'année à la date du traitement
	SELECT 
		RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
		S.RepID, -- ID du représentant
		TreatmentYear = YEAR(Y.RepTreatmentDate), -- Année du traitement
		R.RepCode, -- Code du représentant
		RepName = H.LastName+' '+H.FirstName, -- Représentant
		Y.RepTreatmentDate, -- Date du traitement
		REPPeriodUnit = ROUND(S.REPPeriodUnit,4), -- Nombre d'unités vendus dans la période en tant que représentant
		CumREPPeriodUnit = ROUND(SUM(ISNULL(SS.REPPeriodUnit,0)),4), -- Somme des unités vendus en tant que représentant depuis le début de l'année jusqu'au traitement
		DIRPeriodUnit = ROUND(S.DIRPeriodUnit,4), -- Nombre d'unités vendus dans la période en tant que directeur
		CumDIRPeriodUnit = ROUND(SUM(ISNULL(SS.DIRPeriodUnit,0)),4), -- Somme des unités vendus en tant que directeur depuis le début de l'année jusqu'au traitement
		REPConsPct = ROUND(S.REPConsPct,2), -- Pourcentage de conservation en tant que représentant à la date du traitement de commissions
		DIRConsPct = ROUND(S.DIRConsPct,2), -- Pourcentage de conservation en tant que directeur à la date du traitement de commissions
		ConsPct = ROUND(S.ConsPct,2), -- Pourcentage de conservation à la date du traitement de commissions
		BusinessBonus = ROUND(S.BusinessBonus,2), -- Bonis d'affaires versés dans ce traitement
		CoveredAdvance = ROUND(S.CoveredAdvance,2), -- Avances couvertes dans ce traitement
		NewAdvance = ROUND(S.NewAdvance,2), -- Avance versés dans ce traitement
		CommAndBonus = ROUND(S.CommAndBonus,2), -- Bonis d'affaires et commissions de service versés dans ce traitement
		Adjustment = ROUND(S.Adjustment,2), -- Ajustements pour ce traitement
		ChqBrut = ROUND(S.ChqBrut,2), -- Montant brutes du chèque fait au représentant dans ce traitement (Avances, commissions de service et bonis d'affaires versés dans ce traitement + ajustement de ce traitement)
		CumChqBrut = ROUND(SUM(ISNULL(SS.ChqBrut,0)),2), -- Montant brutes du chèque fait au représentant depuis le début l'année du traitement jusqu'à la date du traitement.
		Retenu = ROUND(S.Retenu,2), -- Retenus pour ce traitement
		ChqNet = ROUND(S.ChqNet,2), -- Montant nettes du chèque fait au représentant (Chèque brut - retenus)
		Mois = ROUND(S.Mois,2), -- Dépense de commissions pour ce traitement fait pour ce représentant
		CumMois = ROUND(SUM(ISNULL(SS.Mois,0)),2), -- Dépense de commissions fait pour ce représentant depuis le début l'année du traitement jusqu'à la date du traitement.
		Advance = ROUND(S.Advance,2), -- Avance non-couvertes
		FuturCom = ROUND(S.FuturCom,2), -- Dépense de commissions à venir (commissions de service à venir et avance à couvrir)
		CommPct = ROUND(S.CommPct,2) -- Porcentage de commissions à ce traitement
	FROM #tbYearRepTreatment Y
	JOIN #tbSumaryWithNoSum S ON S.RepTreatmentID = Y.RepTreatmentID
	JOIN Un_Rep R ON R.RepID = S.RepID
	JOIN dbo.Mo_Human H ON S.RepID = H.HumanID
	LEFT JOIN #tbSumaryWithNoSum SS ON (SS.RepTreatmentID <= Y.RepTreatmentID) AND S.RepID = SS.RepID
	GROUP BY
		S.RepID,
		Y.RepTreatmentDate,
		S.REPPeriodUnit,
		S.DIRPeriodUnit,
		S.NewAdvance,
		S.CommAndBonus,
		S.Adjustment,
		S.ConsPct,
		S.REPConsPct,
		S.DIRConsPct,
		S.ChqBrut,
		S.Retenu,
		S.ChqNet,
		S.Mois,
		S.Advance,
		S.FuturCom,
		S.CommPct,
		R.RepCode,
		H.LastName,
		H.FirstName,
		S.BusinessBonus,
		S.CoveredAdvance
	ORDER BY
		S.RepID,
		Y.RepTreatmentDate
END


