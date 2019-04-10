/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_RepCommissionDetail 
Description         :	Sort le rapport de détaillé des commissions pour qu'on puisse l'insérer dans la table
								temporaire.
Valeurs de retours  :	Dataset :
									RepTreatmentID			INTEGER		ID du traitement de commissions
									RepTreatmentDate 		DATETIME		Date du traitement de commissions
									RepID						INTEGER		ID du représentant
									FirstDepositDate		DATETIME		Date de la première transaction du groupe d'unités
									InforceDate				DATETIME		Date d'entrée en vigueur du groupe d'unités
									Subscriber				VARCHAR(87)	Nom et prénom du souscripteur séparé par une virgule et une espace.
									ConventionNo			VARCHAR(50)	Numéro de convention
									RepName 					VARCHAR(87)	Nom et prénom du représentant séparé par une virgule et une espace.
									RepCode					VARCHAR(75)	Code du représentant
									RepLicenseNo			VARCHAR(75)	Numéro de permis du représentant
									RepRoleDesc				VARCHAR(75)	Rôle du représentant (Directeur, Représentant, etc.)
									LevelShortDesc			VARCHAR(75)	Niveau du représentant (niveau 1, niveau 2, etc.)
									PeriodUnitQty			MONEY			Nombre d'unités vendues dans la période couverte par le traitement
									UnitQty					MONEY			Nombre d'unités du groupe d'unités à la date du traitement
									TotalFee					MONEY			Total des frais du groupe d'unités à la date du traitement
									PeriodAdvance			MONEY			Avance versés dans ce traitement
									CoverdAdvance			MONEY			Avance couverte dans ce traitement
									CumAdvance				MONEY			Avance non couverte après ce traitement
									ServiceComm				MONEY			Commission de service payés ou à payer pour cette vente
									PeriodComm				MONEY			Commission de services payés dans ce traitement
									CummComm					MONEY			Total des commissions de services payées après ce traitement
									FuturComm				MONEY			Commissions de service à payer après ce traitement
									BusinessBonus			MONEY			Bonis d'affaires payés ou à payer pour cette vente
									PeriodBusinessBonus	MONEY			Bonis d'affaires payés dans ce traitement
									CummBusinessBonus		MONEY			Total des bonis d'affaires payés après ce traitement
									FuturBusinessBonus	MONEY			Bonis d'affaires à payer après ce traitement
									SweepstakeBonusAjust	MONEY			Bonis, concours et ajustements
									PaidAmount				MONEY			Montant payé (Commissions de service + bonis d'affaires de la période)
									CommExpenses			MONEY			Dépense de commissions (Commissions de service + bonis d'affaires + avance couverte de la période)
									Notes						VARCHAR(75)	Note indiquant s'il y a eu une résiliation, un transfert de frais ou encore un effet retourné pour ce groupe d'unités dans la période couverte par le traitement.
Note                :	ADX0000696	IA	2005-08-16	Bruno Lapointe		Création
						ADX0001205	UP	2007-07-19	Bruno Lapointe		Ne pas tenir compte des transactions BEC
										2008-07-31 Patrick Robitaille	Utiliser le champ bReduitTauxConservationRep de la table
																		Un_UnitReductionReason au lieu d'une liste d'IDs
										2010-01-04	Donald Huppé		Correction pour que le niveau du directeur face référence à un_replevelhistory (rechercher "2010-01-04" dans le code)

										2011-03-07	Donald Huppé		À la création de #TFirstDeposit, ne plus faire de join sur #TRepTotalLevelBracket. 
																		Cela afin de faire pareil que dans le rapport Sommaire, afin qu'ils balancent.
																		Ce join empêchait de faire sortir des cas ou le rep est modifié dans Un_Unit.  Ces modification de rep (fait pas erreur) ont fait resortir le problème de débalancement
										2016-04-26	Pierre-Luc Simard	Ajout du UnitID et du UnitRepID
										2017-10-20	Donald Huppé		Ajout de DISTINCT pour le calcul de PeriodBusinessBonus car ça duppliquait le montant
						                2018-02-16  Pierre-Luc Simard   Exclure aussi les groupes d'unités avec un RIN partiel
                        JIRA: MC-377	2018-04-12	Maxime Martel		Utilisé le nombre d'unité selon les frais pour l'individuel
                                        2018-05-17  Pierre-Luc Simard   Ajout des PlanID dans Un_RepLevelBracket
										2018-10-30	Donald Huppé		Pour #BusinessBonus, Utiliser V.RepID au lieu de U.RepID.  Ce bug est sorti dans le jira PROD-11673.
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_RepCommissionDetail] (
	@RepTreatmentID INTEGER ) -- ID Unique du traitement de commission
AS
BEGIN
	DECLARE 
		@iBusinessBonusLimit INTEGER,
		@dtLastTreatmentDate DATETIME,
		@dtActualTreatmentDate DATETIME  

	-- Met 6 par défaut pour le nombre limite d'années pour toucher les bonis d'affaires d'un groupe d'unités
	SET @iBusinessBonusLimit = 6
	-- Va chercher le nombre limite d'années pour toucher les bonis d'affaires d'un groupe d'unités dans la table de configuration
	SELECT 
		@iBusinessBonusLimit = BusinessBonusLimit
	FROM Un_Def

	-- Va chercher la date du traitement de commissions précédent
	SELECT 
		@dtLastTreatmentDate = ISNULL(MAX(RepTreatmentDate), 0)   
	FROM Un_RepTreatment   
	WHERE RepTreatmentID < @RepTreatmentID 
	
	-- Va chercher la date du traitement de commissions
	SELECT 
		@dtActualTreatmentDate = RepTreatmentDate   
	FROM Un_RepTreatment   
	WHERE RepTreatmentID = @RepTreatmentID 

	-- Tables temporaire contenant la somme d'avances et de commissions de service versées ou à verser par groupe d'unités,
	-- représentants (représentant et supérieur), niveau et pourcentage de commissions
	-- Avant UNION c'est pour les représentants
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		U.RepID, -- ID du représentant
		RL.RepLevelID, -- ID du niveau
		RepPct = 100.00, -- Pourcentage de commissions
		TotalLevelAdvance = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances uniquement
					WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				),
		TotalLevelCommission = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés de commissions de service seulement
					WHEN RLB.RepLevelBracketTypeID = 'COM' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				)
	INTO #TRepTotalLevelBracket
	FROM dbo.Un_Unit U
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP'
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
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
		RepID = RBH.BossID, -- ID du représentant
		RL.RepLevelID, -- ID du niveau
		RepPct = RBH.RepBossPct, -- Pourcentage de commissions
		TotalLevelAdvance = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés d'avances uniquement
					WHEN RLB.RepLevelBracketTypeID = 'ADV' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				),
		TotalLevelCommission = -- Somme des avances versées ou à verser
			SUM(
				CASE 
					-- Compte les tombés de commissions de service seulement
					WHEN RLB.RepLevelBracketTypeID = 'COM' THEN RLB.AdvanceByUnit
				ELSE 0
				END
				)
	FROM dbo.Un_Unit U
    JOIN Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
	JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND (RL.RepRoleID <> 'REP')
	JOIN Un_RepLevelHist RLH ON RLH.RepID = RBH.BossID AND RL.RepLevelID = RLH.RepLevelID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
	JOIN Un_RepLevelBracket RLB ON RLB.RepLevelID = RL.RepLevelID AND RLB.PlanID = C.PlanID AND (RLB.EffectDate <= U.InForceDate) AND (RLB.TerminationDate IS NULL OR (RLB.TerminationDate >= U.InForceDate))
	GROUP BY
		U.UnitID,
		RBH.BossID,
		RL.RepLevelID,
		RBH.RepBossPct

	-- Table temporaire contenant la date du premier dépôt de chaque groupe d'unités
	SELECT 
		C.UnitID, -- ID du groupe d'unités
		FirstDepositDate = -- Date du premier dépôt (Correspond à la premier transaction pour le groupe d'unités)
			CASE 
				-- On n'a pas l'historique des transactions avant le 30 janvier 1998.  Quand on a une transaction à cette date, c'est une
				-- somme des transaction fait avant.  Dans ce cas on prend la date d'entrée en vigueur de groupe d'unités comme date
				-- de premier dépôt.
				WHEN MIN(O.OperDate) = CAST('1998-01-30' AS DATETIME) THEN MIN(U.InForceDate)
			ELSE MIN(O.OperDate) 
			END 
	INTO #TFirstDeposit
	
	--FROM #TRepTotalLevelBracket V --2011-03-07 : ne plus faire de join sur #TRepTotalLevelBracket
	--JOIN dbo.Un_Unit U ON U.UnitID = V.UnitID
	
	FROM dbo.Un_Unit U 
	
	JOIN Un_Cotisation C ON U.UnitID = C.UnitID
	JOIN Un_Oper O ON O.OperID = C.OperID
	WHERE O.OperTypeID NOT IN ('BEC') -- Exclus les remboursements intégraux.  Les commissions ne sont pas affectés par les variations de frais du à des remboursements intégraux
	GROUP BY C.UnitID
  
	-- Table temporaire contenant la liste des groupes d'unités dont le premier dépôt s'est fait aprés le dernier traitement de
	-- commissions et avant celui-ci
	SELECT DISTINCT
		F.UnitID -- ID du groupe d'unités
	INTO #NewConvForPeriod
	FROM #TFirstDeposit F 
	WHERE F.FirstDepositDate > @dtLastTreatmentDate -- Date de premier dépôt ultérieure au traitement précédent
		AND F.FirstDepositDate <= @dtActualTreatmentDate -- Date de premier dépôt antérieure ou égale au traitement courant

	--	Table temporaire contenant la liste des groupes d'unités qui ont subit une réduction d'unités dans la période couverte par le 
	-- traitement de commissions. (Date de réduction entre la date du dernier traitement et celle du traitement courant)
	SELECT DISTINCT
		UnitID -- ID du groupe d'unités
	INTO #NotesRES
	FROM Un_UnitReduction UR
	JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE ReductionDate > @dtLastTreatmentDate -- Date de la réduction ultérieure au traitement précédent
		AND ReductionDate <= @dtActualTreatmentDate -- Date de la réduction antérieure ou égale au traitement courant
		AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie

	-- Table temporaire contenant la liste des groupes d'unités qui dont un NSF a été déclaré dans la période couverte par le 
	-- traitement de commissions. (Date d'opération entre la date du dernier traitement et celle du traitement courant)
	SELECT DISTINCT
		Ct.UnitID -- ID du groupe d'unités
	INTO #NotesNSF
	FROM Un_Cotisation Ct
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	WHERE O.OperTypeID = 'NSF' -- Opération de type NSF
		AND O.OperDate > @dtLastTreatmentDate -- Date de l'opération ultérieure au traitement précédent
		AND O.OperDate <= @dtActualTreatmentDate -- Date de l'opération antérieure ou égale au traitement courant

	-- Table temporaire contenant la somme des avances versées non couverte et des commissions de services versées par groupe d'unités,
	-- représentant(supérieur inclus), niveau et pourcentage de commissions.
	SELECT 
		C.RepID, -- ID du représentant
		C.UnitID, -- ID du groupe d'unités
		C.RepLevelID, -- ID du niveau
		C2.UnitQty, -- Nombre d'unités dans ce groupe
		C2.RepPct, -- Pourcentage de commissions
		C2.TotalFee, -- Total des frais cotisés pour ce groupe d'unités
		CumAdvance = SUM(C.AdvanceAmount-C.CoveredAdvanceAmount), -- Somme des avances versées non couverte (Avance versés - avances couverte)
		CumComm = SUM(C.CommissionAmount) -- Somme des commissions de service versées
	INTO #SumRepCommission
	FROM Un_RepCommission C
	JOIN Un_RepTreatment T ON T.RepTreatmentID = C.RepTreatmentID
	JOIN (
		SELECT 
			C.RepID, -- ID du représentant
			C.UnitID, -- ID du groupe d'unités
			C.RepLevelID, -- ID du niveau
			MaxRepCommissionID = MAX(C.RepCommissionID) -- ID du dernier versement de commissions pour ce groupe d'unités
		FROM Un_RepCommission C
		JOIN Un_RepTreatment T ON T.RepTreatmentID = C.RepTreatmentID
		WHERE T.RepTreatmentID <= @RepTreatmentID -- Exclus les versements de commissions qui sont ultérieur à ce traitement de commissions
		GROUP BY
			C.RepID,
			C.UnitID,
			C.RepLevelID
		) M ON M.RepID = C.RepID AND M.UnitID = C.UnitID AND M.RepLevelID = C.RepLevelID
	JOIN Un_RepCommission C2 ON C2.RepCommissionID = M.MaxRepCommissionID
	WHERE T.RepTreatmentID <= @RepTreatmentID -- Exclus les versements de commissions qui sont ultérieur à ce traitement de commissions
	GROUP BY
		C.RepID,
		C.UnitID,
		C.RepLevelID,
		C2.UnitQty,
		C2.RepPct,
		C2.TotalFee

	-- Table temporaire des avances versés, des avances couvertes et commissions versés dans ce traitement de commissions pour ce
	-- groupe d'unités, ce représentant, ce niveau, et ce pourcentage de commissions
	SELECT 
		RepID, -- ID du représentant
		UnitID, -- ID du groupe d'unités
		RepLevelID, -- ID du niveau
		UnitQty, -- Nombre d'unités du groupe d'unités
		RepPct, -- Pourcentage de commissions
		TotalFee, -- Total des frais cotisés pour ce groupe d'unités
		PeriodAdvance = SUM(AdvanceAmount), -- Avances versés dans ce traitement de commissions
		CoveredAdvance = SUM(CoveredAdvanceAmount), -- Avances couvertes dans ce traitement de commissions
		PeriodComm = SUM(CommissionAmount) -- Commissions de service versés dans ce traitement de commissions
	INTO #PeriodRepCommission
	FROM Un_RepCommission C
	JOIN Un_RepTreatment T ON T.RepTreatmentID = C.RepTreatmentID
	WHERE T.RepTreatmentID = @RepTreatmentID -- Versements de commissions de traitement de commissions courant seulement.
	GROUP BY
		RepID,
		UnitID,
		RepLevelID,
		UnitQty,
		RepPct,
		TotalFee 

	-- Table temporaire des groupes d'unités qui ont des frais non commissionnés.  Il a aussi un champ qui doit doit avoir une note à 
	-- l'effet qu'il y a eu des dépôts de frais non commissionnés dans la période couverte par le traitement de commissions.
	SELECT DISTINCT
		U.UnitID, -- ID du groupe d'unités
		Notes = -- 0 indique qu'il ne doit pas y avoir de note, 1 qu'il doit y en avoir une
			CASE
				-- Il y a une note si la date de la dernière opérations de frais non commissionnés est ultérieur au dernier traitement de 
				-- commissions.
				WHEN MAX(O.OperDate) > @dtLastTreatmentDate THEN 1
			ELSE 0
			END  
	INTO #TRepUnitWithCommNotToPay
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = Ct.OperID
	JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID AND OT.CommissionToPay = 0
	WHERE O.OperDate <= @dtActualTreatmentDate -- Exclus les opérations ultérieures au traitement de commissions.
		AND Ct.Fee > 0 -- Seulement les dépôts (>0) de frais sont considérés.
	GROUP BY U.UnitID

	-- Table temporaire contenant la somme des exceptions de commissions de service par groupe d'unités, représentant et niveau
	SELECT 
		E.UnitID, -- ID du groupe d'unités
		E.RepID, -- ID du représentant
		E.RepLevelID, -- ID du niveau
		RepExceptionAmount = SUM(E.RepExceptionAmount) -- Somme des exceptions de commissions de service
	INTO #TRepExceptionComm
	FROM Un_RepException E 
	JOIN Un_RepExceptionType T ON T.RepExceptionTypeID = E.RepExceptionTypeID AND T.RepExceptionTypeTypeID = 'COM'
	WHERE E.RepExceptionDate <= @dtActualTreatmentDate -- Exclus les exceptions ultérieures au traitement de commissions
	GROUP BY
		E.UnitID,
		E.RepID,
		E.RepLevelID
	-- Fin tables temporaire pour commission

	-- Tables temporaire pour boni d'affaire
	
	-- Table temporaire qui contient le nombre d'unités résiliés ultérieurement au traitement de commissions
	SELECT 
		UnitID, -- ID du groupe d'unités
		UnitQty = SUM(UnitQty) -- Somme d'unités résiliés
	INTO #UnitReductionNotApp
	FROM Un_UnitReduction UR 
	JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE ReductionDate > @dtActualTreatmentDate -- Unités résiliées ultérieurement seulement
		AND (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
	GROUP BY UnitID

	-- Table temporaire qui contient la somme des bonis d'affaires versés dans ce traitement ou dans les traitements précédents par 
	-- groupe d'unités, représentant, niveau et type de boni d'affaire.
	SELECT 
		RepID, -- ID du représentant
		UnitID, -- ID du groupe d'unités
		SumBusinessBonus = SUM(BusinessBonusAmount), -- Somme des bonis d'affaires versées dans ce traitement ou les traitements antérieurs
		RepLevelID, -- ID du niveau
		InsurTypeID -- Type de bonis d'affaire
	INTO #SumRepBusinessBonus
	FROM Un_RepBusinessBonus BB
	JOIN Un_RepTreatment T ON T.RepTreatmentID = BB.RepTreatmentID
	WHERE T.RepTreatmentID <= @RepTreatmentID -- Bonis d'affaires versés dans ce traitement ou dans les traitements précédents
	GROUP BY
		RepID,
		UnitID,
		InsurTypeID,
		RepLevelID

	-- Table temporaire qui contient la somme des bonis d'affaires versés dans ce traitement par groupe d'unités, représentant, niveau et
	-- type de boni d'affaire.
	SELECT 
		RepID, -- ID du représentant
		UnitID, -- ID du groupe d'unités
		PeriodBusinessBonus = SUM(BusinessBonusAmount), -- Somme des bonis d'affaires versées dans ce traitement
		RepLevelID, -- ID du niveau
		InsurTypeID -- Type de bonis d'affaire
	INTO #PeriodRepBusinessBonus
	FROM Un_RepBusinessBonus BB
	JOIN Un_RepTreatment T ON T.RepTreatmentID = BB.RepTreatmentID
	WHERE T.RepTreatmentID = @RepTreatmentID -- Bonis d'affaires versés dans ce traitement
	GROUP BY
		RepID,
		UnitID,
		InsurTypeID,
		RepLevelID

	-- Table temporaire contenant les plus aux pourcentages pour chaque type de supérieurs et ce pour chaque groupe d'unités.
	SELECT 
		U.UnitID, -- ID du groupe d'unités
		RBH.RepRoleID, -- ID du rôle
		RepBossPct = MAX(RBH.RepBossPct) -- Plus grand pourcentage
	INTO #MaxPctBoss
	FROM dbo.Un_Unit U
	JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL)
	JOIN Un_RepLevel BRL ON BRL.RepRoleID = RBH.RepRoleID
	JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = BRL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
	JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (U.InForceDate >= RBB.StartDate) AND (U.InForceDate <= RBB.EndDate OR RBB.EndDate IS NULL)
	GROUP BY
		U.UnitID,
		RBH.RepRoleID

	--	Table temporaire contenant la somme des exzceptions sur bonis d'affaires par groupe d'unités, représentant, niveau et type de type
	-- d'exception
	SELECT 
		E.UnitID, -- ID du groupe d'unités
		E.RepID, -- ID du représentant
		E.RepLevelID, -- ID du niveau
		T.RepExceptionTypeTypeID, -- ID du type de type d'exception
		RepExceptionAmount = SUM(E.RepExceptionAmount) -- Somme des exceptions 
	INTO #TRepExceptionBB
	FROM Un_RepException E 
	JOIN Un_RepExceptionType T ON T.RepExceptionTypeID = E.RepExceptionTypeID
	WHERE (T.RepExceptionTypeTypeID <> 'COM') -- Exclus les exceptions sur commissions
		AND (E.RepExceptionDate <= @dtActualTreatmentDate) -- Exclus les exceptions ultérieurs au traitement courant.
	GROUP BY
		E.UnitID,
		E.RepID,
		E.RepLevelID,
		T.RepExceptionTypeTypeID

	SELECT
		V.RepID, -- ID du représentant
		V.RepLevelID, -- ID du niveau
		V.UnitID, -- ID du groupe d'unités
		--V.UnitQty, -- Nombre d'unités
		TotalFee = 0.00, -- Total des frais cotisés (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		PeriodUnitQty = 0.00, -- Nombre d'unités vendu dans la période couverte par le traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		PeriodAdvance = 0.00, -- Somme des avances versés dans la période couverte par le traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		CoverdAdvance = 0.00, -- Somme de avances couvertes dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		CumAdvance = 0.00, -- Somme des avances versés pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		ServiceComm = 0.00, -- Somme des commissions de service versées et à verser pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		PeriodComm = 0.00, -- Somme des commissions de service versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		CummComm = 0.00, -- Somme des commissions de service versées pour ce groupe d'unités, ce représentant et ce niveau (Toujours 0 dans ce cas puisqu'on calcul uniquement pour les bonis d'affaires)
		BusinessBonus = SUM(V.BusinessBonus),  -- Somme des bonis d'affaires versées et à verser pour ce groupe d'unités, ce représentant et ce niveau
		PeriodBusinessBonus = SUM(V.PeriodBusinessBonus), -- Somme des bonis d'affaires versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau
		CummBusinessBonus = SUM(V.CummBusinessBonus) -- Somme des bonis d'affaires versées pour ce groupe d'unités, ce représentant et ce niveau
	INTO #BusinessBonus
	FROM (
		-- Sort la somme des bonis d'affaires versées et à verser, des bonis d'affaires versées dans la période couverte par le traitement
		-- de commissions et des bonis d'affaires versées. 
		-- Avant le UNION ALL ce sont les bonis d'affaires sur assurance souscripteur des représentants
		SELECT DISTINCT -- 2017-10-20
			/*U*/V.RepID, -- ID du représentant
			V.RepLevelID, -- ID du niveau
			U.UnitID, -- ID du groupe d'unités
			--UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END, -- Nombre d'unités
			BusinessBonus = -- Bonis d'affaire versées et à verser pour ce groupe d'unités, ce représentant et ce niveau
				CASE
					-- Modalité de paiement n'autorisant pas les bonis d'affaires
					WHEN M.BusinessBonusToPay = 0 THEN 0
					-- Aucune configuration de tombé de bonis pour ce groupe d'unités
					WHEN RBB.BusinessBonusNbrOfYears IS NULL THEN 0
					-- Cas ou l'assurance soucripteur n'est pas coché sur le groupe d'unités
					WHEN U.WantSubscriberInsurance = 0 THEN ISNULL(SBB.SumBusinessBonus,0)
					-- Cas où la délai d'expiration des bonis d'affaires est dépassé pour ce groupe d'unités
					WHEN DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) < @dtActualTreatmentDate THEN ISNULL(SBB.SumBusinessBonus,0) 
				ELSE (ISNULL(RBB.BusinessBonusNbrOfYears,0) * (CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQTY + ISNULL(RUNA.UnitQty,0) END) * ISNULL(RBB.BusinessBonusByUnit,0)) + ISNULL(RBBE.RepExceptionAmount,0)
				END,
			PeriodBusinessBonus = ISNULL(PBB.PeriodBusinessBonus,0), -- Bonis d'affaires versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau
			CummBusinessBonus = ISNULL(SBB.SumBusinessBonus,0) -- Bonis d'affaires versées pour ce groupe d'unités, ce représentant et ce niveau
		FROM (
			-- Sort la liste de tout les représentants qui sont illigible aux bonis d'affaires pour chaque groupe d'unités et niveau
			SELECT DISTINCT
				U.UnitID, -- ID du groupe d'unités
				RL.RepLevelID, -- ID du niveau
				U.RepID -- ID du représentant
			FROM dbo.Un_Unit U
			JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
			-----
			UNION
			-----
			SELECT DISTINCT
				B.UnitID, -- ID du groupe d'unités
				B.RepLevelID, -- ID du niveau
				B.RepID -- ID du représentant
			FROM #SumRepBusinessBonus B
			JOIN Un_RepLevel RL ON RL.RepLevelID = B.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement   
			WHERE B.InsurTypeID = 'ISB' -- Bonis d'affaire d'assurance souscripteur seulement 
			) V
		JOIN dbo.Un_Unit U ON V.UnitID = U.UnitID
		JOIN Un_Convention C on C.ConventionID = U.ConventionID
		JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtActualTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN Un_Modal M ON M.ModalID = U.ModalID 
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
		--LEFT JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND V.RepLevelID = RLH.RepLevelID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
		LEFT JOIN Un_RepLevel RL ON RL.RepLevelID = V.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement
		LEFT JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
		LEFT JOIN #SumRepBusinessBonus SBB ON SBB.UnitID = U.UnitID AND SBB.RepID = /*U*/V.RepID AND SBB.InsurTypeID = 'ISB' AND SBB.RepLevelID = V.RepLevelID
		LEFT JOIN #PeriodRepBusinessBonus PBB ON PBB.UnitID = U.UnitID AND PBB.RepID = /*U*/V.RepID AND PBB.InsurTypeID = 'ISB' AND PBB.RepLevelID = V.RepLevelID
		LEFT JOIN #TRepExceptionBB RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = /*U*/V.RepID AND RBBE.RepLevelID = RL.RepLevelID AND RBBE.RepExceptionTypeTypeID = 'ISB' 
		LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
		-- Le remboursement intégral complet ne doit pas avoir été fait, ou il doit être ultérieur au traitement de commissions
		--WHERE	( U.IntReimbDate IS NULL
		--		OR (U.IntReimbDate > @dtActualTreatmentDate)
		--		)
		WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- Le date du premier dépôt doit être antérieur ou égale au traitement de commissions
			AND (F.FirstDepositDate <= @dtActualTreatmentDate)
		---------	
		UNION ALL
		---------
		-- Avant le prochain UNION ALL ce sont les bonis d'affaires des représentants sur assurance bénéficiaire
		SELECT DISTINCT -- 2017-10-20
			/*U*/V.RepID, -- ID du représentant
			RL.RepLevelID, -- ID du niveau
			U.UnitID, -- ID du groupe d'unités
			--UnitQty = CASE WHEN C.PlanID = 4 THEN UI.UnitQty ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END, -- Nombre d'unités
			BusinessBonus = -- Bonis d'affaire versées et à verser pour ce groupe d'unités, ce représentant et ce niveau
				CASE 
					-- Modalité de paiement n'autorisant pas les bonis d'affaires
					WHEN M.BusinessBonusToPay = 0 THEN 0
					-- Aucune configuration de tombé de bonis pour ce groupe d'unités
					WHEN RBB.BusinessBonusNbrOfYears IS NULL THEN 0
					-- Tous les unités sont résiliés
					WHEN CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END = 0 THEN ISNULL(SBB.SumBusinessBonus,0)
					-- Cas où la délai d'expiration des bonis d'affaires est dépassé pour ce groupe d'unités
					WHEN DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) < @dtActualTreatmentDate THEN ISNULL(SBB.SumBusinessBonus,0) -- Expiration des bonis
				ELSE (ISNULL(RBB.BusinessBonusNbrOfYears,0) * ISNULL(RBB.BusinessBonusByUnit,0)) + ISNULL(RBBE.RepExceptionAmount,0) 
				END,
			PeriodBusinessBonus = ISNULL(PBB.PeriodBusinessBonus,0), -- Bonis d'affaires versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau
			CummBusinessBonus = ISNULL(SBB.SumBusinessBonus,0) -- Bonis d'affaires versées pour ce groupe d'unités, ce représentant et ce niveau
		FROM (
			-- Sort la liste de tout les représentants qui sont illigible aux bonis d'affaires pour chaque groupe d'unités, niveau et type
			-- de bonis d'affaire sur assurance bénéficiaire
			SELECT DISTINCT
				U.UnitID, -- ID du groupe d'unités
				RL.RepLevelID, -- ID du niveau
				U.RepID, -- ID du représentant
				RBB.InsurTypeID -- ID du type d'assurance bénéficiaire
			FROM dbo.Un_Unit U
			JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
			JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID AND BI.BenefInsurFaceValue IN (10000,20000)
			JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND (RLH.StartDate <= U.InForceDate) AND (RLH.EndDate IS NULL OR (RLH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepLevelID = RLH.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement   
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate)) 
														AND(	( RBB.InsurTypeID = 'IB1'
																AND BI.BenefInsurFaceValue = 10000
																)
															OR ( RBB.InsurTypeID = 'IB2'
																AND BI.BenefInsurFaceValue = 20000
																)
															)
			-----
			UNION
			-----
			SELECT DISTINCT
				B.UnitID, -- ID du groupe d'unités
				B.RepLevelID, -- ID du niveau
				B.RepID, -- ID du représentant
				B.InsurTypeID -- ID du type d'assurance bénéficiaire
			FROM #SumRepBusinessBonus B
			JOIN Un_RepLevel RL ON RL.RepLevelID = B.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement        
			WHERE B.InsurTypeID = 'IB1' -- Bonis d'affaire d'assurance bénéfiaire seulement 
				OR B.InsurTypeID = 'IB2'
			) V
		JOIN dbo.Un_Unit U ON V.UnitID = U.UnitID
		JOIN Un_Convention C on C.ConventionID = U.ConventionID
		JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtActualTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		--LEFT JOIN Un_RepLevelHist RLH ON RLH.RepID = U.RepID AND V.RepLevelID = RLH.RepLevelID AND (StartDate <= U.InForceDate) AND (EndDate IS NULL OR (EndDate >= U.InForceDate))
		LEFT JOIN Un_RepLevel RL ON RL.RepLevelID = V.RepLevelID AND RL.RepRoleID = 'REP' -- Représentant seulement
		LEFT JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate)) AND RBB.InsurTypeID = V.InsurTypeID
		LEFT JOIN #SumRepBusinessBonus SBB ON SBB.UnitID = U.UnitID AND SBB.RepID = /*U*/V.RepID AND V.InsurTypeID = SBB.InsurTypeID AND SBB.RepLevelID = RL.RepLevelID
		LEFT JOIN #PeriodRepBusinessBonus PBB ON PBB.UnitID = U.UnitID AND PBB.RepID = /*U*/V.RepID AND PBB.InsurTypeID = V.InsurTypeID AND PBB.RepLevelID = RL.RepLevelID
		LEFT JOIN #TRepExceptionBB RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = /*U*/V.RepID AND RBBE.RepLevelID = RL.RepLevelID AND RBB.InsurTypeID = RBBE.RepExceptionTypeTypeID
		LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
		-- Le remboursement intégral complet ne doit pas avoir été fait, ou il doit être ultérieur au traitement de commissions
		--WHERE	( U.IntReimbDate IS NULL
		--		OR (U.IntReimbDate > @dtActualTreatmentDate)
		--		)
        WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- Le date du premier dépôt doit être antérieur ou égale au traitement de commissions
			AND (F.FirstDepositDate <= @dtActualTreatmentDate)
		---------
		UNION ALL
		---------
		-- Avant le prochain UNION ALL ce sont les bonis d'affaires des supérieurs sur assurance souscripteur
		SELECT DISTINCT -- 2017-10-20
			RepID = RBH.BossID, -- ID du supérieur
			RL.RepLevelID, -- ID du niveau
			U.UnitID, -- ID du groupe d'unités
			--UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END, -- Nombre d'unités
			BusinessBonus = -- Bonis d'affaire versées et à verser pour ce groupe d'unités, ce représentant et ce niveau
				CASE 
					-- Modalité de paiement n'autorisant pas les bonis d'affaires
					WHEN M.BusinessBonusToPay = 0 THEN 0
					-- Aucune configuration de tombé de bonis pour ce groupe d'unités
					WHEN RBB.BusinessBonusNbrOfYears IS NULL THEN 0
					-- Cas ou l'assurance soucripteur n'est pas coché sur le groupe d'unités
					WHEN U.WantSubscriberInsurance = 0 THEN ISNULL(SBB.SumBusinessBonus,0)
					-- Cas où la délai d'expiration des bonis d'affaires est dépassé pour ce groupe d'unités
					WHEN DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) < @dtActualTreatmentDate THEN ISNULL(SBB.SumBusinessBonus,0) -- Expiration des bonis
				ELSE (RBB.BusinessBonusNbrOfYears * (CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQTY + ISNULL(RUNA.UnitQty,0) END) * RBB.BusinessBonusByUnit) + ISNULL(RBBE.RepExceptionAmount,0)
				END,
			PeriodBusinessBonus = ISNULL(PBB.PeriodBusinessBonus,0), -- Bonis d'affaires versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau
			CummBusinessBonus = ISNULL(SBB.SumBusinessBonus,0) -- Bonis d'affaires versées pour ce groupe d'unités, ce représentant et ce niveau
		FROM (
			-- Sort la liste de tout les supérieurs qui sont illigible aux bonis d'affaires pour chaque groupe d'unités et niveau
			SELECT DISTINCT
				U.UnitID, -- ID du groupe d'unités
				RL.RepLevelID, -- ID du niveau
				RepID = RBH.BossID -- ID du supérieur
			FROM dbo.Un_Unit U
			JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
			JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
			
			------- 2010-01-04 : Ajout de ce join pour corriger le calcul du Boni selon le niveau du supérieur
			JOIN Un_RepLevelHist BRLH ON BRLH.RepLevelID = RL.RepLevelID AND BRLH.RepID = RBH.BossID AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate OR BRLH.EndDate IS NULL)
			-------
			
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
			-----
			UNION
			-----
			SELECT DISTINCT
				B.UnitID, -- ID du groupe d'unités
				B.RepLevelID, -- ID du niveau
				B.RepID -- ID du supérieur
			FROM #SumRepBusinessBonus B
			JOIN Un_RepLevel RL ON RL.RepLevelID = B.RepLevelID AND (RL.RepRoleID <> 'REP') -- Supérieur seulement
			WHERE B.InsurTypeID = 'ISB' -- Bonis d'affaire d'assurance souscripteur seulement
			) V
		JOIN dbo.Un_Unit U ON V.UnitID = U.UnitID
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtActualTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN Un_Modal M ON M.ModalID = U.ModalID 
		LEFT JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
		LEFT JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
		LEFT JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND RL.RepLevelID = V.RepLevelID
		LEFT JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND RBB.InsurTypeID = 'ISB' AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
		LEFT JOIN #SumRepBusinessBonus SBB ON SBB.UnitID = U.UnitID AND SBB.RepID = V.RepID AND SBB.InsurTypeID = 'ISB' AND SBB.RepLevelID = V.RepLevelID
		LEFT JOIN #PeriodRepBusinessBonus PBB ON PBB.UnitID = U.UnitID AND PBB.RepID = V.RepID AND PBB.InsurTypeID = 'ISB' AND PBB.RepLevelID = V.RepLevelID
		LEFT JOIN #TRepExceptionBB RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = RBH.BossID AND RBBE.RepLevelID = RL.RepLevelID AND RBBE.RepExceptionTypeTypeID = 'ISB' 
		LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
		-- Le remboursement intégral complet ne doit pas avoir été fait, ou il doit être ultérieur au traitement de commissions
		--WHERE	(U.IntReimbDate IS NULL
		--		OR (U.IntReimbDate > @dtActualTreatmentDate)
		--		)
        WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- Le date du premier dépôt doit être antérieur ou égale au traitement de commissions
			AND (F.FirstDepositDate <= @dtActualTreatmentDate)
		---------
		UNION ALL
		---------
		-- Bonis d'affaires des supérieurs sur assurance bénéficiaire
		SELECT DISTINCT -- 2017-10-20
			RepID = RBH.BossID, -- ID du supérieur
			RL.RepLevelID, -- ID du niveau
			U.UnitID, -- ID du groupe d'unités
			--UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END, -- Nombre d'unités
			BusinessBonus = -- Bonis d'affaire versées et à verser pour ce groupe d'unités, ce représentant et ce niveau
				CASE 
					-- Modalité de paiement n'autorisant pas les bonis d'affaires
					WHEN M.BusinessBonusToPay = 0 THEN 0
					-- Aucune configuration de tombé de bonis pour ce groupe d'unités
					WHEN RBB.BusinessBonusNbrOfYears IS NULL THEN 0
					-- Tous les unités sont résiliés
					WHEN CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END = 0 THEN ISNULL(SBB.SumBusinessBonus,0)
					-- Cas où la délai d'expiration des bonis d'affaires est dépassé pour ce groupe d'unités
					WHEN DATEADD(YEAR, @iBusinessBonusLimit, U.InforceDate) < @dtActualTreatmentDate THEN ISNULL(SBB.SumBusinessBonus,0) -- Expiration des bonis
				ELSE (RBB.BusinessBonusNbrOfYears * RBB.BusinessBonusByUnit) + ISNULL(RBBE.RepExceptionAmount,0) 
				END,
			PeriodBusinessBonus = ISNULL(PBB.PeriodBusinessBonus,0), -- Bonis d'affaires versées dans la période du traitement de commissions pour ce groupe d'unités, ce représentant et ce niveau
			CummBusinessBonus = ISNULL(SBB.SumBusinessBonus,0) -- Bonis d'affaires versées pour ce groupe d'unités, ce représentant et ce niveau
		FROM (
			-- Sort la liste de tout les supérieurs qui sont illigible aux bonis d'affaires pour chaque groupe d'unités, niveau et type
			-- de bonis d'affaire sur assurance bénéficiaire
			SELECT DISTINCT
				U.UnitID, -- ID du groupe d'unités
				RL.RepLevelID, -- ID du niveau
				RepID = RBH.BossID, -- ID du supérieur
				RBB.InsurTypeID -- ID du type d'assurance bénéficiaire
			FROM dbo.Un_Unit U
			JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
			JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID AND BI.BenefInsurFaceValue IN (10000,20000)
			JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
			JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID
			JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RL.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate))
														AND ((RBB.InsurTypeID = 'IB1' AND BI.BenefInsurFaceValue = 10000)	OR (RBB.InsurTypeID = 'IB2' AND BI.BenefInsurFaceValue = 20000))
			-----
			UNION
			-----
			SELECT DISTINCT
				B.UnitID, -- ID du groupe d'unités
				B.RepLevelID, -- ID du niveau
				B.RepID, -- ID du supérieur
				B.InsurTypeID -- ID du type d'assurance bénéficiaire
			FROM #SumRepBusinessBonus B
			JOIN Un_RepLevel RL ON RL.RepLevelID = B.RepLevelID AND (RL.RepRoleID <> 'REP') -- Supérieur seulement       
			WHERE B.InsurTypeID = 'IB1' -- Bonis d'affaire d'assurance bénéficiaire seulement
				OR B.InsurTypeID = 'IB2'
			) V
		JOIN dbo.Un_Unit U ON V.UnitID = U.UnitID
		JOIN Un_Convention C on C.ConventionID = U.ConventionID
		JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
        LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtActualTreatmentDate) RIN ON RIN.UnitID = U.UnitID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN Un_Modal M ON M.ModalID = U.ModalID 
		LEFT JOIN #MaxPctBoss UMPct ON UMPct.UnitID = U.UNitID
		LEFT JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND UMPct.RepBossPct = RBH.RepBossPct AND UMPct.RepRoleID = RBH.RepRoleID AND (RBH.StartDate <= U.InForceDate) AND (RBH.EndDate IS NULL OR (RBH.EndDate >= U.InForceDate))
		LEFT JOIN Un_RepLevel RL ON RL.RepRoleID = RBH.RepRoleID AND RL.RepLevelID = V.RepLevelID
		LEFT JOIN Un_RepBusinessBonusCfg RBB ON RBB.RepRoleID = RBH.RepRoleID AND (RBB.StartDate <= U.InForceDate) AND (RBB.EndDate IS NULL OR (RBB.EndDate >= U.InForceDate)) AND RBB.InsurTypeID = V.InsurTypeID
		LEFT JOIN #SumRepBusinessBonus SBB ON SBB.UnitID = U.UnitID AND SBB.RepID = V.RepID AND V.InsurTypeID = SBB.InsurTypeID AND SBB.RepLevelID = V.RepLevelID
		LEFT JOIN #PeriodRepBusinessBonus PBB ON PBB.UnitID = U.UnitID AND PBB.RepID = V.RepID AND PBB.InsurTypeID = V.InsurTypeID AND PBB.RepLevelID = V.RepLevelID
		LEFT JOIN #TRepExceptionBB RBBE ON RBBE.UnitID = U.UnitID AND RBBE.RepID = RBH.BossID AND RBBE.RepLevelID = RL.RepLevelID AND RBB.InsurTypeID = RBBE.RepExceptionTypeTypeID
		LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = U.UnitID
		LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
		-- Le remboursement intégral complet ne doit pas avoir été fait, ou il doit être ultérieur au traitement de commissions
		--WHERE	( U.IntReimbDate IS NULL
		--		OR (U.IntReimbDate > @dtActualTreatmentDate)
		--		)
        WHERE ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
			-- Le date du premier dépôt doit être antérieur ou égale au traitement de commissions
			AND (F.FirstDepositDate <= @dtActualTreatmentDate)
		) V
	JOIN Un_Rep R ON R.RepID = V.RepID
	GROUP BY
		V.RepID,
		V.RepLevelID,
		V.UnitID,
		--V.UnitQty,
		R.BusinessEnd
	HAVING	( SUM(V.BusinessBonus) > SUM(V.CummBusinessBonus) -- Ne mets pas les groupes d'unités dont les bonis sont toutes payés et qui non pas eu de tombés dans ce traitement
				-- Le représentant doit être actif ou sa date de fin d'affaire doit être ultérieur au traitement de commissions
				AND( R.BusinessEnd IS NULL
					OR (R.BusinessEnd >= @dtActualTreatmentDate)
					)
				)
			OR SUM(V.PeriodBusinessBonus) <> 0 -- Inclus tous les groupes d'unités qui ont eu des tombés de bonis dans ce traitement

	-- Fin tables temporaire boni d'affaire

	-- Table temporaire contenant le total des frais cotisés par groupe d'unités
	SELECT 
		C.UnitID, -- ID du groupe d'unités
		TotalFee = ROUND(SUM(C.Fee), 2) -- Total des frais cotisés pour ce groupe d'unités
	INTO #TUnitTotalFee
	FROM Un_Cotisation C 
	JOIN Un_Oper O ON (O.OperID = C.OperID)
	WHERE (O.OperDate <= @dtActualTreatmentDate) -- Exclus les frais cotisés ultérieurement au traitement
		AND (OperTypeID <> 'RIN') -- Exclus les frais des remboursements intégraux
	GROUP BY C.UnitID      

	-- SELECT Final
	SELECT
		RepTreatmentID = @RepTreatmentID, -- ID du traitement de commissions
		RepTreatmentDate = @dtActualTreatmentDate, -- Date du traitement de commissions
		VC.RepID, -- ID du représentant
		VF.FirstDepositDate, -- Date de la première transaction du groupe d'unités
		U.InforceDate, -- Date d'entrée en vigueur du groupe d'unités
		Subscriber = HS.LastName + ', ' + HS.FirstName, -- Nom et prénom du souscripteur séparé par une virgule et une espace.
		C.ConventionNo, -- Numéro de convention
		RepName = H.LastName + ', ' + H.FirstName, -- Nom et prénom du représentant séparé par une virgule et une espace.
		R.RepCode, -- Code du représentant
		R.RepLicenseNo, -- Numéro de permis du représentant
		RO.RepRoleDesc, -- Rôle du représentant (Directeur, Représentant, etc.)
		LevelShortDesc = ISNULL(RL.LevelShortDesc, ''), -- Niveau du représentant (niveau 1, niveau 2, etc.)
		VC.PeriodUnitQty, -- Nombre d'unités vendus dans la période couverte par le traitement
		VC.UnitQty, -- Nombre d'unités du groupe d'unités à la date du traitement
		TotalFee = ISNULL(VU.TotalFee,0), -- Total des frais du groupe d'unités à la date du traitement
		VC.PeriodAdvance, -- Avance versés dans ce traitement
		VC.CoverdAdvance, -- Avance couverte dans ce traitement
		VC.CumAdvance, -- Avance non couverte aprés ce traitement
		VC.ServiceComm, -- Commission de service payés ou à payer pour cette vente
		VC.PeriodComm, -- Commission de service payés dans ce traitement
		VC.CummComm, -- Total des commission de service payés après ce traitement
		VC.FuturComm, -- Commissions de service à payer après ce traitement
		VC.BusinessBonus, -- Bonis d'affaires payés ou à payer pour cette vente
		VC.PeriodBusinessBonus, -- Bonis d'affaires payés dans ce traitement
		VC.CummBusinessBonus, -- Total des bonis d'affaires payés après ce traitement
		FuturBusinessBonus = VC.BusinessBonus - VC.CummBusinessBonus, -- Bonis d'affaires à payer après ce traitement
		SweepstakeBonusAjust = 0.00, -- Bonis, concours et ajustements
		PaidAmount = VC.PeriodComm + VC.PeriodBusinessBonus, -- Montant payé (Commissions de service + bonis d'affaires de la période)
		CommExpenses = VC.PeriodComm + VC.PeriodBusinessBonus + VC.CoverdAdvance, -- Dàpense de commissions (Commissions de service + bonis d'affaires + avance couverte de la période)
		Notes = -- Note indiquant s'il y a eu une résiliation, un transfert de frais ou encore un effet retourné pour ce groupe d'unités dans la période couverte par le traitement.
			CASE
				WHEN ISNULL(NRES.UnitID,0) <> 0 THEN 'RES'
				WHEN ISNULL(NTFR.UnitID,0) <> 0 THEN 'TFR'
				WHEN ISNULL(NNSF.UnitID,0) <> 0 THEN 'NSF'
			ELSE ' '
			END,
		U.UnitID,
		UnitRepID = U.RepID
	FROM (
		SELECT
			V.RepID, -- ID du représentant
			V.RepLevelID, -- ID du niveau du représentant
			V.UnitID, -- ID du groupe d'unités
			V.UnitQty, -- Nombre d'unités du groupe d'unités à la date du traitement
			TotalFee = SUM(V.TotalFee), -- Total des frais du groupe d'unités
			PeriodUnitQty = SUM(V.PeriodUnitQty), -- Nombre d'unités vendus dans la période couverte par le traitement 
			PeriodAdvance = SUM(V.PeriodAdvance), -- Avance versés dans ce traitement
			CoverdAdvance = SUM(V.CoveredAdvance), -- Avance couverte dans ce traitement
			CumAdvance = SUM(V.CumAdvance), -- Avance non couverte aprés ce traitement
			ServiceComm = SUM(V.ServiceComm), -- Commission de service payés ou à payer pour cette vente
			PeriodComm = SUM(V.PeriodComm), -- Commission de service payés dans ce traitement
			CummComm = SUM(V.CumComm), -- Total des commission de service payés après ce traitement
			FuturComm = SUM(V.FuturComm), -- Commissions de service à payer après ce traitement
			BusinessBonus = SUM(V.BusinessBonus), -- Bonis d'affaires payés ou à payer pour cette vente
			PeriodBusinessBonus = SUM(V.PeriodBusinessBonus), -- Bonis d'affaires payés dans ce traitement
			CummBusinessBonus = SUM(V.CummBusinessBonus) -- Total des bonis d'affaires payés après ce traitement
		FROM (
			SELECT
				V.RepID, -- ID du représentant
				V.RepLevelID, -- ID du niveau du représentant
				U.UnitID, -- ID du groupe d'unités
				UnitQty = CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END, -- Nombre d'unités du groupe d'unités à la date du traitement
				TotalFee = ISNULL(S.TotalFee,0), -- Total des frais du groupe d'unités 
				PeriodUnitQty = -- Nombre d'unités vendus dans la période couverte par le traitement 
					CASE
						WHEN ISNULL(VN.UnitID, 0) = 0 THEN 0.000
					ELSE CASE WHEN C.PlanID = 4 THEN ISNULL(UI.UnitQty,0) ELSE U.UnitQty + ISNULL(RUNA.UnitQty,0) END
					END,
				PeriodAdvance = ISNULL(P.PeriodAdvance,0), -- Avance versés dans ce traitement
				CoveredAdvance = ISNULL(P.CoveredAdvance,0), -- Avance couverte dans ce traitement
				CumAdvance = ISNULL(S.CumAdvance,0), -- Avance non couverte aprés ce traitement
				ServiceComm = -- Commission de service payés ou à payer pour cette vente
					CASE 
						-- Ajuste les commissions a recevoir au montant des commissions reçus pour les unités dont le premier dépôt n'a pas encore eu lieu
						WHEN F.FirstDepositDate > @dtActualTreatmentDate THEN ISNULL(S.CumComm,0)
						WHEN ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) THEN
							CASE
								WHEN ISNULL(UWC.UnitID, 0) <> 0 THEN 
									ROUND((ISNULL(VLB.TotalLevelCommission,0) + ISNULL(VLB.TotalLevelAdvance,0)) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0)
							ELSE 
								ROUND(ISNULL(VLB.TotalLevelCommission,0) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0)
							END
					-- Ajuste les commissions a recevoir au montant des commissions reçus pour les unités dont le remboursement intégral a eu lieu
					ELSE ISNULL(S.CumComm,0)
					END,
				PeriodComm = ISNULL(P.PeriodComm,0), -- Commission de service payés dans ce traitement
				CumComm = ISNULL(S.CumComm,0), -- Total des commission de service payés après ce traitement
				FuturComm = -- Commissions de service à payer après ce traitement
					CASE 
						-- Ne compte pas les commissions a venir des unités dont le premier dépôt n'a pas encore eu lieu
						WHEN F.FirstDepositDate > @dtActualTreatmentDate THEN 0
						-- Ne compte pas les commissions a venir des unités dont le remboursement intégral a eu lieu
						WHEN ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) THEN
							CASE
								WHEN VLB.TotalLevelCommission IS NULL THEN 0
							ELSE
								CASE 
									WHEN ISNULL(UWC.UnitID, 0) <> 0 THEN 
										ROUND((ISNULL(VLB.TotalLevelCommission,0) + ISNULL(VLB.TotalLevelAdvance,0)) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0) - ISNULL(S.CumComm,0)
								ELSE
									ROUND(ISNULL(VLB.TotalLevelCommission,0) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0) - ISNULL(S.CumComm,0)
								END
							END
					ELSE 0
					END,
				BusinessBonus = ISNULL(BB.BusinessBonus,0), -- Bonis d'affaires payés ou à payer pour cette vente
				PeriodBusinessBonus = ISNULL(BB.PeriodBusinessBonus,0), -- Bonis d'affaires payés dans ce traitement
				CummBusinessBonus = ISNULL(BB.CummBusinessBonus,0) -- Total des bonis d'affaires payés après ce traitement
			FROM dbo.Un_Unit U
			JOIN (
				-- Liste des différents groupes d'unités, représentant et niveaux qui doivent apparaître dans le rapport
				SELECT DISTINCT
					UnitID, -- ID du groupe d'unités
					RepID, -- ID du représentant
					RepLevelID -- ID du niveau
				FROM #TRepTotalLevelBracket
				-----
				UNION
				-----
				SELECT DISTINCT
					UnitID, -- ID du groupe d'unités
					RepID, -- ID du représentant
					RepLevelID -- ID du niveau
				FROM #SumRepCommission
				-----
				UNION
				-----
				SELECT DISTINCT
					UnitID, -- ID du groupe d'unités
					RepID, -- ID du représentant
					RepLevelID -- ID du niveau
				FROM #PeriodRepCommission
				-----
				UNION
				-----
				SELECT DISTINCT
					UnitID, -- ID du groupe d'unités
					RepID, -- ID du représentant
					RepLevelID -- ID du niveau
				FROM #BusinessBonus
				) V ON V.UnitID = U.UnitID
                        JOIN Un_Convention C ON C.ConventionID = U.ConventionID
			JOIN #TFirstDeposit F ON F.UnitID = U.UnitID
            LEFT JOIN dbo.fntCONV_ObtenirStatutRINUnite(NULL, NULL, @dtActualTreatmentDate) RIN ON RIN.UnitID = U.UnitID
			LEFT JOIN #TRepTotalLevelBracket VLB ON VLB.UnitID = V.UnitID AND VLB.RepID = V.RepID AND VLB.RepLevelID = V.RepLevelID
			LEFT JOIN #SumRepCommission S ON S.UnitID = V.UnitID AND S.RepID = V.RepID AND S.RepLevelID = V.RepLevelID
			LEFT JOIN #PeriodRepCommission P ON P.RepID = V.RepID AND P.UnitID = V.UnitID AND P.RepLevelID = V.RepLevelID
			LEFT JOIN #NewConvForPeriod VN ON VN.UnitID = V.UnitID
			LEFT JOIN #TRepExceptionComm E ON E.UnitID = VLB.UnitID AND E.RepID = VLB.RepID AND E.RepLevelID = VLB.RepLevelID
			LEFT JOIN #TRepUnitWithCommNotToPay UWC ON UWC.UnitID = V.UnitID
			LEFT JOIN #UnitReductionNotApp RUNA ON RUNA.UnitID = V.UnitID
			LEFT JOIN #BusinessBonus BB ON BB.UnitID = V.UnitID AND BB.RepID = V.RepID AND BB.RepLevelID = V.RepLevelID
			LEFT JOIN dbo.fntCONV_ObtenirNombreUniteIndividuelSelonFraisEnDate(@dtLastTreatmentDate, NULL) UI on UI.UnitID = U.UnitID
			WHERE	(	(	(ISNULL(UWC.UnitID, 0) <> 0) -- Groupe d'unités 
						AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
						AND (ROUND( (ISNULL(VLB.TotalLevelCommission,0) + ISNULL(VLB.TotalLevelAdvance,0)) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0) - ISNULL(S.CumComm,0) <> 0)
						) 
					OR ( ISNULL(UWC.UnitID, 0) = 0
						AND ISNULL(RIN.iStatut_RIN, 0) NOT IN (2, 3) -- Exclure les groupes d'unités avec un RIN partiel ou complet
						AND (ROUND( ISNULL(VLB.TotalLevelCommission,0) * (U.UnitQty + ISNULL(RUNA.UnitQty,0)) * ISNULL(VLB.RepPct,0) / 100, 2) + ISNULL(E.RepExceptionAmount, 0) - ISNULL(S.CumComm,0) <> 0)
						)
					OR (ISNULL(BB.UnitID,0) <> 0)
					OR (ISNULL(S.CumAdvance, 0) <> 0)
					OR (ISNULL(VN.UnitID, 0) <> 0) 
					OR (ISNULL(P.UnitID,0) <> 0)
					)
			) V
		GROUP BY
			V.RepID,
			V.RepLevelID,
			V.UnitID,
			V.UnitQty
		) VC
	JOIN dbo.Mo_Human H ON H.HumanID = VC.RepID
	JOIN Un_Rep R ON R.RepID = VC.RepID
	JOIN Un_RepLevel RL ON RL.RepLevelID = VC.RepLevelID
	JOIN Un_RepRole RO ON RO.RepRoleID = RL.RepRoleID
	JOIN dbo.Un_Unit U ON U.UnitID = VC.UnitID
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN #TFirstDeposit VF ON VF.UnitID = VC.UnitID
	LEFT JOIN #TUnitTotalFee VU ON VU.UnitID = VC.UnitID
	LEFT JOIN #TRepUnitWithCommNotToPay NTFR ON NTFR.UnitID = VC.UnitID AND (NTFR.Notes <> 0)
	LEFT JOIN #NotesRES NRES ON NRES.UnitID = VC.UnitID
	LEFT JOIN #NotesNSF NNSF ON NNSF.UnitID = VC.UnitID
	ORDER BY
		H.LastName,
		H.FirstName,
		VC.RepID,
		RO.RepRoleDesc,
		VF.FirstDepositDate,
		HS.LastName,
		HS.FirstName,
		C.ConventionNo
END