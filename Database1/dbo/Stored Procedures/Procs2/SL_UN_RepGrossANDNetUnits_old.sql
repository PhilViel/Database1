/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	SL_UN_RepGrossANDNetUnits 
Description         :	SP qui retourne les unités brutes et nettes pour une période par représentants et directeur (Boss), ou par UnitID
Valeurs de retours  :	Dataset 
Note                :	2009-05-14	Donald Huppé	Créaton 
						2009-09-17	donald Huppé	Enlever l'ajouter des réduction subséquente dans #tTransferedUnits

*********************************************************************************************************************/
-- exec SL_UN_RepGrossANDNetUnits NULL, '2009-01-01','2009-05-25', 433331, 1

-- exec SL_UN_RepGrossANDNetUnits NULL, '2008-10-01', '2009-09-13', 497169, 1
-- exec SL_UN_RepGrossANDNetUnits NULL, '2009-01-01', '2009-04-30', 433331, 0
-- exec SL_UN_RepGrossANDNetUnits 339, NULL, NULL, 0, 0
-- exec SL_UN_RepGrossANDNetUnits NULL, '2009-01-01', '2009-05-02', 0, 0

CREATE PROCEDURE [dbo].[SL_UN_RepGrossANDNetUnits_old] 
	(
	@ReptreatmentID INTEGER, -- ID du traitement de commissions
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER, -- ID du représentant
	@ByUnit INTEGER -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
	) 

/* -- Retourne ceci quand @ByUnit = 0
		#GrossANDNetUnits TABLE (
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut_4 FLOAT,
		Brut_8 FLOAT,
		Brut_10 FLOAT,
		Retraits_4 FLOAT,
		Retraits_8 FLOAT,
		Retraits_10 FLOAT,
		Reinscriptions_4 FLOAT,
		Reinscriptions_8 FLOAT,
		Reinscriptions_10 FLOAT,
		Net_4 FLOAT,
		Net_8 FLOAT,
		Net_10 FLOAT,
		Brut24_4 FLOAT,
		Brut24_8 FLOAT,
		Brut24_10 FLOAT,
		Retraits24_4 FLOAT,
		Retraits24_8 FLOAT,
		Retraits24_10 FLOAT,
		Reinscriptions24_4 FLOAT,
		Reinscriptions24_8 FLOAT,
		Reinscriptions24_10 FLOAT,
		Net24_4 FLOAT,
		Net24_8 FLOAT,
		Net24_10 FLOAT)

-- Retourne ceci quand @ByUnit = 1

		#GrossANDNetUnits Table (
		UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier  NewSale, terminated et ReUsed ensemble
		UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 
*/
as
BEGIN

	DECLARE @dtBegin DATETIME
	SET @dtBegin = GETDATE()

	DECLARE
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER,
		@LastRepTreatmentDate DATETIME,
		@NextRepTreatmentDate DATETIME

	CREATE TABLE #tYearRepTreatment (
		RepTreatmentID INTEGER PRIMARY KEY,
		RepTreatmentDate DATETIME NOT NULL,
		LastRepTreatmentDate DATETIME NULL )

	CREATE TABLE #tYearRepTreatment24Months (
		RepTreatmentID INTEGER PRIMARY KEY,
		RepTreatmentDate DATETIME NOT NULL,
		LastRepTreatmentDate DATETIME NULL )

	IF @ReptreatmentID is not null
		-- On demande un Traitement
		BEGIN

		SELECT 
			@CurrentTreatmentDate = RepTreatmentDate,
			@TreatmentYear = YEAR(RepTreatmentDate)
		FROM Un_RepTreatment
		WHERE RepTreatmentID = @ReptreatmentID

		INSERT INTO #tYearRepTreatment
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

		INSERT INTO #tYearRepTreatment24Months
			SELECT
				R.RepTreatmentID,
				R.RepTreatmentDate,
				LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0))
			FROM Un_RepTreatment R
			LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
			WHERE (R.RepTreatmentDate >= DATEADD(MONTH, -24, @CurrentTreatmentDate))
				AND R.RepTreatmentDate <= @CurrentTreatmentDate
			GROUP BY 
				R.RepTreatmentID,
				R.RepTreatmentDate
		END
	ELSE
		-- On demande une plage de date
		BEGIN

		set @CurrentTreatmentDate = @EndDate
		set @ReptreatmentID = 2 -- 2 est bidon.
		
		-- Ici, LastRepTreatmentDate correspond à @StartDate moins un jour afin d'être logique avec l'utlisation de LastRepTreatmentDate 
		-- qui est le dernier jour du traitementprécédent et non le premier jour de la plage demandé
		insert into #tYearRepTreatment values (2, @EndDate,DATEADD(DAY, -1, @StartDate)) 

		-- Pour le 24 mois, on s'arrange pour que ce soit semblable au traitement correspondant à la date demandée
		-- Ainsi les résultats pour (une date inclue dans un traitement) seront pareils que ceux demandés pour le traitement correspondant.

		-- Traitement correspondant à la date demandée
		select @NextRepTreatmentDate = min(RepTreatmentDate) from Un_RepTreatment where RepTreatmentDate >= @EndDate
		-- S'il n'y a pas de traitement suivant le @EndDate, on en génère un 7 jours suivant le dernier
		if @NextRepTreatmentDate is null
		begin
			select @NextRepTreatmentDate = dateadd(day,7,max(RepTreatmentDate)) from Un_RepTreatment where RepTreatmentDate <= @EndDate
		end

		-- Date de départ du 24 mois
		select @LastRepTreatmentDate = min(LastRepTreatmentDate)
		from(
			SELECT
				R.RepTreatmentID,
				R.RepTreatmentDate,
				LastRepTreatmentDate = MAX(ISNULL(R2.RepTreatmentDate,0))
			FROM Un_RepTreatment R
			LEFT JOIN Un_RepTreatment R2 ON (R2.RepTreatmentDate < R.RepTreatmentDate) OR (R2.RepTreatmentDate = R.RepTreatmentDate AND R2.RepTreatmentID < R.RepTreatmentID)
			WHERE (R.RepTreatmentDate >= DATEADD(MONTH, -24, @NextRepTreatmentDate))
				AND R.RepTreatmentDate <= @NextRepTreatmentDate
			GROUP BY 
				R.RepTreatmentID,
				R.RepTreatmentDate
			) n

		insert into #tYearRepTreatment24Months values (1,@EndDate,@LastRepTreatmentDate)

		END

	CREATE TABLE #tRepID (
		Repid INTEGER PRIMARY KEY
		)
	create index #TmpRep on #tRepID(Repid)

	-- Insérer le Rep ou Boss demandé
	INSERT INTO #tRepID select @RepID where @RepID <> 0

	-- Insérer les Rep d'un Boss demandé
	INSERT INTO #tRepID
		select U.RepID
		from (
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
				M.UnitID
				,M.UnitQty
			HAVING @RepID = 0 OR MAX(RBH.BossID) = @RepID
			) V
		JOIN dbo.Un_Unit U on V.unitID = U.unitID
		where @RepID <> 0 and U.RepID <> @RepID -- Exclure le rep ou boss demandé car on l'a déjà inséré juste avant
		group by U.RepID

	CREATE TABLE #tMaxPctBoss (
		UnitID INTEGER PRIMARY KEY,
		BossID INTEGER NOT NULL )

	INSERT INTO #tMaxPctBoss
		SELECT 
			M.UnitID,
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
			M.UnitID

	-- Je ne sais pas pourquoi mais le fait de faire ce print, améliore de beaucoup la performance
 PRINT '0 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	--Premier depot
	CREATE TABLE #tFirstDeposit (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER NOT NULL,
		FirstDepositDate DATETIME NOT NULL,
		PlanID INTEGER )

	if @RepID <> 0 -- Selon qu'il y a un rep demandé ou non, on fait 2 sql différents (join sur #tRepID ou non) pour maximiser la performance (au lieu de mettre un OR dans une clause where)
	BEGIN
		INSERT INTO #tFirstDeposit
			SELECT 
				U.UnitID,
				U.RepID,
				FirstDepositDate = U.dtFirstDeposit,
				C.PlanID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C on U.ConventionID = C.ConventionID
			JOIN #tRepID R ON U.RepID = R.RepID
			WHERE U.dtFirstDeposit IS NOT NULL
	END
	ELSE
	BEGIN
		INSERT INTO #tFirstDeposit
			SELECT 
				U.UnitID,
				U.RepID,
				FirstDepositDate = U.dtFirstDeposit,
				C.PlanID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C on U.ConventionID = C.ConventionID
			WHERE U.RepID IS NOT NULL
				  AND U.dtFirstDeposit IS NOT NULL
	END

	-- Je ne sais pas pourquoi mais le fait de faire ce print, améliore de beaucoup la performance
 PRINT '2 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	CREATE TABLE #tTransferedUnits (
		UnitID INTEGER PRIMARY KEY,
		NbUnitesAjoutees MONEY NOT NULL,
		RepTreatmentID INTEGER NOT NULL,
		fUnitQtyUse MONEY NOT NULL )

	-- Unités disponibles transférées (rétention de client) sur les unités de la période
	INSERT INTO #tTransferedUnits
		SELECT 
			U1.UnitID,
			-- on n'addtionne plus les réduction subséquentes puisque ça ne sert à rien et en plus ça génère des bug dans quelques cas (essayer avec unitid in (509486,514297))
			(U1.UnitQty /*+ isnull(UR1.UnitQty,0)*/)- SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
			RT.RepTreatmentID,
			fUnitQtyUse = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A 
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		/*LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			GROUP BY UR.UnitID
			) UR1 ON UR1.UnitID = U1.UnitID*/
		JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid
		JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
		JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep
		JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
						and CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
		JOIN #tFirstDeposit FD ON FD.UnitID = U1.UnitID,
		#tYearRepTreatment24Months RT 
		WHERE O.OperTypeID = 'TFR'
		  AND ((U1.UnitQty /*+ isnull(UR1.UnitQty,0)*/)  -  A.fUnitQtyUse) >= 0
		  AND (FD.FirstDepositDate > RT.LastRepTreatmentDate AND FD.FirstDepositDate <= RT.RepTreatmentDate) 
		GROUP BY
			U1.UnitID, RepTreatmentID,
			U1.UnitQty
			--,UR1.UnitQty

	CREATE TABLE #tReinscriptions (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepTreatmentID INTEGER NOT NULL,
		fUnitQtyUse MONEY NOT NULL )

	INSERT INTO #tReinscriptions
		SELECT 
			UnitID_Ori = Uori.unitid,
			U1.UnitID,
			RT.RepTreatmentID,
			fUnitQtyUse = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid

		JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
		JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep
		JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
						and CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		JOIN Un_Modal M  ON M.ModalID = Uori.ModalID	
		JOIN #tFirstDeposit FD ON FD.UnitID = U1.UnitID,
		#tYearRepTreatment24Months RT 
		WHERE (FD.FirstDepositDate > RT.LastRepTreatmentDate AND FD.FirstDepositDate <= RT.RepTreatmentDate)

			-- La réinscription doit correspondre à une réduction de moins de 24 mois, 
			-- sinon on peut avoir plus de réinscription que de réduction, alors on aurait des % de cons > 100
			AND (UR.reductionDate > DATEADD(MONTH,-24,@CurrentTreatmentDate) and UR.reductionDate <= @CurrentTreatmentDate)

			-- La réinscription doit provenir d'une réduction valide (tel que programmé dans les retraits)
			AND  UR.FeeSumByUnit < M.FeeByUnit
			AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		GROUP BY
			U1.UnitID,
			Uori.unitid,
			RepTreatmentID

	CREATE TABLE #tNewSales (
		UnitID INTEGER,
		RepID INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQty FLOAT,
		UnitQty24 FLOAT)

	--Unites brutes REP
	INSERT INTO #tNewSales
	SELECT 
		U.UnitID,
		U.RepID,
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQty = SUM(
					CASE
						WHEN F.FirstDepositDate > T.LastRepTreatmentDate THEN
							CASE
								WHEN TU.NbUnitesAjoutees > 0 THEN
									TU.NbUnitesAjoutees
								ELSE 
							--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END), -- Unites brutes
		UnitQty24 = SUM(
						CASE
							WHEN TU.NbUnitesAjoutees > 0 THEN
								TU.NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) -- Unites brutes sur 24 mois
	FROM #tFirstDeposit F
	JOIN #tYearRepTreatment T ON (F.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (F.FirstDepositDate <= T.RepTreatmentDate)
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	left JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN #tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	--WHERE (U.RepID in (select repID from #tRepID)) OR (@RepID = 0)
	GROUP BY 
		U.UnitID,
		U.RepID,
		MB.BossID,
		T.RepTreatmentID

	CREATE TABLE #tTerminated (
		UnitID INTEGER,
		RepID INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQtyRes FLOAT,
		UnitQtyRes24 FLOAT)

	-- Retraits frais non couverts REP pendant la période
	INSERT INTO #tTerminated
	SELECT 
		U.UnitID,
		U.RepID,
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQtyRes = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN 
							UR.UnitQty
					ELSE 0
				END), 
		UnitQtyRes24 = SUM(UR.UnitQty)
	FROM #tYearRepTreatment T 
	JOIN Un_UnitReduction UR ON (UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	JOIN #tFirstDeposit FD ON UR.UnitID = FD.UnitID
	JOIN dbo.Un_Unit U  ON U.UnitID = UR.UnitID
	JOIN Un_Modal M  ON M.ModalID = U.ModalID	
	left JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
	    AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY 
		U.UnitID,
		U.RepID,
		MB.BossID,
		T.RepTreatmentID

	-- Réutilisation de frais disponibles 
	CREATE TABLE #tReused (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQtyReused FLOAT,
		UnitQtyReused24 FLOAT)

	INSERT INTO #tReused
	select 
		TU.UnitID_Ori, -- Le UnitID original d'où provient la réutilisation
		TU.UnitID, -- Le nouveau UnitID pour séparation de la qty originale en plusieur gr d'unité et donc planID
		FD.RepID,
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQtyReused = SUM(
							CASE 
								WHEN FD.FirstDepositDate > T.LastRepTreatmentDate THEN 
										fUnitQtyUse
								ELSE 0
							END), 
		UnitQtyReused24 = SUM(fUnitQtyUse)
	from 
		#tReinscriptions TU 
		JOIN #tFirstDeposit FD ON FD.UnitID = TU.UnitID
		left JOIN #tMaxPctBoss MB ON FD.UnitID = MB.UnitID
		join #tYearRepTreatment T ON (FD.FirstDepositDate > DATEADD(MONTH,-24,T.RepTreatmentDate)) AND (FD.FirstDepositDate <= T.RepTreatmentDate)
	group by 
		TU.UnitID_Ori,
		TU.unitid,
		FD.RepID,
		MB.BossID,
		T.RepTreatmentID

	CREATE TABLE #GrossANDNetUnitsByUnit  (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT
		)

	create index #indUnit on #GrossANDNetUnitsByUnit(UnitID)
	create index #indRepID on #GrossANDNetUnitsByUnit(RepID)
	create index #indBossID on #GrossANDNetUnitsByUnit(BossID)

	INSERT INTO #GrossANDNetUnitsByUnit
	select
			V.UnitID_Ori,
			V.UnitID,
			V.RepID,
			V.BossID,
			V.RepTreatmentID,
			Brut = SUM(Brut),
			Retraits = SUM(Retraits),
 			Reinscriptions = SUM(Reinscriptions),
			Brut24 = SUM(Brut24),
			Retraits24 = SUM(Retraits24),
			Reinscriptions24 = SUM(Reinscriptions24)
	from ( 
		SELECT
			UnitID_Ori = NS.UnitID,
			NS.UnitID,
			NS.RepID,
			NS.BossID,
			NS.RepTreatmentID,
			Brut = NS.UnitQty,
			Retraits = 0,
 			Reinscriptions = 0,
			Brut24 = NS.UnitQty24,
			Retraits24 = 0,
			Reinscriptions24 = 0
		FROM #tYearRepTreatment Y
		JOIN #tNewSales NS ON NS.RepTreatmentID = Y.RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT 
			UnitID_Ori = T.UnitID,
			T.UnitID,
			T.RepID,
			T.BossID,
			T.RepTreatmentID,
			Brut = 0,
			Retraits = T.UnitQtyRes,
			Reinscriptions = 0,
			Brut24 = 0,
			Retraits24 = T.UnitQtyRes24,
			Reinscriptions24 = 0
		FROM #tYearRepTreatment Y
		JOIN #tTerminated T ON Y.RepTreatmentID = T.RepTreatmentID
		
		---------
		UNION ALL
		---------
		SELECT 
			R.UnitID_Ori,
			R.UnitID,
			R.RepID,
			R.BossID,
			R.RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			Reinscriptions = R.UnitQtyReused,
			Brut24 = 0,
			Retraits24 = 0,
			Reinscriptions24 = R.UnitQtyReused24
		FROM #tYearRepTreatment Y
		JOIN #tReused R ON Y.RepTreatmentID = R.RepTreatmentID
       ) V
	GROUP BY 
		V.UnitID_Ori,
		V.UnitID,
		V.RepID,
		V.BossID,
		V.RepTreatmentID

	ORDER BY 
		V.RepID,
		V.RepTreatmentID

	if @ByUnit = 1 -- Sortir les résultats par UnitID
	BEGIN
		select 
			G.UnitID_Ori, -- Le unitID_Ori permettra à la sp appelante de lier  NewSale, terminated et ReUsed ensemble
			G.UnitID, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original
			G.RepID,
			G.BossID,
			G.RepTreatmentID,
			R.RepTreatmentDate,
			Brut = SUM(Brut),
			Retraits = SUM(Retraits),
 			Reinscriptions = SUM(Reinscriptions),
			Brut24 = SUM(Brut24),
			Retraits24 = SUM(Retraits24),
			Reinscriptions24 = SUM(Reinscriptions24) 
		from #GrossANDNetUnitsByUnit G
		JOIN #tYearRepTreatment R on G.RepTreatmentID = R.RepTreatmentID
		Group by
			G.UnitID_Ori,
			G.UnitID,
			G.RepID,
			G.BossID,
			G.RepTreatmentID,
			R.RepTreatmentDate
	END

	ELSE

	BEGIN
	--insert into #GrossANDNetUnits

	SELECT 
		G.RepID,
		BossID,
		G.RepTreatmentID,
		R.RepTreatmentDate,
		Brut_4 = sum (case when planid = 4 then Brut else 0 end),
		Brut_8 = sum (case when planid = 8 then Brut else 0 end),
		Brut_10 = sum (case when planid = 10 then Brut else 0 end),
		Retraits_4 = sum (case when planid = 4 then Retraits else 0 end),
		Retraits_8 = sum (case when planid = 8 then Retraits else 0 end),
		Retraits_10 = sum (case when planid = 10 then Retraits else 0 end),
		Reinscriptions_4 = sum (case when planid = 4 then Reinscriptions else 0 end),
		Reinscriptions_8 = sum (case when planid = 8 then Reinscriptions else 0 end),
		Reinscriptions_10 = sum (case when planid = 10 then Reinscriptions else 0 end),
			-- = (Brut) - ( (Retraits) - (Reinscriptions) )
		Net_4 = (sum (case when planid = 4 then Brut else 0 end) ) - ( ( sum (case when planid = 4 then Retraits else 0 end) ) - (sum (case when planid = 4 then Reinscriptions else 0 end) ) ),
		Net_8 = (sum (case when planid = 8 then Brut else 0 end) ) - ( ( sum (case when planid = 8 then Retraits else 0 end) ) - (sum (case when planid = 8 then Reinscriptions else 0 end) ) ),
		Net_10 = (sum (case when planid = 10 then Brut else 0 end) ) - ( ( sum (case when planid = 10 then Retraits else 0 end) ) - (sum (case when planid = 10 then Reinscriptions else 0 end) ) ),
		Brut24_4 = sum (case when planid = 4 then Brut24 else 0 end),
		Brut24_8 = sum (case when planid = 8 then Brut24 else 0 end),
		Brut24_10 = sum (case when planid = 10 then Brut24 else 0 end),
		Retraits24_4 = sum (case when planid = 4 then Retraits24 else 0 end),
		Retraits24_8 = sum (case when planid = 8 then Retraits24 else 0 end),
		Retraits24_10 = sum (case when planid = 10 then Retraits24 else 0 end),
		Reinscriptions24_4 = sum (case when planid = 4 then Reinscriptions24 else 0 end),
		Reinscriptions24_8 = sum (case when planid = 8 then Reinscriptions24 else 0 end),
		Reinscriptions24_10 = sum (case when planid = 10 then Reinscriptions24 else 0 end),
		Net24_4 = (sum (case when planid = 4 then Brut24 else 0 end) ) - ( ( sum (case when planid = 4 then Retraits24 else 0 end) ) - (sum (case when planid = 4 then Reinscriptions24 else 0 end) ) ),
		Net24_8 = (sum (case when planid = 8 then Brut24 else 0 end) ) - ( ( sum (case when planid = 8 then Retraits24 else 0 end) ) - (sum (case when planid = 8 then Reinscriptions24 else 0 end) ) ),
		Net24_10 = (sum (case when planid = 10 then Brut24 else 0 end) ) - ( ( sum (case when planid = 10 then Retraits24 else 0 end) ) - (sum (case when planid = 10 then Reinscriptions24 else 0 end) ) )
	FROM #GrossANDNetUnitsByUnit G
	JOIN dbo.Un_Unit U ON U.UnitID = G.UnitID
	JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
	JOIN #tYearRepTreatment R on G.RepTreatmentID = R.RepTreatmentID
	-- On filtre selon le rep ou le boss demandé.  
	where (@RepID = 0) or (G.RepID = @RepID or BossID = @RepID) 
	group by 
		G.RepID,
		BossID,
		G.RepTreatmentID,
		R.RepTreatmentDate
	order by 
		G.RepID,
		BossID,
		G.RepTreatmentID

	END

END


