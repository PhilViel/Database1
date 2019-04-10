/****************************************************************************************************
Copyrights (c) 2007 Gestion Universitas Inc.
Nom                 :	RP_UN_RepPresidentClubContest
Description         :	Procédure stockée du rapport : Concours club du prédident
Valeurs de retours  :	Dataset 
Note                :	ADX0001206	IA	2007-01-09	Bruno Lapointe		Optimisation.
										2008-11-18  Patrick Robitaille	Intégrer le calcul des rétentions sur le nb. d'unités brutes
										2009-01-30	Patrick Robitaille	Correction sur le calcul du brut et du calcul des résiliations d'unités.  
																		Si une partie ou toutes les unités résiliées ont été réutilisées, le nb. 
																		d'unités résiliées est diminué du nb d'unités réutilisées.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepPresidentClubContest] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@RepContestCfgID INTEGER, -- ID Unique du concours
	@DataOrder VARCHAR(3)) -- Trois caractères désignant l’ordre désiré.  AGY = Par agence et ventes (section1) REP = Par ventes (section 2).
AS
BEGIN
	-- Retourne les unités vendus dans une période par régime et groupé par représentant et agence
	DECLARE 
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@StartDate DATETIME,
		@Today DATETIME

	SET @dtBegin = GETDATE()

	-- Va chercher l'intervalle du concours
	SELECT 
		@StartDate = StartDate
	FROM Un_RepContestCfg
	WHERE RepContestCfgID = @RepContestCfgID

	-- Va chercher la date du jour sans les minutes
	SET @Today = dbo.FN_CRQ_DateNoTime(GETDATE())

	-- Création de tables temporaires
	CREATE TABLE #GrossUnits (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER,
		UnitQty MONEY)

	CREATE TABLE #TerminatedUnits (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER,
		UnitQty MONEY)

	CREATE TABLE #MaxPctBoss (
		RepID INTEGER PRIMARY KEY,
		BossID INTEGER)

	CREATE TABLE #SalesByRecruit (
		UnitID INTEGER PRIMARY KEY)

	CREATE TABLE #RepPresidentClubContest (
		RepID INTEGER,
		LastName VARCHAR(75),
		FirstName VARCHAR(75),
		AgencyLastName VARCHAR(75),
		AgencyFirstName VARCHAR(75),
		GrossUnits MONEY,
		TerminatedUnits MONEY,
		NetUnits MONEY,
		ContestPriceName VARCHAR(75),
		SectionColor INTEGER)

	-- Va chercher la date de premier dépôt qui correspond à la date de la ventes
	INSERT INTO #SalesByRecruit
		SELECT 
			U.UnitID
		FROM dbo.Un_Unit U
		JOIN Un_Rep R ON R.RepID = U.RepID
		WHERE R.BusinessStart >= @StartDate
			AND dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit) = 1

	-- Calcul les ventes brutes
	INSERT INTO #GrossUnits
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
		FROM dbo.Un_Unit U 
		JOIN #SalesByRecruit S ON S.UnitID = U.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
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
			GROUP BY UR.UnitID
			) UR ON UR.UnitID = U.UnitID
		WHERE R.BusinessStart >= @StartDate
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

	-- Calcul des résiliations
	INSERT INTO #TerminatedUnits
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
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID		
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		WHERE (UR.FeeSumByUnit < M.FeeByUnit) -- Compte uniquement les résiliations dont les frais n'étaient pas totalement couvert
		  AND (R.BusinessStart >= @StartDate)
		  AND (dbo.fn_Un_IsRecruit(R.BusinessStart, UR.ReductionDate) = 1)
		  AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		GROUP BY
			U.UnitID,
			U.RepID

	-- Va chercher les agences
	INSERT INTO #MaxPctBoss
		SELECT
			RB.RepID,
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		JOIN Un_Rep R ON R.RepID = RB.RepID
		JOIN (
			SELECT
				RepID,
				RepBossPct = MAX(RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
			  AND (StartDate IS NOT NULL)
			  AND (StartDate <= @Today)
			  AND (EndDate IS NULL OR EndDate >= @Today)
			GROUP BY
				RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE RB.RepRoleID = 'DIR'
		  AND (RB.StartDate IS NOT NULL)
		  AND (RB.StartDate <= @Today)
		  AND (RB.EndDate IS NULL OR RB.EndDate >= @Today)
		  AND (R.BusinessStart >= @StartDate)
		GROUP BY
			RB.RepID

	-- Sélection finale
	INSERT INTO #RepPresidentClubContest
		SELECT
			V.RepID, -- ID unique du représentant
			V.LastName, -- Nom du représentant
			V.FirstName, -- Prénom du représentant
			V.AgencyLastName, -- Nom du directeur
			V.AgencyFirstName, -- Prénom du directeur
			V.GrossUnits, -- Ventes brutes
			V.TerminatedUnits, -- Résiliations
			V.NetUnits, -- Ventes nettes
			ContestPriceName = ISNULL(P.ContestPriceName,''), -- Nom du prix
			SectionColor = ISNULL(P.SectionColor, 16777215) -- Couleur de la ligne
		FROM (
			SELECT
				R.RepID,
				H.LastName,
				H.FirstName,
				AgencyFirstName = B.FirstName,
				AgencyLastName = B.LastName,
				GrossUnits = ISNULL(SUM(N.UnitQty),0),
				TerminatedUnits = ISNULL(SUM(T.UnitQty),0),
				NetUnits = ISNULL(SUM(N.UnitQty),0) - ISNULL(SUM(T.UnitQty),0)
			FROM dbo.Un_Unit U
			JOIN Un_Rep R ON (U.RepID = R.RepID)
			JOIN dbo.Mo_Human H ON (H.HumanID = R.RepID)
			JOIN #MaxPctBoss M ON (U.RepID = M.RepID)
			JOIN dbo.Mo_Human B ON (B.HumanID = M.BossID)
			LEFT JOIN #GrossUnits N ON (R.RepID = N.RepID) AND (U.UnitID = N.UnitID)
			LEFT JOIN #TerminatedUnits T ON (R.RepID = T.RepID) AND (U.UnitID = T.UnitID)
			WHERE (N.UnitID IS NOT NULL)
				OR (T.UnitID IS NOT NULL)
			GROUP BY
				R.RepID,
				H.LastName,
				H.FirstName,
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
			LEFT JOIN Un_RepContestPriceCfg P2 ON (P2.MinUnitQty > P.MinUnitQty) AND (P2.RepContestCfgID = @RepContestCfgID)
			WHERE P.RepContestCfgID = @RepContestCfgID
			GROUP BY
				P.RepContestPriceCfgID,
				P.ContestPriceName,
				P.MinUnitQty,
				P.SectionColor
			) P ON (P.MinUnitQty <= V.NetUnits) AND (P.MaxUnitQty IS NULL OR P.MaxUnitQty > V.NetUnits)

	IF @DataOrder = 'AGY' -- Tri par agences et ventes nettes
		SELECT
			RepID,
			LastName,
			FirstName,
			Agency = AgencyFirstName+' '+AgencyLastName,
			GrossUnits,
			TerminatedUnits,
			NetUnits,
			ContestPriceName,
			SectionColor
		FROM #RepPresidentClubContest
		ORDER BY
			AgencyLastName,
			AgencyFirstName,
			NetUnits DESC,
			LastName,
			FirstName
	ELSE IF @DataOrder = 'REP' -- Tri par ventes nettes
		SELECT
			RepID,
			LastName,
			FirstName,
			Agency = AgencyFirstName+' '+AgencyLastName,
			GrossUnits,
			TerminatedUnits,
			NetUnits,
			ContestPriceName,
			SectionColor
		FROM #RepPresidentClubContest 
		ORDER BY
			NetUnits DESC,
			LastName,
			FirstName,
			AgencyLastName,
			AgencyFirstName

	DROP TABLE #GrossUnits
	DROP TABLE #TerminatedUnits
	DROP TABLE #MaxPctBoss
	DROP TABLE #SalesByRecruit
	DROP TABLE #RepPresidentClubContest

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
				'Concours club du prédident',
				'RP_UN_RepPresidentClubContest',
				'EXECUTE RP_UN_RepPresidentClubContest @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @RepContestCfgID = '+CAST(@RepContestCfgID AS VARCHAR)+
					', @DataOrder = '+@DataOrder
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepPresidentClubContest] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@RepContestCfgID = 294, -- ID Unique du concours, 294 = NIVEAU 2009
	@DataOrder = REP -- Trois caractères désignant l’ordre désiré.  AGY = Par agence et ventes (section1) REP = Par ventes (section 2).
*/


