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
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_SumCESPBySubscriberAccount
Description         :	Rapport : Sommaire du PCEE par compte souscripteur.
Valeurs de retours  :	Dataset :
									iPlanID					INTEGER			ID unique du régime
									vcPlanDesc				VARCHAR(75)		Description du régime	
									iYearQualif				INTEGER			Année de qualification aux bourses de la convention. C'est 
																				l'année à laquelle le bénéficiaire de la convention pourra 
																				toucher sa première bourse pour cette convention s'il 
																				rempli les conditions.
									ConventionNo			VARCHAR(15)		Numéro de convention
									vcSubscriber			VARCHAR(87)		Nom, prénom du souscripteur
									fUnitQty				MONEY			Nombre d’unités
									fCESG					MONEY			SCEE
									fACESG					MONEY			SCEE+
									fCLB					MONEY			BEC
									fINS					MONEY			Intérêts créditeurs - SCEE
									fCESG_ACESG_TIN			MONEY			SCEE et SCEE+ reçue (TIN)
									fCLB_TIN				MONEY			BEC reçu (TIN)
									fCESG_ACESG_OUT			MONEY			SCEE et SCEE+ payée (OUT)
									fCLB_OUT				MONEY			BEC payé (OUT)
									fCESPInt_TIN			MONEY			Intérêts PCEE TIN reçus
									fCESPInt_OUT			MONEY			Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts 
																				payés (OUT)
									fCESPOfScholarship		MONEY			SCEE, SCEE+, BEC et Intérêts versés en bourse.
									fTotal					MONEY			fCESG+fACESG+fCLB+fINS+fCESG_ACESG_TIN+fCLB_TIN+
																			fCESG_ACESG_OUT+fCLB_OUT+fCESPInt_TIN+fCESPInt_OUT+
																				CESPOfScholarship

Note                :	ADX0001170	IA	2006-11-14	Bruno Lapointe			Création
						ADX0002426	BR	2007-05-22	Alain Quirion			Modification : Un_CESP au lieu de Un_CESP900
										2009-12-10	Jean-François Gauthier	Modification des INT pour IN+/IN-
										2009-12-17	Jean-François Gauthier	Intégration modif. Rémy
										2010-01-15	Donald Huppé			remplacer fnOPER_ObtenirTypesOperationConvCategorie par fnOPER_ObtenirTypesOperationCategorie
										2010-02-18	Donald Huppé			Ajout de RIO et TIO
																			Reduire le nombre de select causé par @bAll
										2010-04-16	Donald Huppé			GLPI 3157	
										2010-04-23	Donald Huppé			correction d'un bug sur le calcul du rendement TIO (voir -- corrigé le 2010-04-23)	
										2010-12-10	Donald Huppé			Ajout des ARI dans le calcul du rendement SCEE (fINS)	
										2011-02-24	Donald Huppé			GLPI 4422 : Ajout des 3 nouveaus critères de recherche : @cConventionno, @iYearQualif, @iPlanID																
                                        2018-11-12  Pierre-Luc Simard       N'est plus utilisée

exec RP_UN_SumCESPBySubscriberAccount_New 0, '2011-01-01', '2011-02-24', 0, '1096661', 2011, 0
exec RP_UN_SumCESPBySubscriberAccount_New 0, '1950-01-01', '2009-12-31', 0, NULL, NULL, 0

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SumCESPBySubscriberAccount_New] (	
	@bAll INTEGER, -- Champ booléen qui détermine si l'on veut le rapport sans période (1) ou pour une période saisie (0).
	@dtStart DATETIME, -- Date de début saisie
	@dtEnd DATETIME, -- Date de fin saisie
	@iColumnFilter INTEGER ,--	Filtre sur les colonnes associées à des comptes G/L du rapport :
									--		0 = Une des colonnes (pas de filtre)
									--		1 = SCEE
									--		2 = SCEE+
									--		3 = BEC
									--		4 = Intérêts créditeurs - SCEE
									--		5 = SCEE et SCEE+ reçu (TIN)
									--		6 = BEC reçu (TIN)
									--		7 = SCEE et SCEE+ payée (OUT)
									--		8 = BEC payé (OUT)
									--		9 = Intérêts SCEE, SCEE+ et BEC reçus (TIN)
									--		10 = Intérêts SCEE, SCEE+ et BEC payés (OUT)
									--		11 = SCEE, SCEE+, BEC et Intérêts versés en bourse.
	@cConventionno varchar(15) = NULL,
	@iYearQualif INT = NULL,
	@iPlanID varchar(75) = 0
	)
AS
BEGIN

SELECT 1/0

/*
	DECLARE @vcOPER_RENDEMENT_POSITIF_NEGATIF VARCHAR(200)

	SET @vcOPER_RENDEMENT_POSITIF_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_RENDEMENT_POSITIF_NEGATIF')

	IF @bAll = 1
	BEGIN
		-- Si on sort pour tous, alors on met comme date de début 01/01/1950 et date de fin la date du jour.
		SELECT
			@dtStart = '1950-01-01',
			@dtEnd = dbo.FN_CRQ_DateNoTime(GETDATE())
	END
	SET @dtEnd = DATEADD(s, -1, DATEADD(DAY, 1, @dtEnd))

	-- Applique le filtre des états de conventions.
	CREATE TABLE #tConventionState (
		ConventionID INTEGER PRIMARY KEY )

	INSERT INTO #tConventionState
		SELECT 
			V.ConventionID
		FROM ( -- Retourne le plus grand ID pour la plus grande date de début d'un état par convention
			SELECT 		
				T.ConventionID,
				ConventionConventionStateID = MAX(CCS.ConventionConventionStateID)
			FROM (-- Retourne la plus grande date de début d'un état par convention
				SELECT 
					S.ConventionID,
					MaxDate = MAX(S.StartDate)
				FROM Un_ConventionConventionState S
				JOIN dbo.Un_Convention C ON C.ConventionID = S.ConventionID
				LEFT JOIN Un_ConventionYearQualif Y (READUNCOMMITTED) ON Y.ConventionID = C.ConventionID AND @dtEnd BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnd+1)
				WHERE 
					S.StartDate <= @dtEnd -- État à la date de fin de la période
					AND (@cConventionno is NULL OR C.ConventionNO = @cConventionno)
					AND (@iYearQualif  is NULL OR ISNULL(Y.YearQualif,C.YearQualif) = @iYearQualif)
					AND (@iPlanID = 0 OR C.PlanID = @iPlanID) 
				
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			GROUP BY T.ConventionID
			) V
		JOIN Un_ConventionConventionState CCS ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
		WHERE CCS.ConventionStateID = 'REE' -- L'état REEE
				OR CCS.ConventionStateID = 'FRM' -- Fermé compte comme REE
				OR CCS.ConventionStateID = 'TRA' -- Transitoire
				OR CCS.ConventionStateID = 'PRP' -- En proposition

	CREATE TABLE #tOperTIO(
		OperID INT PRIMARY KEY,
		iTioId integer
		)

	INSERT INTO #tOperTIO
		SELECT 
			o.OperID,
			TioTIN.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioTIN on TioTIN.iTINOperID = o.operid
		WHERE	(@bAll = 1 and OperDate <= @dtEnd )
			OR
				(@bAll = 0 and OperDate BETWEEN @dtStart AND @dtEnd )
		UNION

		SELECT 
			o.OperID,
			TioOUT.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioOUT on TioOUT.iOUTOperID = o.operid
		WHERE	(@bAll = 1 and OperDate <= @dtEnd )
			OR
				(@bAll = 0 and OperDate BETWEEN @dtStart AND @dtEnd )

	CREATE TABLE #tCESP (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL,
		fCESG_ACESG_TIN MONEY NOT NULL,
		fCLB_TIN MONEY NOT NULL,
		fCESG_ACESG_OUT MONEY NOT NULL,
		fCLB_OUT MONEY NOT NULL,
		fCESPOfScholarship MONEY NOT NULL,
		fCESG_ACESG_CLB_RIO MONEY NOT NULL,
		fCESG_ACESG_CLB_TIO MONEY NOT NULL)

		-- Subventions(PCEE) par convention
		INSERT INTO #tCESP
		
		select
			ConventionID,
			fCESG = SUM(fCESG),
			fACESG = SUM(fACESG),
			fCLB = SUM(fCLB),
			fCESG_ACESG_TIN = SUM(fCESG_ACESG_TIN),
			fCLB_TIN = SUM(fCLB_TIN),
			fCESG_ACESG_OUT = SUM(fCESG_ACESG_OUT),
			fCLB_OUT = SUM(fCLB_OUT),
			fCESPOfScholarship = SUM(fCESPOfScholarship),
			fCESG_ACESG_CLB_RIO = SUM(fCESG_ACESG_CLB_RIO),
			fCESG_ACESG_CLB_TIO = SUM(fCESG_ACESG_CLB_TIO)
			
			FROM (
		
			SELECT
				CE.ConventionID,
				fCESG = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCESG ELSE 0 END),
				fACESG = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fACESG ELSE 0 END),
				fCLB = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCLB ELSE 0 END),
				fCESG_ACESG_TIN = SUM(CASE WHEN O.OperTypeID = 'TIN' THEN CE.fCESG + CE.fACESG ELSE 0 END),
				fCLB_TIN = SUM(CASE WHEN O.OperTypeID = 'TIN' THEN CE.fCLB ELSE 0 END),
				fCESG_ACESG_OUT = SUM(CASE WHEN O.OperTypeID = 'OUT' THEN CE.fCESG + CE.fACESG ELSE 0 END),
				fCLB_OUT = SUM(CASE WHEN O.OperTypeID = 'OUT' THEN CE.fCLB ELSE 0 END),
				fCESPOfScholarship = SUM(CASE WHEN O.OperTypeID = 'PAE' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_RIO = SUM(CASE WHEN O.OperTypeID = 'RIO' THEN CE.fCESG + CE.fACESG + CE.fCLB ELSE 0 END),
				fCESG_ACESG_CLB_TIO = 0
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID
			LEFT JOIN #tOperTIO TIO ON O.OperID = TIO.OperID
			WHERE O.OperTypeID IN ('OUT', 'TIN', 'PAE', 'SUB', 'RIO')
				AND (
					(@bAll = 1 and O.OperDate <= @dtEnd)
					OR
					(@bAll = 0 AND O.OperDate BETWEEN @dtStart AND @dtEnd)
					)
				AND TIO.OperID IS NULL -- exclure les TIO
			GROUP BY
				CE.ConventionID
		
			UNION ALL
			
			-- LES TIO
			SELECT
				CE.ConventionID,
				fCESG = 0,
				fACESG = 0,
				fCLB = 0,
				fCESG_ACESG_TIN = 0,
				fCLB_TIN = 0,
				fCESG_ACESG_OUT = 0,
				fCLB_OUT = 0,
				fCESPOfScholarship = 0,
				fCESG_ACESG_CLB_RIO = 0,
				fCESG_ACESG_CLB_TIO = SUM(CE.fCESG + CE.fACESG + CE.fCLB)
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID
			JOIN #tOperTIO TIO ON O.OperID = TIO.OperID
			GROUP BY
				CE.ConventionID
			) Y
			GROUP BY ConventionID
			HAVING 
				SUM(fCESG) <> 0
				OR SUM(fACESG) <> 0
				OR SUM(fCLB) <> 0
				OR SUM(fCESG_ACESG_TIN) <> 0
				OR SUM(fCLB_TIN) <> 0
				OR SUM(fCESG_ACESG_OUT) <> 0
				OR SUM(fCLB_OUT) <> 0
				OR SUM(fCESPOfScholarship) <> 0
				OR SUM(fCESG_ACESG_CLB_RIO) <> 0
				OR SUM(fCESG_ACESG_CLB_TIO) <> 0

	CREATE TABLE #tConventionOper (
		ConventionID INTEGER PRIMARY KEY,
		fINS MONEY NOT NULL,
		fCESPInt_TIN MONEY NOT NULL,
		fCESPInt_OUT MONEY NOT NULL,
		fCESPOfScholarship MONEY NOT NULL,
		fCESPInt_RIO MONEY NOT NULL,
		fCESPInt_TIO MONEY NOT NULL)

		INSERT INTO #tConventionOper
			SELECT
				V.ConventionID,
				fINS = SUM(V.fINS),
				fCESPInt_TIN = SUM(V.fCESPInt_TIN),
				fCESPInt_OUT = SUM(V.fCESPInt_OUT),
				fCESPOfScholarship = SUM(V.fCESPOfScholarship),
				fCESPInt_RIO = SUM(fCESPInt_RIO),
				fCESPInt_TIO = SUM(fCESPInt_TIO)
			FROM (
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = CO.ConventionOperAmount,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE (CHARINDEX(Un_Oper.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF+ ',ARI') > 0)
						AND (
							(@bAll = 1 and OperDate <= @dtEnd)
							OR
							(@bAll = 0 AND OperDate BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = 0,
					fCESPInt_TIN = CO.ConventionOperAmount,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID = 'IST' -- Int. TIN
					AND CO.OperID IN (
						SELECT OP.OperID
						FROM Un_Oper OP
						LEFT JOIN #tOperTIO TIO on op.operid = TIO.operid
						WHERE OperTypeID = 'TIN' -- Opérations TIN
						AND (
							(@bAll = 1 and OperDate <= @dtEnd)
							OR
							(@bAll = 0 AND OperDate BETWEEN @dtStart AND @dtEnd)
							)
						AND TIO.operid IS NULL
						)
				---------
				UNION ALL
				---------
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = CO.ConventionOperAmount,
					fCESPOfScholarship = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OP.OperID
						FROM Un_Oper op
						LEFT JOIN #tOperTIO tio on op.operid = TIO.operid
						WHERE OperTypeID = 'OUT' -- Opérations OUT
						AND (
							(@bAll = 1 and OperDate <= @dtEnd)
							OR
							(@bAll = 0 AND OperDate BETWEEN @dtStart AND @dtEnd)
							)
						AND TIO.operid IS NULL
						)
				---------
				UNION ALL
				---------
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = CO.ConventionOperAmount,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = 0
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'PAE' -- Opérations PAE
						AND (
							(@bAll = 1 and OperDate <= @dtEnd)
							OR
							(@bAll = 0 AND OperDate BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_RIO = CO.ConventionOperAmount,
					fCESPInt_TIO = 0

				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OperID
						FROM Un_Oper
						WHERE OperTypeID = 'RIO' -- Opérations PAE
						AND (
							(@bAll = 1 and OperDate <= @dtEnd)
							OR
							(@bAll = 0 AND OperDate BETWEEN @dtStart AND @dtEnd)
							)
						)
				---------
				UNION ALL
				---------
				SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
					CO.ConventionID,
					fINS = 0,
					fCESPInt_TIN = 0,
					fCESPInt_OUT = 0,
					fCESPOfScholarship = 0,
					fCESPInt_RIO = 0,
					fCESPInt_TIO = CO.ConventionOperAmount
				FROM Un_ConventionOper CO
				WHERE CO.ConventionOperTypeID IN ('IBC', 'INS', 'IS+', 'IST') -- Int. TIN
					AND CO.OperID IN (
						SELECT OperID
						FROM #tOperTIO
						)

				) V
			GROUP BY V.ConventionID
			HAVING SUM(V.fINS) <> 0 -- Au moins un des montants doit être différent de 0.00$
				OR SUM(V.fCESPInt_TIN) <> 0
				OR SUM(V.fCESPInt_OUT) <> 0
				OR SUM(V.fCESPOfScholarship) <> 0
				OR SUM(fCESPInt_RIO) <> 0
				OR SUM(fCESPInt_TIO) <> 0 -- corrigé le 2010-04-23

	SELECT
		P.PlanID, -- ID unique du régime
		PlanDesc = case when P.PlanId = 12 then 'Reeeflex 2010' else P.PlanDesc end, -- Description du régime
		YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
		C.ConventionNo, -- Numéro de convention
		vcSubscriber = S.LastName+', '+S.FirstName, -- Nom, prénom du souscripteur
		fUnitQty = U.UnitQty, -- Nombre d’unité
		fCESG = ISNULL(CESP.fCESG,0), -- SCEE
		fACESG = ISNULL(CESP.fACESG,0), -- SCEE+
		fCLB = ISNULL(CESP.fCLB,0), -- BEC
		fINS = ISNULL(CO.fINS,0), -- Intérêts créditeurs - SCEE
		fCESG_ACESG_TIN = ISNULL(CESP.fCESG_ACESG_TIN,0), -- SCEE et SCEE+ reçue (TIN)
		fCLB_TIN = ISNULL(CESP.fCLB_TIN,0), -- BEC reçu (TIN)
		fCESG_ACESG_OUT = ISNULL(CESP.fCESG_ACESG_OUT,0), -- SCEE et SCEE+ payée (OUT)
		fCLB_OUT = ISNULL(CESP.fCLB_OUT,0), -- BEC payé (OUT)
		fCESPInt_TIN = ISNULL(CO.fCESPInt_TIN,0), -- Intérêts PCEE TIN reçus
		fCESPInt_OUT = ISNULL(CO.fCESPInt_OUT,0), -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
		fCESPOfScholarship = ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0), -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
		fCESG_ACESG_CLB_RIO = ISNULL(CESP.fCESG_ACESG_CLB_RIO,0), -- SCEE, SCEE+ et BEC (RIO)
		fCESPInt_RIO = ISNULL(CO.fCESPInt_RIO,0), -- Intérêts SCEE, SCEE+ et BEC (RIO)
		fCESG_ACESG_CLB_TIO = ISNULL(CESP.fCESG_ACESG_CLB_TIO,0), -- SCEE, SCEE+ et BEC (TIO)
		fCESPInt_TIO = ISNULL(CO.fCESPInt_TIO,0), -- Intérêts SCEE, SCEE+ et BEC (TIO)
		SoldeNetGarantie =	
			ISNULL(CESP.fCESG,0) + 
			ISNULL(CESP.fACESG,0) + 
			ISNULL(CESP.fCLB,0) + 
			ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
			ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
			ISNULL(CESP.fCESG_ACESG_TIN,0) + 
			ISNULL(CESP.fCESG_ACESG_OUT,0) + 
			ISNULL(CESP.fCESPOfScholarship,0) + 
			ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + 
			ISNULL(CESP.fCESG_ACESG_CLB_TIO,0),
		SoldeNetRendement = 
			ISNULL(CO.fINS,0) + 
			ISNULL(CO.fCESPInt_TIN,0) + 
			ISNULL(CO.fCESPInt_OUT,0) + 
			ISNULL(CO.fCESPOfScholarship,0) + 
			ISNULL(CO.fCESPInt_RIO,0) + 
			ISNULL(CO.fCESPInt_TIO,0),
		fTotal = 
			ISNULL(CESP.fCESG,0) + -- SCEE
			ISNULL(CESP.fACESG,0) + -- SCEE+
			ISNULL(CESP.fCLB,0) + -- BEC
			ISNULL(CO.fINS,0) + -- Intérêts créditeurs - SCEE
			ISNULL(CESP.fCESG_ACESG_TIN,0) + -- SCEE et SCEE+ reçue (TIN)
			ISNULL(CESP.fCLB_TIN,0) + -- BEC reçu (TIN)
			ISNULL(CESP.fCESG_ACESG_OUT,0) + -- SCEE et SCEE+ payée (OUT)
			ISNULL(CESP.fCLB_OUT,0) + -- BEC payé (OUT)
			ISNULL(CO.fCESPInt_TIN,0) + -- Intérêts PCEE TIN reçus
			ISNULL(CO.fCESPInt_OUT,0) + -- Intérêts SCEE, intérêts SCEE+, intérêts BEC et intérêts payés (OUT)
			ISNULL(CESP.fCESG_ACESG_CLB_RIO,0) + -- SCEE, SCEE+ et BEC (RIO)
			ISNULL(CO.fCESPInt_RIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (RIO)
			ISNULL(CESP.fCESG_ACESG_CLB_TIO,0) + -- SCEE, SCEE+ et BEC (TIO)
			ISNULL(CO.fCESPInt_TIO,0) +  -- Intérêts SCEE, SCEE+ et BEC (TIO)
			ISNULL(CESP.fCESPOfScholarship,0)+ISNULL(CO.fCESPOfScholarship,0) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
	FROM #tConventionState CS
	JOIN dbo.Un_Convention C ON CS.ConventionID = C.ConventionID
	JOIN Un_Plan P ON C.PlanID = P.PlanID
	LEFT JOIN Un_ConventionYearQualif Y ON Y.ConventionID = C.ConventionID AND @dtEnd BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnd+1)
	JOIN dbo.Mo_Human S ON S.HumanID = C.SubscriberID
	LEFT JOIN ( -- GLPI 3157 faire un LEFT JOIN plutot qu'un JOIN
		SELECT
			CS.ConventionID,
			UnitQty = SUM(U.UnitQty+ISNULL(UR.UnitQty, 0))
		FROM #tConventionState CS
		JOIN dbo.Un_Unit U ON U.ConventionID = CS.ConventionID
		LEFT JOIN (
			-- Va chercher les unités résiliés après la date de fin de la période. Il faut additionner ces unités à ceux actuel des
			-- groupes d'unités pour connaître le nombre d'unités à la date de fin de période
	 		SELECT
				UnitID,
				UnitQty = SUM(UnitQty)
			FROM Un_UnitReduction
			WHERE ReductionDate > @dtEnd -- Résiliation d'unités faites après la date de fin de période.
			GROUP BY UnitID
			) UR ON UR.UnitID = U.UnitID
		-- WHERE U.dtFirstDeposit <= @dtEnd -- GLPI 3157 dtFirstDeposit peut être null dans le cas d'un RIO -- Et cette clause ne sert à rien selon PLS
		GROUP BY CS.ConventionID
		) U ON U.ConventionID = C.ConventionID
	LEFT JOIN #tCESP CESP ON CESP.ConventionID = C.ConventionID
	LEFT JOIN #tConventionOper CO ON CO.ConventionID = C.ConventionID
	WHERE ( CESP.ConventionID IS NOT NULL
			OR CO.ConventionID IS NOT NULL
			)
		AND(	@iColumnFilter = 0	-- 0 = Une des colonnes (pas de filtre)
			OR	( @iColumnFilter = 1 -- 1 = SCEE
				AND ISNULL(CESP.fCESG,0) <> 0
				)
			OR ( @iColumnFilter = 2 -- 2 = SCEE+
				AND ISNULL(CESP.fACESG,0) <> 0
				)
			OR ( @iColumnFilter = 3 -- 3 = BEC
				AND ISNULL(CESP.fCLB,0) <> 0
				)
			OR ( @iColumnFilter = 4 -- 4 = Intérêts créditeurs - SCEE
				AND ISNULL(CO.fINS,0) <> 0
				)
			OR ( @iColumnFilter = 5 -- 5 = SCEE et SCEE+ reçu (TIN)
				AND ISNULL(CESP.fCESG_ACESG_TIN,0) <> 0
				)
			OR ( @iColumnFilter = 6 -- 6 = BEC reçu (TIN)
				AND ISNULL(CESP.fCLB_TIN,0) <> 0
				)
			OR ( @iColumnFilter = 7 -- 7 = SCEE et SCEE+ payée (OUT)
				AND ISNULL(CESP.fCESG_ACESG_OUT,0) <> 0
				)
			OR ( @iColumnFilter = 8 -- 8 = BEC payé (OUT)
				AND ISNULL(CESP.fCLB_OUT,0) <> 0
				)
			OR ( @iColumnFilter = 9 -- 9 = Intérêts SCEE, SCEE+ et BEC reçus (TIN)
				AND ISNULL(CO.fCESPInt_TIN,0) <> 0
				)
			OR ( @iColumnFilter = 10 -- 10 = Intérêts SCEE, SCEE+ et BEC payés (OUT)
				AND ISNULL(CO.fCESPInt_OUT,0) <> 0
				)
			OR ( @iColumnFilter = 11 -- 11 = SCEE, SCEE+, BEC et Intérêts versés en bourse.
				AND ISNULL(CESP.fCESPOfScholarship,0) + ISNULL(CO.fCESPOfScholarship,0) <> 0
				)
			)
	ORDER BY
		P.OrderOfPlanInReport,
		ISNULL(Y.YearQualif,C.YearQualif),
		C.ConventionNo
*/
END