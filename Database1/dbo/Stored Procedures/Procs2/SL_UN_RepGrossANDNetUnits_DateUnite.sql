/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	SL_UN_RepGrossANDNetUnits 
Description         :	SP qui retourne les unités brutes et nettes pour une période par représentants et directeur (Boss), ou par UnitID
Valeurs de retours  :	Dataset 
Note                :	2009-05-14	Donald Huppé	    Création 
						2009-09-17	Donald Huppé	    Enlever l'ajouter des réduction subséquente dans #tTransferedUnits
						2009-10-02	Donald Huppé	    Enlever critère dans #tReinscriptions que : La réinscription doit correspondre à une réduction de moins de 24 mois
													    Modifier les critères de recherche pour aller chercher les données 24 mois avant la date de début.  Au lieu de 24 mois avant la date de fin
						2010-01-11	Donald Huppé	    Ajout du plan 12
						2010-01-11	Donald Huppé	    Modification pour ajouter une valeur de retour "Recrue" lorsque demandé par UnitID.  
													    Ce champs sera utilisé dans les rapports de recrues
						2010-02-11	Donald Huppé	    Ne plus utiliser #tFirstDeposit afin d'améliorer la rapidité car loader cette table était trop long
													    Et filtrer le repid ou bossid passé en paramètre à la fin seulement (dans le cas de @ByUnit = 1)
													    Enlever les Print
						2010-05-05	Donald Huppé	    Ne plus utiliser la fct fn_Un_IsRecruit pour le champ recrue car c'est trop long. plutot faire le calcul directement 
													    Ne plus créer les index sur #GrossANDNetUnitsByUnit car c'est trop long
													    résultat :
														quand par id avec plage de date = 5 sec
														quand par traitement avec rep = 17 sec
						2012-04-15	Donald Huppé	    GLPI 7399 : On exclu les unité provenant d'un RIO. Elles sont associées au rep "Siège social".
						2012-11-07	Donald Huppé	    Ne pas retourner les unitid des convention de type R17
						2014-09-23	Donald Huppé	    Modifier le calcul des résiliations et réinscriptions : on calcule la qté d'unité selon le ratio des frais encaissés p/r 
													    au frais total prévu : (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit
						2014-10-14	Donald Huppé	    Faire un Merge des Rep Corpo vers le Rep Original (voir table tblREPR_Lien_Rep_RepCorpo)
						2015-01-26	Donald Huppé	    correction suite au merge des rep corpo : valider le businessStart du rep original pour détermimer s'il est recrue (voir calcul de recrue)
						2015-10-22	Donald Huppé	    glpi 15916 : ajout du paramètre @QteMoisRecrue (défaut = 12)
						2016-06-02	Donald Huppé	    retourne DateUnite en plus quand @ByUnit = 1
						2016-10-28	Donald Huppé	    jira ti-1893 : ajout des unités des régime individuels T(avec FRS à 11.50) et I (de gestion de BEC) : provenant de fntREPR_ObtenirUniteConvT
						2017-12-28	Donald Huppé	    jira prod-7129
						2018-01-05	Donald Huppé	    Correction du calcul de #tTransferedUnits
                        2018-11-08  Pierre-Luc Simard   Utilisation des regroupements de régimes

exec SL_UN_RepGrossANDNetUnits_DateUnite NULL, '2017-11-21','2017-12-25', 0, 1
EXEC SL_UN_RepGrossANDNetUnits_DateUnite 490, NULL, NULL, 0, 0

exec SL_UN_RepGrossANDNetUnits_DateUnite NULL, '2017-01-01', '2017-12-27', 0, 1,12,1

exec SL_UN_RepGrossANDNetUnits_DateUnite
	@ReptreatmentID = NULL,
	@StartDate = '2016-01-01', -- Date de début
	@EndDate = '2016-07-27', -- Date de fin
	@RepID = 0, -- ID du représentant
	@ByUnit = 1, -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
	@QteMoisRecrue = 12,
	@incluConvT = 0

****************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepGrossANDNetUnits_DateUnite] 
	(
	@ReptreatmentID INTEGER, -- ID du traitement de commissions
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER, -- ID du représentant
	@ByUnit INTEGER, -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
	@QteMoisRecrue INTEGER = 12,
	@incluConvT INTEGER = 1
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
		Recrue INTEGER, -- Indique si le rep était recrue quand la vente brute ou le retrait ou la réinscripteur a eu lieu (utile pour les rapports de vente des recrues)
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT,
		DateUnite DATETIME) 
*/
as
BEGIN

	DECLARE @dtBegin DATETIME
	SET @dtBegin = GETDATE()

	DECLARE @DateDebutRatio datetime = '2014-10-06'

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

	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
		BossID INT,
		dtFirstDeposit DATETIME )

	if @incluConvT = 1
	BEGIN
		insert into #UniteConvT
		SELECT * FROM fntREPR_ObtenirUniteConvT(1)
	END


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
 --PRINT '0 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	--Premier depot
	CREATE TABLE #tFirstDeposit (
		UnitID INTEGER PRIMARY KEY,
		RepID INTEGER NOT NULL,
		FirstDepositDate DATETIME NOT NULL,
		Recrue INTEGER,
		PlanID INTEGER )


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
			(U1.UnitQty  + ISNULL(UR2.UnitQty,0) )- SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
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
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR
			GROUP BY UR.UnitID
			) UR2 ON UR2.UnitID = U1.UnitID
		,#tYearRepTreatment24Months RT 
		WHERE O.OperTypeID = 'TFR'
		  AND ( (U1.UnitQty + ISNULL(UR2.UnitQty,0) )- A.fUnitQtyUse) >= 0
		  AND (U1.dtFirstDeposit > RT.LastRepTreatmentDate AND U1.dtFirstDeposit <= RT.RepTreatmentDate)
		  --AND (FD.FirstDepositDate > RT.LastRepTreatmentDate AND FD.FirstDepositDate <= RT.RepTreatmentDate) 
		GROUP BY
			U1.UnitID, RepTreatmentID,
			UR2.UnitQty,
			U1.UnitQty

		--select * from #tTransferedUnits where unitid = 509637
		--return 

 --PRINT '3 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	CREATE TABLE #tReinscriptions (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepTreatmentID INTEGER NOT NULL,
		fUnitQtyUse MONEY NOT NULL,
		Recrue INTEGER
		,DateUnite DATETIME)

	INSERT INTO #tReinscriptions
		SELECT 
			UnitID_Ori = Uori.unitid,
			U1.UnitID,
			RT.RepTreatmentID,
			fUnitQtyUse = SUM(A.fUnitQtyUse * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END),
			Recrue = case when DATEADD(mm,@QteMoisRecrue, isnull(rc.BusinessStart, R.BusinessStart)) > U1.dtFirstDeposit then 1 else 0 end--dbo.fn_Un_IsRecruit(R.BusinessStart, U1.dtFirstDeposit)
			,DateUnite = u1.dtFirstDeposit
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN Un_Rep R on U1.repid = R.Repid
		JOIN dbo.Un_Convention Cv on U1.conventionid = Cv.conventionid

		JOIN Un_UnitReduction UR on a.unitreductionid = UR.unitreductionid 
		JOIN dbo.Un_Unit Uori on UR.unitid = Uori.unitid and Uori.repID = U1.repid -- doit être le même Rep
		JOIN dbo.Un_Convention CvOri on Uori.conventionid = CvOri.conventionid 
						and CvOri.SubscriberID = Cv.SubscriberID -- doit être le même Souscripteur 	--and CvOri.BeneficiaryID = Cv.BeneficiaryID -- On ne vérifie pas le bénéficiaire à la demande de Pascal Gilbert 2009-04-15
		LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
		JOIN Un_Modal M  ON M.ModalID = Uori.ModalID	

		LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u1.RepID = lrc.RepID_Corpo
		LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

		--JOIN #tFirstDeposit FD ON FD.UnitID = U1.UnitID
		,#tYearRepTreatment24Months RT 
		WHERE (U1.dtFirstDeposit > RT.LastRepTreatmentDate AND U1.dtFirstDeposit <= RT.RepTreatmentDate)

			--La réinscription doit correspondre à une réduction de moins de 24 mois, 
			--sinon on peut avoir plus de réinscription que de réduction, alors on aurait des % de cons > 100
			--AND (UR.reductionDate > DATEADD(MONTH,-24,@CurrentTreatmentDate) and UR.reductionDate <= @CurrentTreatmentDate)

			-- TEST : moins de 24 mois entre la réduction et la réinscription
			--AND datediff(mm,UR.ReductionDate,FD.FirstDepositDate) < 24

			-- La réinscription doit provenir d'une réduction valide (tel que programmé dans les retraits)
			AND  UR.FeeSumByUnit < M.FeeByUnit
			AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		GROUP BY
			U1.UnitID,
			Uori.unitid,
			RepTreatmentID,
			isnull(rc.BusinessStart, R.BusinessStart), U1.dtFirstDeposit
			,u1.dtFirstDeposit
		
		--select * from #tReinscriptions where unitid = 509637
		--return 

 --PRINT '4 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	CREATE TABLE #tNewSales (
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQty FLOAT,
		UnitQty24 FLOAT
		,DateUnite DATETIME)

	--Unites brutes REP
	INSERT INTO #tNewSales
	SELECT 
		U.UnitID,
		U.RepID,
		Recrue = case when DATEADD(mm,@QteMoisRecrue,isnull(rc.BusinessStart, R.BusinessStart)) > U.dtFirstDeposit then 1 else 0 end,-- dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit),
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQty = SUM(
					CASE
						WHEN U.dtFirstDeposit > T.LastRepTreatmentDate THEN
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
						WHEN U.dtFirstDeposit > DATEADD(MONTH,-24,T.RepTreatmentDate) THEN
							CASE
								WHEN TU.NbUnitesAjoutees > 0 THEN
									TU.NbUnitesAjoutees
								ELSE 
							--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END) -- Unites brutes sur 24 mois
		,DateUnite = u.dtFirstDeposit
	FROM dbo.Un_Unit U --#tFirstDeposit F
	JOIN Un_Rep R on U.RepID = R.RepID
	JOIN #tYearRepTreatment T ON (U.dtFirstDeposit > DATEADD(MONTH,-24,T.LastRepTreatmentDate)) AND (U.dtFirstDeposit <= T.RepTreatmentDate)
	--JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	LEFT JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN #tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo
	LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

	LEFT JOIN #UniteConvT UT ON U.UnitID = UT.UnitID

	WHERE UT.UnitID is null -- exclure les unité convv T. On va les chercher dans le insert suivant

	GROUP BY 
		U.UnitID,
		U.RepID,
		isnull(rc.BusinessStart, R.BusinessStart), U.dtFirstDeposit,
		MB.BossID,
		T.RepTreatmentID
		,u.dtFirstDeposit
		

	--Unites brutes Convention T
	INSERT INTO #tNewSales
	SELECT 
		U.UnitID,
		UT.RepID,
		Recrue = case when DATEADD(mm,@QteMoisRecrue,isnull(rc.BusinessStart, R.BusinessStart)) > UT.dtFirstDeposit then 1 else 0 end,-- dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit),
		Bossid = isnull(UT.BossID,0),
		T.RepTreatmentID,
		UnitQty = SUM(
					CASE
						WHEN UT.dtFirstDeposit > T.LastRepTreatmentDate THEN
							CASE
								WHEN TU.NbUnitesAjoutees > 0 THEN
									TU.NbUnitesAjoutees
								ELSE 
							--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END), -- Unites brutes
		UnitQty24 =  0 --SELON LE MÉMO DU 12 OCTOBRE : lES t ET I NE FONT PAS PARTI DU CALCUL DU TAUX DE CONSERVATION
			/*
					SUM(
					CASE
						WHEN UT.dtFirstDeposit > DATEADD(MONTH,-24,T.RepTreatmentDate) THEN
							CASE
								WHEN TU.NbUnitesAjoutees > 0 THEN
									TU.NbUnitesAjoutees
								ELSE 
							--		qté actuel+	Qté réduite = qté vendue,	- qté vendue qui est de la rétention
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END) -- Unites brutes sur 24 mois
				*/
		,DateUnite = UT.dtFirstDeposit
	FROM dbo.Un_Unit U
	JOIN #UniteConvT UT ON U.UnitID = UT.UnitID 
	JOIN Un_Rep R on UT.RepID = R.RepID
	JOIN #tYearRepTreatment T ON (UT.dtFirstDeposit > DATEADD(MONTH,-24,T.LastRepTreatmentDate)) AND (UT.dtFirstDeposit <= T.RepTreatmentDate)
	LEFT JOIN #tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON UT.RepID = lrc.RepID_Corpo
	LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

	GROUP BY 
		U.UnitID,
		UT.RepID,
		isnull(rc.BusinessStart, R.BusinessStart),
		UT.dtFirstDeposit,
		UT.BossID,
		T.RepTreatmentID



 --PRINT '5 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	--select *
	--from #tNewSales ns
	--JOIN #UniteConvT UT ON ns.UnitID = UT.UnitID 


	delete from #tNewSales where UnitQty = 0 and UnitQty24 = 0

 --PRINT '6 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	CREATE TABLE #tTerminated (
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQtyRes FLOAT,
		UnitQtyRes24 FLOAT
		,DateUnite DATETIME)

	-- Retraits frais non couverts REP pendant la période
	INSERT INTO #tTerminated
	SELECT 
		U.UnitID,
		U.RepID,
		Recrue = case when DATEADD(mm,@QteMoisRecrue,isnull(rc.BusinessStart, R.BusinessStart)) > UR.ReductionDate then 1 else 0 end, --dbo.fn_Un_IsRecruit(R.BusinessStart, UR.ReductionDate), 
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQtyRes = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN 
							UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END), 
		UnitQtyRes24 = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate) THEN
							UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END)
		,DateUnite = ur.ReductionDate
	FROM #tYearRepTreatment T 
	JOIN Un_UnitReduction UR ON (UR.ReductionDate > DATEADD(MONTH,-24,T.LastRepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	--JOIN #tFirstDeposit FD ON UR.UnitID = FD.UnitID
	JOIN dbo.Un_Unit U  ON U.UnitID = UR.UnitID
	JOIN Un_Rep R on U.RepID = R.RepID
	JOIN Un_Modal M  ON M.ModalID = U.ModalID	
	left JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo
	LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

	LEFT JOIN #UniteConvT UT ON U.UnitID = UT.UnitID


	WHERE UR.FeeSumByUnit < M.FeeByUnit
	    AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		AND UT.UnitID is null -- exclure les unité convv T. On va les chercher dans le insert suivant
		AND U.dtFirstDeposit IS NOT NULL -- jira prod-7129 : IL DOIT Y AVOIR EU UN 1ER DÉPÔT

	GROUP BY 
		U.UnitID,
		U.RepID,
		isnull(rc.BusinessStart, R.BusinessStart), UR.ReductionDate,
		MB.BossID,
		T.RepTreatmentID
		,ur.ReductionDate
		
/*
SELON LE MÉMO DU 12 OCTOBRE :Aucun suivi des résiliations ne sera effectué pour les conventions T et I-BEC. Cela signifie que l’unité sera accordée peu importe si elle est résiliée dans la période du rapport ou subséquemment. 

	-- conv T
	INSERT INTO #tTerminated
	SELECT 
		U.UnitID,
		UT.RepID,
		Recrue = case when DATEADD(mm,@QteMoisRecrue,isnull(rc.BusinessStart, R.BusinessStart)) > UR.ReductionDate then 1 else 0 end, --dbo.fn_Un_IsRecruit(R.BusinessStart, UR.ReductionDate), 
		Bossid = isnull(UT.BossID,0),
		T.RepTreatmentID,
		UnitQtyRes = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > T.LastRepTreatmentDate THEN 
							UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END), 
		UnitQtyRes24 = 
			SUM(
				CASE 
					WHEN UR.ReductionDate > DATEADD(MONTH,-24,T.RepTreatmentDate) THEN
							UR.UnitQty * CASE WHEN UR.ReductionDate >= @DateDebutRatio THEN (M.FeeByUnit - UR.FeeSumByUnit) / M.FeeByUnit ELSE 1 END
					ELSE 0
				END)
		,DateUnite = ur.ReductionDate
	FROM #tYearRepTreatment T 
	JOIN Un_UnitReduction UR ON (UR.ReductionDate > DATEADD(MONTH,-24,T.LastRepTreatmentDate)) AND (UR.ReductionDate <= T.RepTreatmentDate)
	--JOIN #tFirstDeposit FD ON UR.UnitID = FD.UnitID
	JOIN dbo.Un_Unit U  ON U.UnitID = UR.UnitID

	JOIN #UniteConvT UT ON U.UnitID = UT.UnitID

	JOIN Un_Rep R on UT.RepID = R.RepID
	JOIN Un_Modal M  ON M.ModalID = U.ModalID	
	--left JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID

	LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo
	LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

	WHERE UR.FeeSumByUnit < M.FeeByUnit
	    AND (URR.bReduitTauxConservationRep = 1	OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY 
		U.UnitID,
		UT.RepID,
		isnull(rc.BusinessStart, R.BusinessStart), UR.ReductionDate,
		UT.BossID,
		T.RepTreatmentID
		,ur.ReductionDate
*/

 --PRINT '7 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	-- Supprimer les enregistrements dont les 2 qté sont 0
	Delete FROM #tTerminated where UnitQtyRes = 0 and UnitQtyRes24 = 0
 --PRINT '8 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	-- Réutilisation de frais disponibles 
	CREATE TABLE #tReused (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		Bossid INTEGER,
		RepTreatmentID INTEGER,
		UnitQtyReused FLOAT,
		UnitQtyReused24 FLOAT
		,DateUnite DATETIME)

	INSERT INTO #tReused
	select 
		TU.UnitID_Ori, -- Le UnitID original d'où provient la réutilisation
		TU.UnitID, -- Le nouveau UnitID pour séparation de la qty originale en plusieur gr d'unité et donc planID
		U.RepID,
		Recrue = case when DATEADD(mm,@QteMoisRecrue,isnull(rc.BusinessStart, R.BusinessStart)) > U.dtFirstDeposit then 1 else 0 end, --dbo.fn_Un_IsRecruit(R.BusinessStart, U.dtFirstDeposit),
		Bossid = isnull(MB.BossID,0),
		T.RepTreatmentID,
		UnitQtyReused = SUM(
							CASE 
								WHEN U.dtFirstDeposit > T.LastRepTreatmentDate THEN 
										fUnitQtyUse
								ELSE 0
							END), 
		UnitQtyReused24 = SUM(
							CASE 
								WHEN U.dtFirstDeposit > DATEADD(MONTH,-24,T.RepTreatmentDate) THEN 
										fUnitQtyUse
								ELSE 0
							END)
		,DateUnite = U.dtFirstDeposit
	from 
		#tReinscriptions TU 
		--JOIN #tFirstDeposit FD ON FD.UnitID = TU.UnitID
		JOIN dbo.Un_Unit U ON U.UnitID = TU.UnitID
		JOIN Un_Rep R on U.RepID = R.RepID
		LEFT JOIN #tMaxPctBoss MB ON U.UnitID = MB.UnitID
		JOIN #tYearRepTreatment T ON (U.dtFirstDeposit > DATEADD(MONTH,-24,T.LastRepTreatmentDate)) AND (U.dtFirstDeposit <= T.RepTreatmentDate)

		LEFT JOIN tblREPR_Lien_Rep_RepCorpo lrc ON u.RepID = lrc.RepID_Corpo
		LEFT JOIN un_rep rc ON lrc.RepID = rc.RepID -- Le rep original du rep corpo

	group by 
		TU.UnitID_Ori,
		TU.unitid,
		U.RepID,
		isnull(rc.BusinessStart, R.BusinessStart), U.dtFirstDeposit,
		MB.BossID,
		T.RepTreatmentID
		,U.dtFirstDeposit

 --PRINT '9 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	Delete from #tReused where UnitQtyReused = 0 and UnitQtyReused24 = 0

 --PRINT '10 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	CREATE TABLE #GrossANDNetUnitsByUnit  (
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT
		,DateUnite DATETIME
		)

	--create index #indUnit on #GrossANDNetUnitsByUnit(UnitID)
	--create index #indRepID on #GrossANDNetUnitsByUnit(RepID)
	--create index #indBossID on #GrossANDNetUnitsByUnit(BossID)

	--create index #IndtNewSales on #tNewSales(RepTreatmentID)

 --PRINT '101 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	INSERT INTO #GrossANDNetUnitsByUnit
	select
			V.UnitID_Ori,
			V.UnitID,
			V.RepID,
			V.Recrue,
			V.BossID,
			V.RepTreatmentID,
			Brut = SUM(Brut),
			Retraits = SUM(Retraits),
 			Reinscriptions = SUM(Reinscriptions),
			Brut24 = SUM(Brut24),
			Retraits24 = SUM(Retraits24),
			Reinscriptions24 = SUM(Reinscriptions24)
			,DateUnite
	from ( 
		SELECT
			UnitID_Ori = NS.UnitID,
			NS.UnitID,
			NS.RepID,
			NS.Recrue,
			NS.BossID,
			NS.RepTreatmentID,
			Brut = NS.UnitQty,
			Retraits = 0,
 			Reinscriptions = 0,
			Brut24 = NS.UnitQty24,
			Retraits24 = 0,
			Reinscriptions24 = 0
			,DateUnite
		FROM #tNewSales NS
		JOIN #tYearRepTreatment Y ON NS.RepTreatmentID = Y.RepTreatmentID
		---------
		UNION ALL
		---------
		SELECT 
			UnitID_Ori = T.UnitID,
			T.UnitID,
			T.RepID,
			T.Recrue,
			T.BossID,
			T.RepTreatmentID,
			Brut = 0,
			Retraits = T.UnitQtyRes,
			Reinscriptions = 0,
			Brut24 = 0,
			Retraits24 = T.UnitQtyRes24,
			Reinscriptions24 = 0
			,DateUnite
		FROM #tTerminated T 
		JOIN #tYearRepTreatment Y ON Y.RepTreatmentID = T.RepTreatmentID
		
		---------
		UNION ALL
		---------
		SELECT 
			R.UnitID_Ori,
			R.UnitID,
			R.RepID,
			R.Recrue,
			R.BossID,
			R.RepTreatmentID,
			Brut = 0,
			Retraits = 0,
			Reinscriptions = R.UnitQtyReused,
			Brut24 = 0,
			Retraits24 = 0,
			Reinscriptions24 = R.UnitQtyReused24
			,DateUnite
		FROM #tReused R 
		JOIN #tYearRepTreatment Y ON Y.RepTreatmentID = R.RepTreatmentID
       ) V
	--GLPI 7399 : On exclu les unité provenant d'un RIO. Elles sont associé au rep "Siège social".
    left join tblOPER_OperationsRIO rio on rio.iID_Unite_Destination = V.UnitID and rio.bRIO_QuiAnnule = 0 and rio.bRIO_Annulee = 0
    
    -- Exclure les unités de convention de catégorie R17
    left JOIN dbo.Un_Unit u ON V.UnitId = u.UnitID
    left JOIN dbo.tblCONV_ConventionConventionCategorie CCC ON ccC.ConventionId = u.ConventionID
    left JOIN dbo.tblCONV_ConventionCategorie CC ON CCC.ConventionCategorieId = CC.ConventionCategoreId AND CC.CategorieCode = 'R17'
    
	LEFT JOIN #UniteConvT UT ON v.UnitID = UT.UnitID
    where 
		rio.iID_Unite_Destination IS NULL

		--AND CC.ConventionCategoreId IS NULL
		and (
			CC.ConventionCategoreId IS NULL
			OR UT.UnitID IS NOT NULL
			)
    ----------------------------------
	GROUP BY 
		V.UnitID_Ori,
		V.UnitID,
		V.RepID,
		V.Recrue,
		V.BossID,
		V.RepTreatmentID
		,V.DateUnite

	ORDER BY 
		V.RepID,
		V.RepTreatmentID

	-- Faire un Merge des Rep Corpo vers le Rep Original
	UPDATE G
	set g.repid = LR.RepID
	from #GrossANDNetUnitsByUnit G
	join tblREPR_Lien_Rep_RepCorpo LR on LR.repid_Corpo = G.repid

 --PRINT '11 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	if @ByUnit = 1 -- Sortir les résultats par UnitID
	BEGIN
		select 
			G.UnitID_Ori, -- Le unitID_Ori permettra à la sp appelante de lier  NewSale, terminated et ReUsed ensemble
			G.UnitID, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original
			G.RepID,
			G.Recrue,
			G.BossID,
			G.RepTreatmentID,
			R.RepTreatmentDate,
			Brut = SUM(Brut),
			Retraits = SUM(Retraits),
 			Reinscriptions = SUM(Reinscriptions),
			Brut24 = SUM(Brut24),
			Retraits24 = SUM(Retraits24),
			Reinscriptions24 = SUM(Reinscriptions24) 
			,G.DateUnite
		--into TMPGNUNew
		from #GrossANDNetUnitsByUnit G
		JOIN #tYearRepTreatment R on G.RepTreatmentID = R.RepTreatmentID
		/* ajout */ where (@RepID = 0) or (G.RepID = @RepID or BossID = @RepID)
		Group by
			G.UnitID_Ori,
			G.UnitID,
			G.RepID,
			G.Recrue,
			G.BossID,
			G.RepTreatmentID,
			R.RepTreatmentDate
			,G.DateUnite

 --PRINT '12 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	END

	ELSE

	BEGIN
	--insert into #GrossANDNetUnits

	SELECT 
		G.RepID,
		BossID,
		G.RepTreatmentID,
		R.RepTreatmentDate,
		Brut_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Brut else 0 end),
		Brut_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Brut else 0 end),
		Brut_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Brut else 0 end),
		Retraits_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Retraits else 0 end),
		Retraits_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Retraits else 0 end),
		Retraits_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Retraits else 0 end),
		Reinscriptions_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Reinscriptions else 0 end),
		Reinscriptions_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Reinscriptions else 0 end),
		Reinscriptions_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Reinscriptions else 0 end),
			-- = (Brut) - ( (Retraits) - (Reinscriptions) )
		Net_4 = (sum (case when RR.vcCode_Regroupement = 'IND' then Brut else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'IND' then Retraits else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'IND' then Reinscriptions else 0 end) ) ),
		Net_8 = (sum (case when RR.vcCode_Regroupement = 'UNI' then Brut else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'UNI' then Retraits else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'UNI' then Reinscriptions else 0 end) ) ),
		Net_10 = (sum (case when RR.vcCode_Regroupement = 'REF' then Brut else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'REF' then Retraits else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'REF' then Reinscriptions else 0 end) ) ),
		Brut24_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Brut24 else 0 end),
		Brut24_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Brut24 else 0 end),
		Brut24_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Brut24 else 0 end),
		Retraits24_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Retraits24 else 0 end),
		Retraits24_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Retraits24 else 0 end),
		Retraits24_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Retraits24 else 0 end),
		Reinscriptions24_4 = sum (case when RR.vcCode_Regroupement = 'IND' then Reinscriptions24 else 0 end),
		Reinscriptions24_8 = sum (case when RR.vcCode_Regroupement = 'UNI' then Reinscriptions24 else 0 end),
		Reinscriptions24_10 = sum (case when RR.vcCode_Regroupement = 'REF' then Reinscriptions24 else 0 end),
		Net24_4 = (sum (case when RR.vcCode_Regroupement = 'IND' then Brut24 else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'IND' then Retraits24 else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'IND' then Reinscriptions24 else 0 end) ) ),
		Net24_8 = (sum (case when RR.vcCode_Regroupement = 'UNI' then Brut24 else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'UNI' then Retraits24 else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'UNI' then Reinscriptions24 else 0 end) ) ),
		Net24_10 = (sum (case when RR.vcCode_Regroupement = 'REF' then Brut24 else 0 end) ) - ( ( sum (case when RR.vcCode_Regroupement = 'REF' then Retraits24 else 0 end) ) - (sum (case when RR.vcCode_Regroupement = 'REF' then Reinscriptions24 else 0 end) ) )
	FROM #GrossANDNetUnitsByUnit G
	JOIN dbo.Un_Unit U ON U.UnitID = G.UnitID
	JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
    JOIN Un_Plan P ON P.PlanID = C.PlanID
    JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
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

 --PRINT '13 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

	END

 --PRINT '14 - ' + CAST(DATEDIFF(MILLISECOND, @dtBegin, GETDATE())/1000 AS VARCHAR(20))

END