/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepConcoursUnitBenef (RP_UN_RepGrossANDNetUnits)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants
Valeurs de retours  :	Dataset 
Note                :	2009-02-13	Donald Huppé	Créaton (à partir de RP_UN_RepGrossANDNetUnits)
						2009-02-26	Donald Huppé	Modification pour ne pas afficher les ventre des rep qui ne sont plus actif à la fin du concours 
													et ajout de la date du permis du Rep (GLPI 1487)
						2009-03-19	Donald Huppé	Correction du nb de nouveaux bénéficiaires est maintenant basé sur dtFirstDeposit au leiu de inforceDate
						2009-04-02	Donald Huppé	Correction de bug :		Dans le calcul de #NewSales, mettre ">=" au lieu de ">". 
																			Enlever la clause where de la sum(brut) <> 0
						2009-04-07	Donald Huppé	Correction du calcul des TFR : reculer au début de l'année pour faire comme RP_UN_RepGrossANDNetUnits
													En attente de reculer de 24 mois comme il se devrait
						2009-04-17	Donald Huppé	Afficher les rep inactif malgré la demande GLPI 1487 car les directeurs comparent ce rapport avec le bulletin et les chiffres ne balancent pas sinon.
						2009-04-20	Donald Huppé	Enlever les Rep inactifs à la demande de Patricia.  Ils ne compareront plus les rapports
						2009-05-11	Donald Huppé	Correction du calcul du nb de départ de bénéficiaire.  On vérifie maintenant si les frais sont couverts et que la raison réduit le taux de conservation
						2009-06-02	Pierre-Luc Simard	Ajout du paramètre pour sortir tous les représentants ou les actifs uniquement. Ajout de la date de fin du représentant.
						2009-09-13	Donald Huppé	Correction du calcul des TFR : reculer à startdate au lieu du début de l'année pour faire comme RP_UN_RepGrossANDNetUnits
*********************************************************************************************************************/

-- exec GU_RP_VentesExcelRepConcoursUnitBenef 1, '2008-10-01', '2009-09-13' , 0, 0

CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepConcoursUnitBenef_old] (
	@ConnectID INTEGER, -- ID de connexion de l'usager
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID INTEGER, -- ID du représentant : 0 pour tous
	@Actif BIT) -- Actifs à la fin du coucours uniquement
AS
BEGIN
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER

	SET NOCOUNT ON -- Pour que ça fonctionne avec Access

	SET @dtBegin = GETDATE()

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
		WHERE (U.RepID = @RepID OR @RepID = 0 OR M.BossID IS NOT NULL)
		    AND U.RepID IS NOT NULL
			AND U.dtFirstDeposit IS NOT NULL

	-- Unités disponibles transférées (rétention de client)
	DECLARE @tTransferedUnits TABLE (
		UnitID INTEGER PRIMARY KEY,
		NbUnitesAjoutees MONEY NOT NULL,
		fUnitQtyUse MONEY NOT NULL )

	INSERT INTO @tTransferedUnits
		SELECT 
			U1.UnitID,
			U1.UnitQty - SUM(A.fUnitQtyUse) AS NbUnitesAjoutees,
			fUnitQtyUse = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		JOIN Un_Oper O ON O.OperID = A.OperID
		JOIN Un_Cotisation C ON C.OperID = O.OperID
		JOIN dbo.Un_Unit U1 ON U1.UnitID = C.UnitID
		JOIN @tFirstDeposit FD ON FD.UnitID = U1.UnitID
		WHERE O.OperTypeID = 'TFR'
		  AND (U1.UnitQty - A.fUnitQtyUse) >= 0
		  --AND (FD.FirstDepositDate BETWEEN @StartDate and @EndDate)

		-- Prendre les TFR depuis le début de l'année. Pour faire comme RP_UN_RepGrossANDNetUnits
		-- Mais ce n'est pas bon car il faut reculer de 24 mois.  à corriger quand RP_UN_RepGrossANDNetUnits sera corrigé aussi
		--AND (FD.FirstDepositDate BETWEEN (cast(year(@EndDate) as varchar(4)) +'-01-01') and @EndDate)
		AND (FD.FirstDepositDate BETWEEN @Startdate and @EndDate)

		GROUP BY
			U1.UnitID,
			U1.UnitQty

	--Unites brutes REP

	select repID, UnitQtyUniv = sum(UnitQtyUniv), UnitQtyRFLEX = sum(UnitQtyRFLEX), UnitQtyInd = sum(UnitQtyInd), UnitQty24Univ = sum(UnitQty24Univ), UnitQty24RFLEX = sum(UnitQty24RFLEX), UnitQty24Ind = sum(UnitQty24Ind)
		INTO #NewSales
	from (

	SELECT 
		U.RepID,
		UnitQtyUniv = case when C.PlanID = 8 then  SUM(
					CASE
						WHEN F.FirstDepositDate >= @StartDate THEN
							CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
								ELSE 
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END) else 0 end, -- Unites brutes universitas
		UnitQtyRFLEX = case when C.PlanID = 10 then  SUM(
					CASE
						WHEN F.FirstDepositDate >= @StartDate THEN
							CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
								ELSE 
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END) else 0 end, -- Unites brutes Reflex
		UnitQtyInd = case when C.PlanID = 4 then  SUM(
					CASE
						WHEN F.FirstDepositDate >= @StartDate THEN
							CASE
								WHEN NbUnitesAjoutees > 0 THEN
									NbUnitesAjoutees
								ELSE 
									U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
							END
					ELSE 0
					END) else 0 end, -- Unites brutes Individuel
		UnitQty24Univ = case when C.PlanID = 8 then  SUM(
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) else 0 end, -- Unites brutes sur 24 mois
		UnitQty24RFLEX = case when C.PlanID = 10 then  SUM(
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) else 0 end, -- Unites brutes sur 24 mois

		UnitQty24Ind = case when C.PlanID = 4 then  SUM(
						CASE
							WHEN NbUnitesAjoutees > 0 THEN
								NbUnitesAjoutees
							ELSE
								U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
						END) else 0 end -- Unites brutes sur 24 mois

	FROM @tFirstDeposit F
	JOIN dbo.Un_Unit U ON U.UnitID = F.UnitID
	JOIN dbo.Un_Convention C ON U.CONVENTIONID = C.CONVENTIONID
	LEFT JOIN @tTransferedUnits TU ON (TU.UnitID = U.UnitID)
	LEFT JOIN (
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR 
		GROUP BY UR.UnitID
		) UR ON UR.UnitID = U.UnitID
	WHERE ((U.RepID = @RepID) OR (@RepID = 0))
		and (F.FirstDepositDate > DATEADD(MONTH,-24,@EndDate) AND F.FirstDepositDate <= @EndDate)
	GROUP BY 
		U.RepID,
		C.PlanID
	) V
	group by RepID

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

	select repID, UnitQtyUniv = sum(UnitQtyUniv), UnitQtyRFLEX = sum(UnitQtyRFLEX), UnitQtyInd = sum(UnitQtyInd), UnitQty24Univ = sum(UnitQty24Univ), UnitQty24RFLEX = sum(UnitQty24RFLEX), UnitQty24Ind = sum(UnitQty24Ind)
	INTO #Terminated
	from (
	SELECT 
		U.RepID,
		UnitQtyUniv = case when C.PlanID = 8 then  
			SUM(
				CASE 
					WHEN UR.ReductionDate >= @StartDate THEN 
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END) else 0 end , 
		UnitQtyRFlex = case when C.PlanID = 10 then  
			SUM(
				CASE 
					WHEN UR.ReductionDate >= @StartDate THEN 
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END) else 0 end , 
		UnitQtyInd = case when C.PlanID = 4 then  
			SUM(
				CASE 
					WHEN UR.ReductionDate >= @StartDate THEN 
						CASE
							WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
								UR.UnitQty - RU.NbReUsedUnits
						ELSE UR.UnitQty
						END
				ELSE 0
				END) else 0 end , 
		UnitQty24Univ = case when C.PlanID = 8 then
			SUM(
				CASE
					WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
						UR.UnitQty - RU.NbReUsedUnits
				ELSE UR.UnitQty
				END) else 0 end,
		UnitQty24RFlex = case when C.PlanID = 10 then
			SUM(
				CASE
					WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
						UR.UnitQty - RU.NbReUsedUnits
				ELSE UR.UnitQty
				END) else 0 end,
		UnitQty24Ind = case when C.PlanID = 4 then
			SUM(
				CASE
					WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 THEN
						UR.UnitQty - RU.NbReUsedUnits
				ELSE UR.UnitQty
				END) else 0 end

	FROM Un_UnitReduction UR
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN dbo.Un_Convention C ON U.CONVENTIONID = C.CONVENTIONID
	JOIN Un_Modal M ON M.ModalID = U.ModalID	
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
		AND (U.RepID = @RepID OR @RepID = 0)
	    AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	AND( UR.ReductionDate > DATEADD(MONTH,-24,@EndDate) AND (UR.ReductionDate <= @EndDate))
	GROUP BY 
		U.RepID,
		C.PlanID
	) V 	group by RepID

	-- Va chercher le nombre de nouveaux bénéficiaires entre deux dates pour chaque représentant
	SELECT 
		U.RepID,
		NbBenef = COUNT(NB.BeneficiaryID)
	INTO #tRepNewBeneficiary
	FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			WHERE U.terminatedDate is null or U.terminatedDate > @EndDate -- permet d'aditionner les bénéficaire qui sont de retour suite à une résiliation
			GROUP BY C.BeneficiaryID
			HAVING MIN(U.dtFirstDeposit) BETWEEN @StartDate AND @EndDate -- doit être prendant cette période
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	-- Va chercher le nombre de départs de bénéficiaires entre deux dates pour chaque représentant

	SELECT 
		U.RepID,
		NbOldBenef = COUNT(NB.BeneficiaryID)
	INTO #tRepOldBeneficiary
	FROM ( 
		SELECT -- Premier unitID de la première date de premier dépôt
			NB.BeneficiaryID,
			MinUnitID = MIN(UnitID)
		FROM ( -- Première date du premier dépôt par bénéficaire
			SELECT 
				C.BeneficiaryID,
				MindtFirstDeposit = MIN(U.dtFirstDeposit), -- Premier "Premier Dépôt"
				MaxterminatedDate = Max(U.terminatedDate) -- Dernière résiliation
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			JOIN (
				SELECT 
					C.BeneficiaryID,
					BenefNbUnit.nbUnit,
					NbResil = count(*) -- nombre de résiliation avec frais non couverts pour chaque bénéf.
				FROM dbo.Un_Convention C
				JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
				left JOIN ( -- La somme des résil de frais qui affectent le taux de conservation
					SELECT 
						unitid, FeeSumByUnit = sum(FeeSumByUnit) 
					FROM Un_UnitReduction UR
					LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
					where (URR.bReduitTauxConservationRep = 1 OR URR.bReduitTauxConservationRep IS NULL) 
					GROUP BY unitid	
						) UR ON U.unitID = UR.unitID
				JOIN UN_MODAL M on u.ModalID = M.ModalID
				JOIN ( -- nb total de gr d'unité pour chaque bénéf.
					SELECT  
						C.BeneficiaryID,
						nbUnit = count(*)
					FROM dbo.Un_Convention C
					JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
					GROUP BY BeneficiaryID
					) BenefNbUnit on BenefNbUnit.BeneficiaryID = C.BeneficiaryID
				WHERE U.terminatedDate is not null -- Résilié...
				-- ...avec frais non couverts. S'il n'y en a pas(car left join), alors UR.FeeSumByUnit est null.  
				-- Et Null est plus grand que M.FeeByUnit.  Alors ce n'est pas une résiliation qui affecte (car la clause where est alors fausse), 
				-- donc la résiliation ne compte pas.
				AND UR.FeeSumByUnit < M.FeeByUnit
				GROUP BY C.BeneficiaryID,BenefNbUnit.nbUnit
				HAVING COUNT(*) = BenefNbUnit.nbUnit  -- Nb de résil = nb total de gr d'unité : Donc toutes les unitées sont résiliées
				) OldBenef on OldBenef.BeneficiaryID = C.BeneficiaryID
			GROUP BY C.BeneficiaryID
			HAVING MIN(U.dtFirstDeposit) < @StartDate -- Premier "premier dépôt" doit être avant le concours.  sinon, si pendant le concours, ce cas est géré par le cas précédent
				and Max(U.terminatedDate) between @StartDate AND @EndDate -- dernière résiliation pendant le concours
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.dtFirstDeposit = NB.MindtFirstDeposit
		GROUP BY NB.BeneficiaryID
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID

	SELECT 
		V.RepID,

		BrutUniv = SUM(V.BrutUniv),
		BrutRFlex = SUM(V.BrutRFlex),
		BrutInd = SUM(V.BrutInd),

		NetUniv = SUM(V.BrutUniv) - SUM(V.RetraitsUniv),
		NetRFlex = SUM(V.BrutRFlex) - SUM(V.RetraitsRFlex),
		NetInd = SUM(V.BrutInd) - SUM(V.RetraitsInd),

		Brut24Univ = SUM(V.Brut24Univ),
		Brut24RFlex = SUM(V.Brut24RFlex),
		Brut24Ind = SUM(V.Brut24Ind),

		Net24Univ = SUM(V.Brut24Univ) - SUM(V.Retraits24Univ),
		Net24RFlex = SUM(V.Brut24RFlex) - SUM(V.Retraits24RFlex),
		Net24Ind = SUM(V.Brut24Ind) - SUM(V.Retraits24Ind)

  INTO #Temp
  FROM (
		SELECT
		 NS.RepID,

         BrutUniv = NS.UnitQtyUniv,
         BrutRFlex = NS.UnitQtyRFlex,
         BrutInd = NS.UnitQtyInd,

         RetraitsUniv = 0,
         RetraitsRFlex = 0,
         RetraitsInd = 0,

         Brut24Univ = NS.UnitQty24Univ,
Brut24RFlex = NS.UnitQty24Rflex,
         Brut24Ind = NS.UnitQty24Ind,

         Retraits24Univ = 0,
         Retraits24RFlex = 0,
         Retraits24Ind = 0

		FROM #NewSales NS

		---------
		UNION ALL
		---------
		SELECT 
		 T.RepID,

		 BrutUniv = 0,
		 BrutRFlex = 0,
		 BrutInd = 0,

		 RetraitsUniv = T.UnitQtyUniv,
		 RetraitsRFlex = T.UnitQtyRflex,
		 RetraitsInd = T.UnitQtyInd,

         Brut24Univ = 0,
         Brut24RFlex = 0,
         Brut24Ind = 0,

         Retraits24Univ = T.UnitQty24Univ,
         Retraits24RFlex = T.UnitQty24RFlex,
         Retraits24Ind = T.UnitQty24Ind

		FROM #Terminated T 

       ) V

	GROUP BY 
		V.RepID
	ORDER BY 
		V.RepID

	--- Résultat final

	select  
			t.RepID,
			Rep.RepCode,
			HRep.firstName,
			HRep.LastName,
			BusinessStart = Rep.BusinessStart,
			BusinessEnd = Rep.BusinessEnd,
			DirFirstName = HDir.FirstName,
			DirLastName = HDir.LastName,

			NbBenef = isnull(NbBenef,0), -- Nouveau Bénéf
			NbOldBenef = isnull(NbOldBenef,0), -- Départ bénéf
			NbBenefNet = isnull(NbBenef,0) - isnull(NbOldBenef,0), -- Nouveau bénéf net

			NbUniteBrutUniv = BrutUniv,
			NbUniteNetUniv = NetUniv,

			NbUniteBrutRFlex = BrutRFlex,
			NbUniteNetRFlex = NetRFlex,

			NbUniteBrutInd = BrutInd,
			NbUniteNetInd = NetInd,

			ConsPct = 
				CASE
					WHEN (Brut24Univ + Brut24RFlex + Brut24Ind) <= 0 THEN 0
				ELSE ROUND(( (Net24Univ + Net24RFlex + Net24Ind ) / (Brut24Univ + Brut24RFlex + Brut24Ind)) * 100, 2)
				END
	from 
		#Temp t
		left join #tRepNewBeneficiary NB on t.repid = nb.repid
		left join #tRepOldBeneficiary OB on t.repid = ob.repid
		join Un_Rep Rep on t.repid = Rep.repid
		JOIN dbo.Mo_human HREP on t.repid = HREP.humanid
		join (
			SELECT
				RB.RepID,
				BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
			FROM 
				Un_RepBossHist RB
				JOIN (
					SELECT
						RepID,
						RepBossPct = MAX(RepBossPct)
					FROM 
						Un_RepBossHist RB
					WHERE 
						RepRoleID = 'DIR'
						AND StartDate IS NOT NULL
						AND (StartDate <= GETDATE())
						AND (EndDate IS NULL OR EndDate >= GETDATE())
					GROUP BY
						  RepID
					) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			  WHERE RB.RepRoleID = 'DIR'
					AND RB.StartDate IS NOT NULL
					AND (RB.StartDate <= GETDATE())
					AND (RB.EndDate IS NULL OR RB.EndDate >= GETDATE())
			  GROUP BY
					RB.RepID
		) RepDIR on t.repID = RepDIR.RepID
		join Un_Rep DIR on RepDIR.BossID = DIR.RepId
		JOIN dbo.Mo_human HDIR on DIR.repid = HDIR.humanid
	where isnull(rep.BusinessEnd,'3000-01-01') > @EndDate -- exclure les rep rendu inactif avant la fin du concours (GLPI 1487)
		OR @Actif = 0
		-- and (ISNULL(BrutUniv,0) + ISNULL(BrutRFLEX,0) + ISNULL(BrutInd,0)) <> 0 -- à enlever car cause un débalancement avec RP_UN_RepGrossANDNetUnits
		
	order by

		HRep.LastName,
		HRep.firstName

/*

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
					
					', @RepID = '+CAST(@RepID AS VARCHAR)
*/

END


