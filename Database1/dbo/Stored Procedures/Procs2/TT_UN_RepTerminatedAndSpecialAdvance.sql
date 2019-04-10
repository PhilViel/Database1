/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	TT_UN_RepTerminatedAndSpecialAdvance 
Description         :	Traitement d’émission et remboursement des avances spéciales et des avances sur résiliations.
Valeurs de retours  :	@ReturnValue :
									>0 :	Le traitement a réussi.
									<=0 :	Le traitement a échoué.
Note                :	ADX0000696	IA	2005-08-11	Bruno Lapointe		Création
						ADX0000695	IA	2005-09-14	Bruno Lapointe		Changer le fonctionnement pour les représentants 
										                                inactifs : les commissions de services serviront à payer les avances spéciales même 
										                                quand le pourcentage de risque du représentant sera inférieur à 75%.
                                        2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel
                                        2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[TT_UN_RepTerminatedAndSpecialAdvance] (
	@ConnectID INTEGER, -- ID unique de connexion de l’usager qui a lancé le traitement.
	@RepTreatmentID INTEGER ) -- ID unique du traitement de commissions.
AS
BEGIN 
	DECLARE
		@RepTreatmentDate DATETIME,	-- Date du traitement de commissions pour lequel on fait ce traitement.  Correspond 
												-- aussi à la date de fin de la période couverte par le traitement.
		@LastRepTreatmentDate DATETIME,	-- Date du traitement de commissions précédent.
		@MaxRepRisk MONEY,	-- % de risque à utilisé selon la configuration
		@iResult INTEGER	-- Variable conservant le résultat de la procédure 

	-- Cherche la date du traitement de commissions
	SELECT @RepTreatmentDate = RepTreatmentDate
	FROM Un_RepTreatment
	WHERE @RepTreatmentID = RepTreatmentID
	-- Cherche la date du traitement de commissions précédent
	SELECT @LastRepTreatmentDate = MAX(RepTreatmentDate)
	FROM Un_RepTreatment
	WHERE RepTreatmentDate < @RepTreatmentDate
	-- Cherche le % de risque a utiliser pour ce traitement.  
	SELECT @MaxRepRisk = MAX(MaxRepRisk)
	FROM Un_Def

	-- Initialise le résultat au RepTreatmentID.
	SET @iResult = @RepTreatmentID

	-- Calcul, pour chaque groupe d'unités, pour chaque représentant et chaque supérieur, la somme d'avance et la somme
	-- d'avance + commission de service par unité qu'il devrait toucher. 
	-- Cette première partie (Avant le "UNION") fait le calcul pour les représentants qui ont fait les ventes
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		U.RepID, -- ID du représentant
		RL.RepLevelID, -- ID du niveau du représentant
		RepPct = 100.00, -- Pourcentage de commission auquel il a droit (Toujours 100% pour les représentants qui ont fait les ventes)
		AdvanceByUnit = -- Somme d'avances qu'il devrait toucher
			SUM	(
					CASE 
						WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
					ELSE 0
					END
					),
		AdvANDComByUnit = -- Somme d'avances et commissions de service qu'il devrait toucher
			SUM	(
					CASE 
						WHEN RLB.RepLevelBracketTypeID IN ('ADV', 'COM') THEN RLB.AdvanceByUnit
					ELSE 0
					END
					)
	INTO #TUnitRepAdv
	FROM dbo.Un_Unit U
    JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID AND (RLB.EffectDate < = U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
	GROUP BY
		U.UnitID,
		U.RepID,
		RL.RepLevelID
	-----
	UNION
	-----
	-- Cette deuxième partie fait le calcul pour les supérieurs des représentants qui ont fait les ventes
	SELECT 
		U.UnitID,
		RepID = RBH.BossID,
		RL.RepLevelID,
		RepPct = RBH.RepBossPct,
		AdvanceByUnit = 
			SUM	(
					CASE
						-- Prend seulement les montants d'avances
						WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
					ELSE 0
					END
					),
		AdvANDComByUnit =
			SUM	(
					CASE
						-- Prend seulement les montants d'avances et de commissions de service
						WHEN RLB.RepLevelBracketTypeID IN ('ADV','COM') THEN RLB.AdvanceByUnit
					ELSE 0
					END
					)
	FROM dbo.Un_Unit U
    JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND (RL.RepRoleID <> 'REP')
	JOIN Un_RepLevelHist RLH ON RLH.RepID = RBH.BossID AND RL.RepLevelID = RLH.RepLevelID AND (RLH.StartDate <= U.InForceDate) AND ((RLH.EndDate IS NULL) OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
	GROUP BY
		U.UnitID,
		RBH.BossID,
		RL.RepLevelID,
		RBH.RepBossPct

	-- Table qui contiendra la date du premier dépôt de chacun des groupes d'unités
	CREATE TABLE #TFirstDeposit (
		UnitID INTEGER PRIMARY KEY, -- ID de groupe d'unités
		FirstDepositDate DATETIME NOT NULL ) -- Date du premier dépôt
	INSERT INTO #TFirstDeposit
		SELECT 
			C.UnitID,  
			FirstDepositDate =
				CASE 
					-- Étant donné qu'on a pas d'historique des transactions avant le 30 janvier 1998, on prend la date d'entrée en vigueur
					-- du groupe d'unités comme date de premier dépôt s'il y a une transaction en date du 30 janvier 1998.
					WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
				ELSE MIN(O.OperDate) 
				END 
		FROM #TUnitRepAdv V
		JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
		JOIN Un_Cotisation C ON V.UnitID = C.UnitID
		JOIN Un_Oper O ON O.OperID = C.OperID
		GROUP BY
			C.UnitID

	-- Table des groupes d'unités dont une partie des frais est non commissionnable.
	CREATE TABLE #TRepUnitWithCommNotToPay (
		UnitID INTEGER PRIMARY KEY ) -- ID de groupe d'unités
	INSERT INTO #TRepUnitWithCommNotToPay
		SELECT DISTINCT
			U.UnitID
		FROM Un_Oper O 
		JOIN Un_Cotisation Ct ON O.OperID = Ct.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN #TUnitRepAdv A ON A.UnitID = U.UnitID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID AND OT.CommissionToPay = 0
		WHERE O.OperDate <= @RepTreatmentDate
			AND Ct.Fee > 0

	-- Table contenant les unités résiliés après la date de traitement de commissions.  Il faut ajouter c'est unités à ceux qu'on
	-- trouve dans la table Un_Unit pour connaître le nombre d'unités à commissionner pour un groupe d'unités pour ce traitement de 
	-- commissions.
	CREATE TABLE #UnitReductionNotApp (
		UnitID INTEGER PRIMARY KEY, -- ID de groupe d'unités
		UnitQty MONEY NOT NULL) -- Nombre d'unités résiliés après la date de traitement
	INSERT INTO #UnitReductionNotApp
		SELECT 
			UR.UnitID,
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR 
		WHERE UR.ReductionDate > @RepTreatmentDate
		GROUP BY UR.UnitID

	-- Table des exceptions de commissions.
	CREATE TABLE #ComException (
		UnitID INTEGER NOT NULL, -- ID de groupe d'unités
		RepID INTEGER NOT NULL, -- ID du représentant
		RepLevelID INTEGER NOT NULL, -- ID du niveau du représentant
		Exception MONEY NOT NULL, -- Montant en exception de commission
		CONSTRAINT PK_ComException PRIMARY KEY (UnitID, RepID, RepLevelID) ) -- Clef primaire
	INSERT INTO #ComException
		SELECT 
			E.UnitID,
			E.RepID,
			E.RepLevelID,
			Exception = SUM(E.RepExceptionAmount)
		FROM Un_RepException E 
		JOIN Un_RepExceptionType ET ON ET.RepExceptionTypeID = E.RepExceptionTypeID
		WHERE ET.RepExceptionTypeTypeID = 'COM' -- Commission de service seulement
			AND E.RepExceptionDate <= @RepTreatmentDate -- Exception antérieur ou égale au jour du traitement seulement
		GROUP BY
			E.UnitID,
			E.RepID,
			E.RepLevelID

	-- Table contenant le solde des avances non couvertes et des commissions de service payés pour chaque représentant
	CREATE TABLE #SumRepCommission (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		CumAdvance MONEY NOT NULL, -- Montant total des avances non couverte du représentant
		CumComm MONEY NOT NULL ) -- Montant total des commissions de service payés au représentant
	INSERT INTO #SumRepCommission
		SELECT 
			C.RepID,
			CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount),
			CumComm = SUM(C.CommissionAmount)
		FROM Un_RepCommission C 
		WHERE C.RepTreatmentID < = @RepTreatmentID
		GROUP BY C.RepID 

	-- Table contenant le solde des avances et des commissions de service payés pour chaque représentant pour chaque rôle
	CREATE TABLE #SumRepCommissionByRole (
		RepID INTEGER NOT NULL, -- ID du représentant
		RepRoleID CHAR(3) NOT NULL, -- ID du rôle du représentant
		CumAdvance MONEY NOT NULL, -- Montant total des avances versées au représentant
		CumComm MONEY NOT NULL, -- Montant total des commissions de service payés au représentant
		CONSTRAINT PK_SumRepCommissionByRole PRIMARY KEY (RepID, RepRoleID) ) -- Clef primaire
	INSERT INTO #SumRepCommissionByRole
		SELECT 
			C.RepID, 
			RL.RepRoleID,
			CumAdvance = SUM(C.AdvanceAmount),
			CumComm = SUM(C.CommissionAmount)
		FROM Un_RepCommission C 
		JOIN Un_RepLevel RL ON RL.RepLevelID = C.RepLevelID
		WHERE C.RepTreatmentID = @RepTreatmentID
		GROUP BY
			C.RepID,
			RL.RepRoleID 

	-- Table contenant le solde d'avance, d'avance non couverte et de commissions de service pour chaque représentant et supérieur de chacun des groupes d'unités
	CREATE TABLE #tSumRepCommissionByUnit (
		RepID INTEGER NOT NULL, -- ID du représentant
		UnitID INTEGER NOT NULL, -- ID du groupe d'unités
		RepLevelID INTEGER NOT NULL, -- ID du niveau du représentant
		Advance MONEY NOT NULL, -- Montant total des avances versées au représentant
		CumAdvance MONEY NOT NULL, -- Montant total des avances non couverte du représentant
		CumComm MONEY NOT NULL, -- Montant total des commissions de service payés au représentant
		CONSTRAINT PK_SumRepCommissionByUnit PRIMARY KEY (RepID, UnitID, RepLevelID) ) -- Clef primaire
	INSERT INTO #tSumRepCommissionByUnit (
			RepID,
			UnitID,
			RepLevelID,
			Advance,
			CumAdvance,
			CumComm )
		SELECT 
			C.RepID,
			U.UnitID,
			A.RepLevelID,
			Advance = SUM(C.AdvanceAmount),
			CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount),
			CumComm = SUM(C.CommissionAmount)
		FROM Un_RepCommission C 
		JOIN dbo.Un_Unit U ON U.UnitID = C.UnitID
		JOIN #TUnitRepAdv A ON A.UnitID = C.UnitID AND A.RepID = C.RepID AND A.RepLevelID = C.RepLevelID
		WHERE C.RepTreatmentID <= @RepTreatmentID
		GROUP BY
			C.RepID,
			U.UnitID,
			A.RepLevelID

	-- Table contenant le solde de commissions de service pour chaque représentant et supérieur de chacun des groupes d'unités pour lesquelles 
	CREATE TABLE #ServiceComm (
		RepID INTEGER NOT NULL, -- ID du représentant
		UnitID INTEGER NOT NULL, -- ID du groupe d'unités
		RepLevelID INTEGER NOT NULL, -- ID du niveau du représentant
		ServiceComm MONEY NOT NULL, -- Montant total des commissions de service que devrait touché en tout le représentant ou supérieur pour ce groupe d'unités
		CONSTRAINT PK_ServiceComm PRIMARY KEY (RepID, UnitID, RepLevelID) ) -- Clef primaire
	INSERT INTO #ServiceComm
		SELECT 
			A.RepID,
			U.UnitID,
			A.RepLevelID,
			ServiceComm = 
				SUM(
					CASE ISNULL(TF.UnitID,0) -- Groupe d'unités avec frais non commissionable
						WHEN 0 THEN ROUND(((A.AdvANDComByUnit - A.AdvanceByUnit)*(U.UnitQty + ISNULL(RUNA.UnitQty,0)))*(A.RepPct/100),2) + ISNULL(E.Exception,0)
					ELSE ROUND((A.AdvANDComByUnit*(U.UnitQty + ISNULL(RUNA.UnitQty,0)))*(A.RepPct/100),2) + ISNULL(E.Exception,0)
					END
					) 
		FROM #TUnitRepAdv A 
		JOIN dbo.Un_Unit U ON A.UnitID = U.UnitID
		LEFT JOIN #TRepUnitWithCommNotToPay TF ON TF.UnitID = A.UnitID
		LEFT JOIN #ComException E ON E.UnitID = A.UnitID AND E.RepID = A.RepID AND E.RepLevelID = A.RepLevelID
		LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
		WHERE U.ActivationConnectID IS NOT NULL
		GROUP BY
			A.RepID,
			U.UnitID,
			A.RepLevelID 

	DROP TABLE #UnitReductionNotApp
	DROP TABLE #ComException

	-- Table contenant le solde des avances non couvertes et des commissions de service payés pour chaque représentant
	CREATE TABLE #FuturComm (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		FuturComm MONEY NOT NULL ) -- Montant total des commissions de service à recevoir pour chacun des représentants
	INSERT INTO #FuturComm
		SELECT 
			S.RepID,
			FuturComm = SUM(S.ServiceComm - ISNULL(R.CumComm,0))
		FROM #ServiceComm S 
		JOIN #TFirstDeposit F ON F.UnitID = S.UnitID AND (F.FirstDepositDate <= @RepTreatmentDate)
		LEFT JOIN #tSumRepCommissionByUnit R ON R.RepID = S.RepID AND R.UnitID = S.UnitID AND R.RepLevelID = S.RepLevelID
		JOIN dbo.Un_Unit U ON U.UnitID = S.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @RepTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		--WHERE U.IntReimbDate IS NULL
		--	OR (U.IntReimbDate > @RepTreatmentDate)
        WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
		GROUP BY
			S.RepID

	DROP TABLE #ServiceComm

	-- Table contenant pour chaque réduction d'unités et chaque représentant le montant d'avance sur résiliation.  L'avance sur 
	-- résiliation est le montant d'avance qui n'a pas été couverte qu'a touché un représentant pour des unités résiliés dans la
	-- période couverte par le traitement de commission que le représentant doit rembourser.  Le remboursement est fait par des
	-- retenus sur les paiements d'avances et commissions de service des prochains traitements de commissions.
	CREATE TABLE #RESAdvanceByUnitReduction (
		RepID INTEGER NOT NULL, -- ID du représentant
		UnitID INTEGER NOT NULL, -- ID du groupe d'unités
		UnitReductionID INTEGER NOT NULL, -- ID de la réduction d'unités
		RESAmount MONEY NOT NULL, -- Montant d'avance sur résiliation pour la période couverte par ce traitement de commissions
		CONSTRAINT PK_RESAdvanceByUnitReduction PRIMARY KEY (RepID, UnitID, UnitReductionID) ) -- Clef primaire
	INSERT INTO #RESAdvanceByUnitReduction
		SELECT 
			A.RepID, 
			UR.UnitID,
			UR.UnitReductionID,
			RESAmount = SUM(ROUND(A.AdvanceByUnit * UR.UnitQty,2))-ISNULL(E.RepExceptionAmount,0)
		FROM Un_UnitReduction UR 
		JOIN #TUnitRepAdv A ON A.UnitID = UR.UnitID
		JOIN Un_RepLevel RL ON RL.RepLevelID = A.RepLevelID AND RL.RepRoleID = 'REP'
		JOIN #tSumRepCommissionByUnit S ON S.UnitID = UR.UnitID AND S.RepLevelID = RL.RepLevelID AND A.RepID = S.RepID
		JOIN #TFirstDeposit F ON F.UnitID = UR.UnitID
		LEFT JOIN ( -- Va chercher les exceptions de types "Résiliations(Avance)" pour les représentants.
			SELECT
				E.RepID,
				URE.UnitReductionID, 
				RepExceptionAmount = SUM(E.RepExceptionAmount)
			FROM Un_UnitReductionRepException URE 
			JOIN Un_RepException E ON URE.RepExceptionID = E.RepExceptionID
			JOIN Un_RepLevel RL ON RL.RepLevelID = E.RepLevelID AND RL.RepRoleID = 'REP'
			WHERE E.RepExceptionTypeID = 'ARE'
				AND (E.RepExceptionDate <= @RepTreatmentDate)
			GROUP BY
				E.RepID,
				URE.UnitReductionID      
			) E ON E.UnitReductionID = UR.UnitReductionID AND E.RepID = A.RepID
		LEFT JOIN #TRepUnitWithCommNotToPay TF ON TF.UnitID = A.UnitID
		WHERE (UR.ReductionDate > @LastRepTreatmentDate)
			AND (UR.ReductionDate <= @RepTreatmentDate)
			AND TF.UnitID IS NULL
		GROUP BY
			A.RepID,
			UR.UnitID,
			UR.UnitReductionID,
			E.RepExceptionAmount 

	DROP TABLE #TFirstDeposit
	DROP TABLE #TRepUnitWithCommNotToPay
	DROP TABLE #tSumRepCommissionByUnit
	DROP TABLE #TUnitRepAdv

	-- Table contenant pour chaque représentant le montant d'avance sur résiliation du traitement de commissions courant.
	CREATE TABLE #RESAdvance (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		RESAmount MONEY NOT NULL ) -- Montant total des avances sur résiliation pour chaque représentant
	INSERT INTO #RESAdvance
		SELECT 
			RepID,
			RESAmount = SUM(RESAmount)
		FROM #RESAdvanceByUnitReduction
		GROUP BY RepID

	DROP TABLE #RESAdvanceByUnitReduction

	-- Table contenant pour chaque représentant le solde(non remboursé) d'avance sur résiliation des précédents traitements de
	-- commissions.
	CREATE TABLE #SoldeAVR (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		AVRAmount MONEY NOT NULL ) -- Solde des avances sur résiliation des traitements précédents pour chaque représentant
	INSERT INTO #SoldeAVR
		SELECT 
			RepID,
			AVRAmount = SUM(RepChargeAmount)
		FROM Un_RepCharge 
		WHERE RepChargeTypeID = 'AVR'  
			AND RepChargeDate <= @RepTreatmentDate      
		GROUP BY RepID

	-- Table contenant pour chaque représentant le solde(non remboursé) d'avance spéciale.  Les avances spéciales, sont des avances 
	-- données par Gestion Universitas à des représentants dans des occasions spéciales.  
	CREATE TABLE #SoldeAVS (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		AVSAmount MONEY NOT NULL ) -- Solde des avances spéciales pour chaque représentant
	INSERT INTO #SoldeAVS
		SELECT 
			RepID,
			AVSAmount = SUM(Amount)
		FROM Un_SpecialAdvance 
		WHERE EffectDate <= @RepTreatmentDate 
		GROUP BY RepID

	-- Table contenant le pourcentage de commission de chaque représentant.
	CREATE TABLE #CommPct (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		Notes VARCHAR(255),	-- Notes expliquant le calcul du pourcentage de commissions.  Elle sera inscrit dans les ajustements/retenus
									-- qui feront les remboursements de l'avance spéciale et de l'avance sur résiliation.
		CommPct MONEY NOT NULL ) -- Pourcentage de commissions du représentant
	INSERT INTO #CommPct
		SELECT
			C.RepID,
			Notes = 
				') = (AN('+CAST(C.CumAdvance AS VARCHAR)+') + AVR('+CAST(ISNULL(R.AVRAmount,0) AS VARCHAR)+') + AVS('+CAST(ISNULL(S.AVSAmount,0) AS VARCHAR)+'))/(AN('+CAST(C.CumAdvance AS VARCHAR)+') + CS('+CAST(ISNULL(F.FuturComm,0) AS VARCHAR)+'))',
			CommPct = 
				CASE
					-- Évite une erreur de division par 0
					WHEN C.CumAdvance + ISNULL(F.FuturComm,0) < = 0 THEN 0 
				ELSE
					-- % commission = (Avances non couverte + solde d'avance sur résiliation + solde d'avance spéciales)
					--                / (Avances non couverte + Commissions de service à venir)
					ROUND(((C.CumAdvance + ISNULL(R.AVRAmount,0) + ISNULL(S.AVSAmount,0))/(C.CumAdvance + ISNULL(F.FuturComm,0)))*100,2)
				END
		FROM #SumRepCommission C 
		LEFT JOIN #FuturComm F ON F.RepID = C.RepID
		LEFT JOIN #SoldeAVR R ON R.RepID = C.RepID
		LEFT JOIN #SoldeAVS S ON S.RepID = C.RepID
  
	DROP TABLE #FuturComm

	-- Table contenant les ajustements/retenus à créer dans ce traitement de commissions pour effectuer le remboursement
	-- des avances sur résiliations
	CREATE TABLE #AVR (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		RepChargeTypeID CHAR(3) NOT NULL, -- Type d'ajustement ('AVR' tout le temps dans cette table)
		RepChargeDesc VARCHAR(255) NOT NULL, -- Explication de l'ajustement/retenu
		RepChargeAmount MONEY NOT NULL, -- Montant de l'ajustement/retenu
		RepTreatmentID INTEGER NOT NULL, -- ID du traitement de commission
		RepChargeDate DATETIME NOT NULL ) -- Date de l'ajustement/retenu
	INSERT INTO #AVR
		SELECT 
			V.RepID,
			RepChargeTypeID = 'AVR',
			RepChargeDesc = V.Notes,
			RepChargeAmount = V.Amount,
			RepTreatmentID = @RepTreatmentID,
			RepChargeDate = @RepTreatmentDate
		FROM (
			SELECT 
			S.RepID,
			Notes = '%Com('+CAST(P.CommPct AS VARCHAR)+P.Notes,
			Amount = 
				CASE 
					WHEN (P.CommPct > @MaxRepRisk) AND (S.CumAdvance+ISNULL(RES.RESAmount,0)> 0) THEN
						CASE 
							WHEN (S.CumComm+(S.CumAdvance+ISNULL(RES.RESAmount,0))) > 0 THEN
								CASE 
									WHEN (S.CumComm+(S.CumAdvance+ISNULL(RES.RESAmount,0))) < ISNULL(RES.RESAmount,0) THEN
										ISNULL(RES.RESAmount,0) - (S.CumComm+(S.CumAdvance+ISNULL(RES.RESAmount,0))) 
								ELSE 
									CASE 
										WHEN ISNULL(AVR.AVRAmount,0) = 0 THEN 0
									ELSE
										CASE 
											WHEN ((S.CumComm+(S.CumAdvance+ISNULL(RES.RESAmount,0))) - ISNULL(RES.RESAmount,0)) < ISNULL(AVR.AVRAmount,0) THEN
												ISNULL(RES.RESAmount,0) - (S.CumComm+(S.CumAdvance+ISNULL(RES.RESAmount,0)))
										ELSE
											ISNULL(AVR.AVRAmount,0) * -1
										END
									END 
								END
						ELSE ISNULL(RES.RESAmount,0)
						END
				ELSE 
					CASE 
						WHEN S.CumComm > 0 THEN
							CASE 
								WHEN S.CumComm < ISNULL(RES.RESAmount,0) THEN
									ISNULL(RES.RESAmount,0) - S.CumComm
							ELSE 
								CASE 
									WHEN ISNULL(AVR.AVRAmount,0) = 0 THEN 0
								ELSE
									CASE 
										WHEN (S.CumComm - ISNULL(RES.RESAmount,0)) < ISNULL(AVR.AVRAmount,0) THEN
											ISNULL(RES.RESAmount,0) - S.CumComm
									ELSE
										ISNULL(AVR.AVRAmount,0) * -1
									END
								END 
							END
					ELSE ISNULL(RES.RESAmount,0)
					END
				END
			FROM #SumRepCommissionByRole S
			JOIN #CommPct P ON P.RepID = S.RepID
			LEFT JOIN #SoldeAVR AVR ON AVR.RepID = S.RepID
			LEFT JOIN #SoldeAVS AVS ON AVS.RepID = S.RepID
			LEFT JOIN #RESAdvance RES ON RES.RepID = S.RepID
			WHERE S.RepRoleID = 'REP'
			) V
		WHERE V.Amount <> 0

	-- Table contenant le solde des avances et des commissions de service(-remboursement d'avance sur résiliation) payés pour chaque
	-- représentant pour chaque rôle
	CREATE TABLE #SumRepCommissionByRole2 (
		RepID INTEGER NOT NULL, -- ID du représentant
		RepRoleID CHAR(3) NOT NULL, -- ID du rôle du représentant
		CumAdvance MONEY NOT NULL, -- Montant total des avances versées au représentant
		CumComm MONEY NOT NULL, -- Montant total des commissions de service payés au représentant
		CONSTRAINT PK_SumRepCommissionByRole2 PRIMARY KEY (RepID, RepRoleID) ) -- Clef primaire
	INSERT INTO #SumRepCommissionByRole2
		SELECT
			S.RepID,
			S.RepRoleID,
			S.CumAdvance,
			CumComm =
				CASE
					-- S'il n'y a eu de remboursement pour des avances sur résiliaion il conserve le même montant.
					WHEN V.CumComm IS NULL THEN S.CumComm
				ELSE ISNULL(V.CumComm,0)
				END
		FROM #SumRepCommissionByRole S
		LEFT JOIN ( -- Enlève le montant de commissions de service qui sert au remboursement d'avance sur résiliation
			SELECT 
				S.RepID,
				CumComm =
					CASE 
						WHEN S.CumComm > 0 THEN
							CASE 
								WHEN S.CumComm < ISNULL(RES.RESAmount,0) THEN 0 
							ELSE 
								CASE 
									WHEN ISNULL(AVR.AVRAmount,0) = 0 THEN 
										S.CumComm
								ELSE
									CASE 
										WHEN (S.CumComm - ISNULL(RES.RESAmount,0)) < ISNULL(AVR.AVRAmount,0) THEN 0
									ELSE
										(S.CumComm - ISNULL(RES.RESAmount,0)) - ISNULL(AVR.AVRAmount,0) 
									END
								END 
							END
					ELSE S.CumComm
					END
			FROM #SumRepCommissionByRole S
			LEFT JOIN #SoldeAVR AVR ON AVR.RepID = S.RepID
			LEFT JOIN #RESAdvance RES ON RES.RepID = S.RepID
			WHERE S.RepRoleID = 'REP'
		) V ON V.RepID = S.RepID AND S.RepRoleID = 'REP'

	DROP TABLE #SumRepCommissionByRole
	DROP TABLE #SoldeAVR
	DROP TABLE #RESAdvance

	-- Table contenant pour chaque représentant l'avance spéciale versés et les commissions de service versées excluant ceux servant
	-- au remboursement d'avances sur résiliations
	CREATE TABLE #SumRepComm (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		CumAdvance MONEY NOT NULL,	-- Montant d'avance spéciale versés au représentant
		CumComm MONEY NOT NULL ) 	-- Montant de commissions de service versées au représentant excluant ceux servant au remboursement 
											-- d'avances sur résiliations
	INSERT INTO #SumRepComm
		SELECT 
			RepID, 
			CumAdvance = SUM(CumAdvance),
			CumComm = SUM(CumComm)
		FROM #SumRepCommissionByRole2
		GROUP BY RepID 

	DROP TABLE #SumRepCommissionByRole2
	DROP TABLE #SumRepCommission

	-- Table contenant les ajustements/retenus à créer dans ce traitement de commissions pour effectuer le remboursement
	-- des avances spéciales
	CREATE TABLE #AVS (
		RepID INTEGER PRIMARY KEY, -- ID du représentant
		RepChargeTypeID CHAR(3) NOT NULL, -- Type d'ajustement ('AVS' tout le temps dans cette table)
		RepChargeDesc VARCHAR(255) NOT NULL, -- Explication de l'ajustement/retenu
		RepChargeAmount MONEY NOT NULL, -- Montant de l'ajustement/retenu
		RepTreatmentID INTEGER NOT NULL, -- ID du traitement de commission
		RepChargeDate DATETIME NOT NULL ) -- Date de l'ajustement/retenu
	INSERT INTO #AVS
		SELECT 
			V.RepID,
			RepChargeTypeID = 'AVS',
			RepChargeDesc = V.Notes,
			RepChargeAmount = V.Amount, 
			RepTreatmentID = @RepTreatmentID,
			RepChargeDate = @RepTreatmentDate
		FROM (
			SELECT 
				S.RepID,
				Notes = '%Com('+CAST(P.CommPct AS VARCHAR)+P.Notes,
				Amount = 
					CASE 
						WHEN	( (P.CommPct > @MaxRepRisk)
								OR (ISNULL(R.BusinessEnd,@RepTreatmentDate+1) <= @RepTreatmentDate )
								)
								AND (S.CumComm > 0)
								AND (AVS.AVSAmount > 0) THEN
							CASE 
								WHEN S.CumComm < AVS.AVSAmount THEN
									S.CumComm * -1
							ELSE 
								AVS.AVSAmount * -1 
							END
					ELSE 0 
					END
			FROM #SumRepComm S
			JOIN #CommPct P ON P.RepID = S.RepID
			JOIN #SoldeAVS AVS ON AVS.RepID = S.RepID
			JOIN Un_Rep R ON R.RepID = S.RepID
			) V
		WHERE V.Amount <> 0

	DROP TABLE #CommPct
	DROP TABLE #SoldeAVS
	DROP TABLE #SumRepComm
 
	-- Insère les ajustements/retenus des remboursements d'avances spéciales et d'avances sur résiliation dans la table permanente.
	INSERT INTO Un_RepCharge (
			RepID,
			RepChargeTypeID,
			RepChargeDesc,
			RepChargeAmount,
			RepTreatmentID,
			RepChargeDate )
		SELECT *
		FROM #AVR
		---------
		UNION ALL
		---------
		SELECT *
		FROM #AVS

	DROP TABLE #AVR

	IF @@ERROR <> 0 
		SET @iResult = -1
	ELSE
	BEGIN
		-- Insère les ajutements/retenus dans la table des avances spéciales.
		INSERT INTO Un_SpecialAdvance (
				RepID,
				EffectDate,
				Amount,
				RepTreatmentID )
			SELECT 
				A.RepID,
				EffectDate = @RepTreatmentDate,
				Amount = A.RepChargeAmount,
				A.RepTreatmentID
			FROM #AVS A
 
		IF @@ERROR <> 0 
			SET @iResult = -2
	END

	DROP TABLE #AVS

	RETURN(@iResult)
END