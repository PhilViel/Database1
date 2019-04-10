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
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	FN_VentesRep (RP_UN_RepGrossANDNetUnits)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Club du Président"
Valeurs de retours  :	Dataset 
Note                :	2009-03-04	Donald Huppé	    Créaton (à partir de RP_UN_RepGrossANDNetUnits)
						2010-01-11	Donald Huppé	    Ajout du plan 12
                        2018-10-29  Pierre-Luc Simard   N'est plus utilisée
*********************************************************************************************************************/

-- select * from FN_VentesRep ('2009-01-01', '2009-03-14' , 0,  'DIR')
-- select * from FN_VentesRep ('2008-10-01', '2009-09-13' , 149505,  'REP')

CREATE function [dbo].[FN_VentesRep] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@RepID integer, -- un RepID ou 0 pour tous les repid
	@RepType varchar(3) -- Les vente des reps d'un 'DIR' ou les vente d'un 'REP'
	) 

RETURNS @Final
	TABLE (
		RepID int,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		Point float,

		--retrait24 float,
		--Brut24 float,

		ConsPct float
	
		--,AgenceVente varchar(255) -- AgenceVente

		)
BEGIN
    
    SET @RepID = 1/0

    DECLARE @tRepDir TABLE (
		RepID INTEGER PRIMARY KEY,
		BossID INTEGER )

	INSERT INTO @tRepDir -- Table des Directeurs des rep à la date demandée
	SELECT
		RB.RepID,
		BossID = MAX(BossID)
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
				AND (StartDate <= @EndDate)
				AND (EndDate IS NULL OR EndDate >= @EndDate)
			GROUP BY
				  RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	  WHERE RB.RepRoleID = 'DIR'
			and (rb.repid = @RepID or @RepID = 0)
			AND RB.StartDate IS NOT NULL
			AND (RB.StartDate <= @EndDate)
			AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDate)
	  GROUP BY
			RB.RepID

	--Unites brutes 

	DECLARE @tNewSales TABLE (
		RepID INTEGER,
		BossID  INTEGER,
		UnitQtyUniv float,
		UnitQtyRFLEX float,
		UnitQtyInd float,
		UnitQty24Univ float,
		UnitQty24RFLEX float,
		UnitQty24Ind float
		 )

	insert into @tNewSales
	select 
		repID, v.BossID, UnitQtyUniv = sum(UnitQtyUniv), UnitQtyRFLEX = sum(UnitQtyRFLEX), UnitQtyInd = sum(UnitQtyInd), UnitQty24Univ = sum(UnitQty24Univ), UnitQty24RFLEX = sum(UnitQty24RFLEX), UnitQty24Ind = sum(UnitQty24Ind)
	--INTO #NewSales
	from (

		SELECT 
			U.RepID,
			BossUnit.BossID,
			UnitQtyUniv = case when C.PlanID = 8 then  SUM(
						CASE
							WHEN U.dtFirstDeposit >= @StartDate THEN
								CASE
									WHEN NbUnitesAjoutees > 0 THEN
										NbUnitesAjoutees
									ELSE 
										U.UnitQty + ISNULL(UR.UnitQty,0) - ISNULL(TU.fUnitQtyUse, 0)
								END
						ELSE 0
						END) else 0 end, -- Unites brutes universitas
			UnitQtyRFLEX = case when C.PlanID IN (10, 12) then  SUM(
						CASE
							WHEN U.dtFirstDeposit >= @StartDate THEN
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
							WHEN U.dtFirstDeposit >= @StartDate THEN
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
			UnitQty24RFLEX = case when C.PlanID IN (10, 12) then  SUM(
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

		FROM dbo.Un_Unit U 

		join ( -- Dir du UnitID
			SELECT 
				M.UnitID,
				BossID = MAX(RBH.BossID)
			FROM (
				SELECT 
					U.UnitID,
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
			) BossUnit on u.unitid = BossUnit.unitid 
		
		JOIN dbo.Un_Convention C ON U.CONVENTIONID = C.CONVENTIONID

		LEFT JOIN ( --@tTransferedUnits : Unités disponibles transférées (rétention de client)
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
			--	AND (U1.dtFirstDeposit BETWEEN DATEADD(MONTH, -24, @EndDate) and @EndDate)

				-- Pour faire comme RP_UN_RepGrossANDNetUnits en attendant de la réparer pour faire comme ci-haut en reculant de 24 mois
			   -- AND (U1.dtFirstDeposit BETWEEN cast(cast(year(@EndDate) as varchar(4)) + '-01-01' as datetime) and @EndDate)
			
				AND (U1.dtFirstDeposit BETWEEN @Startdate and @EndDate) -- on doit prendre ceci

			GROUP BY
				U1.UnitID,
				U1.UnitQty

			)TU ON TU.UnitID = U.UnitID 

		LEFT JOIN (
			SELECT 
				UR.UnitID,
				UnitQty = SUM(UR.UnitQty)
			FROM Un_UnitReduction UR 
			GROUP BY UR.UnitID
			) UR ON UR.UnitID = U.UnitID

		WHERE 
			U.dtFirstDeposit > DATEADD(MONTH,-24,@EndDate) AND U.dtFirstDeposit <= @EndDate

			and ((U.repid = @RepID and @RepID <> 0 and @RepType = 'REP' )or @RepID = 0) -- Si on demande seulement un RepID d'un REP (et non un DIR)

		GROUP BY 
			U.RepID,
			BossUnit.BossID,
			C.PlanID

		) V
	group by V.RepID, V.BossID

	-- Retraits frais non couverts

	DECLARE @tTerminated TABLE (
		RepID INTEGER ,
		BossID  INTEGER,
		UnitQtyUniv float,
		UnitQtyRFLEX float,
		UnitQtyInd float,
		UnitQty24Univ float,
		UnitQty24RFLEX float,
		UnitQty24Ind float
		 )

	insert into @tTerminated
	select repID, BossID, UnitQtyUniv = sum(UnitQtyUniv), UnitQtyRFLEX = sum(UnitQtyRFLEX), UnitQtyInd = sum(UnitQtyInd), UnitQty24Univ = sum(UnitQty24Univ), UnitQty24RFLEX = sum(UnitQty24RFLEX), UnitQty24Ind = sum(UnitQty24Ind)
	--INTO #Terminated
	from (
	SELECT 
		U.RepID,
		BossUnit.BossID,
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
		UnitQtyRFlex = case when C.PlanID IN (10, 12) then  
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
		UnitQty24RFlex = case when C.PlanID IN (10, 12) then
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

	join ( -- Dir du UnitID
		SELECT 
			M.UnitID,
			BossID = MAX(RBH.BossID)
		FROM (
			SELECT 
				U.UnitID,
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
		) BossUnit on ur.unitid = BossUnit.unitid 

	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN dbo.Un_Convention C ON U.CONVENTIONID = C.CONVENTIONID
	JOIN Un_Modal M ON M.ModalID = U.ModalID	
	LEFT JOIN (--@tReUsedUnits : total des ré-utilisation de frais disponibles par résiliation (UnitReduction)
		SELECT 
			UnitReductionID,
			NbReUsedUnits = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		GROUP BY
			UnitReductionID
		)RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE UR.FeeSumByUnit < M.FeeByUnit
	    AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	AND( UR.ReductionDate > DATEADD(MONTH,-24,@EndDate) AND (UR.ReductionDate <= @EndDate))

	and ((U.repid = @RepID and @RepID <> 0 and @RepType = 'REP' )or @RepID = 0)-- Si on demande seulement un RepID d'un REP (et non un DIR)

	GROUP BY 
		U.RepID,
		BossID,
		C.PlanID
	) V 	group by RepID,BossID

	insert into @Final

	SELECT 
		/*
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
		*/ 

		V.RepID,
		Rep.RepCode,
		Rep = HRep.firstName + ' ' + HRep.LastName,  -- Nom du REP OU le nom d'une agence si @RepType = 'DIR' 
		BusinessStart = Rep.BusinessStart,
		Agence = HDir.FirstName + ' ' + HDir.LastName, -- est l'agence du Rep en date du @EndDate.  n'est pas utilisé dans les tableau d'agence car dans ce cas on utilise plutot le REP en tant qu'agence (voir champ explication du champ REP)
		Point = (SUM(V.BrutUniv) - SUM(V.RetraitsUniv)) + ((SUM(V.BrutRFlex) - SUM(V.RetraitsRFlex)) * 1.25) + (SUM(V.BrutInd) - SUM(V.RetraitsInd)),

		--retrait24 =  SUM(V.Retraits24Univ) + SUM(V.Retraits24RFlex) + SUM(V.Retraits24Ind),
		--Brut24 = SUM(V.Brut24Univ) + SUM(V.Brut24RFlex) + SUM(V.Brut24Ind),

		ConsPct = 
			CASE
				WHEN (SUM(V.Brut24Univ) + SUM(V.Brut24RFlex) + SUM(V.Brut24Ind)) <= 0 THEN 0
			ELSE ROUND(( ((SUM(V.Brut24Univ) - SUM(V.Retraits24Univ)) + (SUM(V.Brut24RFlex) - SUM(V.Retraits24RFlex)) + (SUM(V.Brut24Ind) - SUM(V.Retraits24Ind)) ) / (SUM(V.Brut24Univ) + SUM(V.Brut24RFlex) + SUM(V.Brut24IND))) * 100, 2)
			END

		--,AgenceVente = HDIRVente.FirstName + ' ' + HDIRVente.LastName -- AgenceVente

  FROM (
		SELECT
		 RepID =	Case 
					when @RepType = 'DIR' then NS.BossID 
					when @RepType = 'REP' then NS.RepID 
					end,

		 --BossID = NS.BossID, -- AgenceVente

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

		FROM @tNewSales NS

		---------
		UNION ALL
		---------
		SELECT 
		 RepID =	Case 
					when @RepType = 'DIR' then T.BossID 
					when @RepType = 'REP' then T.RepID 
					end,

		--BossID = T.BossID, -- AgenceVente

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

		FROM @tTerminated T 

       ) V

	join Un_Rep Rep on V.repid = Rep.repid 
	JOIN dbo.Mo_Human HREP on V.repid = HREP.humanid

	--JOIN dbo.Mo_Human HDIRVente on V.BossID = HDIRVente.humanid -- AgenceVente

	join @tRepDir RepDIR on V.repID = RepDIR.RepID
	JOIN dbo.Mo_Human HDIR on RepDIR.BossID = HDIR.humanid

	GROUP BY 
		V.RepID,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		HDir.FirstName + ' ' + HDir.LastName

		--,HDIRVente.FirstName + ' ' + HDIRVente.LastName -- AgenceVente

	--having	SUM(V.BrutUniv) + SUM(V.BrutRFlex) + SUM(V.BrutInd) <> 0

	ORDER BY 
		V.RepID

return

END