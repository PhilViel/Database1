/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_RepNewValidatedSales
Description         :	Rapport des nouvelles ventes validés
Valeurs de retours  :	Dataset 
Note                :	2004-06-14	Bruno Lapointe		Migration et User Problem ADX0000199
						ADX0001014	UP	2006-11-01	Bruno Lapointe		Exclus les BEC
						ADX0001206	IA	2006-11-06	Bruno Lapointe		Optimisation.
						ADX0001285	BR	2007-01-08	Bruno Lapointe		Optimisation.
										2008-07-31	Patrick Robitaille	Utiliser le champ bReduitTauxConservationRep de la table
																		Un_UnitReductionReason au lieu d'une liste d'IDs
										2008-11-18	Patrick Robitaille	Intégrer le calcul des rétentions sur le nb. d'unités brutes
										2009-01-30	Patrick Robitaille	Correction sur le calcul du brut et du calcul des résiliations d'unités.  
																		Si une partie ou toutes les unités résiliées ont été réutilisées, le nb. 
																		d'unités résiliées est diminué du nb d'unités réutilisées.
										2014-05-29	Donald Huppé		glpi 11625 : Pour Terminated60UnitQty (RES frais remb.), 
																		on prend toutes les résiliation qu'elle affecte le taux ou non.
										2014-11-13	Donald Huppé		glpi 12481 : Modifier le calcul des résiliations et réinscriptions : on calcule la qté d'unité selon le ratio des frais encaissés p/r 
																		au frais total prévu : (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit
										2015-02-26	Pierre-Luc Simard	Ne plus vérifier le ValidationConnectID
										2015-05-21	Donald Huppé		Ajouter les rep corpo associé au repID apssé en paramètre

exec RP_UN_RepNewValidatedSales 1,'REP', '2015-05-01' , '2015-05-30', 416305

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_RepNewValidatedSales] (
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

	DECLARE @DateDebutRatio datetime = '2014-10-06'

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
		BEGIN
		INSERT INTO #tRep
		VALUES (@RepID)
		-- Ajouter les rep corpo associé au repID apssé en paramètre
		INSERT INTO #tRep select RepID_Corpo from tblREPR_Lien_Rep_RepCorpo where RepID =  @RepID
		END
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
		FeeTFR MONEY NOT NULL,
		UnitQty MONEY NOT NULL)

	INSERT INTO #tUn_RealFeeByUnit
		SELECT 
			Ct.UnitID, 
			FeeTFR = SUM(Ct.Fee),
			U.UnitQty
		FROM #tTFROper O
		JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		WHERE Ct.Fee > 0
		GROUP BY 
			Ct.UnitID,
			U.UnitQty

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

	-- Va chercher le nombre d'unités qui ont été réduit après la période choisi
	CREATE TABLE #tUnitReductionAfterPeriod (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL )

	INSERT INTO #tUnitReductionAfterPeriod
		SELECT 
			UR.UnitID, 
			UnitQty =	 
				SUM(
					CASE
						WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
							UR.UnitQty - RU.NbReUsedUnits
					ELSE UR.UnitQty
					END)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN #tRep F ON F.RepID = U.RepID -- Filtre des représentants
		LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		WHERE UR.ReductionDate > @EndDate
		  AND (URR.bReduitTauxConservationRep = 1
			  OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
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
			ActiveUnitQty =	CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
							ELSE 
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(S1.fUnitQtyUse, 0)
							END,				
			FeeTransferUnitQty = 
				CASE
					WHEN ISNULL(V.UnitID,0) = 0 THEN 0
				ELSE U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(NbUnitesAjoutees,0) 
				END
		FROM #tRep F -- Filtre des représentants
		JOIN dbo.Un_Unit U ON F.RepID = U.RepID
		LEFT JOIN #tUn_RealFeeByUnit V ON V.UnitID = U.UnitID
		LEFT JOIN #tUnitReductionAfterPeriod UR ON UR.UnitID = U.UnitID
		LEFT JOIN (
			SELECT 
				U1.UnitID,
				U1.UnitQty - SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
				fUnitQtyUse = SUM(A.fUnitQtyUse)
			FROM Un_AvailableFeeUse A
			JOIN #tTFROper O ON O.OperID = A.OperID
			JOIN Un_Cotisation C ON C.OperID = O.OperID
			JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
			WHERE (U1.UnitQty - A.fUnitQtyUse) >= 0
			GROUP BY
				U1.UnitID,
				U1.UnitQty
			) AS S1 ON (S1.UnitID = U.UnitID)
		WHERE --U.ValidationConnectID IS NOT NULL
			--AND 
			U.dtFirstDeposit BETWEEN @StartDate AND @EndDate

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
				ActiveUnitQty,		-- = ActiveUnitQty - FeeTransferUnitQty,
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
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			WHERE --U.ValidationConnectID IS NOT NULL
				--AND 
				ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND (URR.bReduitTauxConservationRep = 1
					OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
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
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			WHERE --U.ValidationConnectID IS NOT NULL
				--AND 
				ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				--AND (ISNULL(URR.bReduitTauxConservationRep,1) = 1 -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
				AND UR.FeeSumByUnit = 0
			---------
			UNION ALL
			---------
			SELECT
				U.UnitID,
				ActiveUnitQty = 0,
				TerminatedUnitQty = 0,
				Terminated60UnitQty = 0,
				PartialTerminatedUnitQty = UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END,
				ReductionUnitQty = 0,
				FeeTransferUnitQty = 0
			FROM #tRep F
			JOIN dbo.Un_Unit U ON F.RepID = U.RepID
			JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID 
			JOIN Un_Modal M ON M.ModalID = U.ModalID
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			WHERE --U.ValidationConnectID IS NOT NULL
				--AND 
				ISNULL(U.TerminatedDate,0) = UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND M.FeeByUnit > UR.FeeSumByUnit
				AND (URR.bReduitTauxConservationRep = 1
					OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
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
			JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
			WHERE --U.ValidationConnectID IS NOT NULL
				--AND 
				ISNULL(U.TerminatedDate,0) <> UR.ReductionDate
				AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
				AND (URR.bReduitTauxConservationRep = 1
					OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
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
		Status = dbo.fn_Un_RepStatus(R.BusinessStart, R.BusinessEnd, @EndDate),
		BossName = 
			CASE ISNULL(B.LastName,'') 
				WHEN '' THEN ''
			ELSE B.LastName + ', ' + B.FirstName 
			END, 
		SubscriberName = HS.LastName + ', ' + HS.FirstName, 
		C.ConventionNo,
		P.PlanDesc,
		UR.FirstPmtDate,
		UR.InForceDate,
		UR.ActiveUnitQty,
		UR.TerminatedUnitQty,
		UR.Terminated60UnitQty,
		UR.PartialTerminatedUnitQty,
		UR.ReductionUnitQty,
		UR.FeeTransferUnitQty
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
	ORDER BY 
		B.LastName, 
		B.FirstName, 
		HR.LastName, 
		HR.FirstName, 
		HS.LastName, 
		HS.FirstName, 
		C.ConventionNo

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
				'Nouvelles ventes validées',
				'RP_UN_RepNewValidatedSales',
				'EXECUTE RP_UN_RepNewValidatedSales @ConnectID = '+CAST(@ConnectID AS VARCHAR)+
					', @Type = '+@Type+
					', @StartDate = '+CONVERT(VARCHAR(15), @StartDate, 103)+
					', @EndDate = '+CONVERT(VARCHAR(15), @EndDate, 103)+
					', @RepID = '+CAST(@RepID AS VARCHAR)
END

/*  Sequence de test - par: PLS - 09-05-2008
	exec [dbo].[RP_UN_RepNewValidatedSales] 
	@ConnectID = 1, -- ID de connexion de l'usager
	@Type = 'REP', -- Type de recherche 'ALL' = Tous les représentants, 'DIR' = Tous les représentants du directeur, 'REP' Représentant unique
	@StartDate = '2008-01-01', -- Date de début de l'interval
	@EndDate ='2008-05-31', -- Date de fin de l'interval
	@RepID = 149653 -- ID unique du représentant, 0 pour tous, 149653 pour Claude Cossette
*/


