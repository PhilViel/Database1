/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_SumContByPlanAndQualifYear
Description         :	Rapport : Sommaire des contributions par régime et année de qualification
Valeurs de retours  :	Dataset :
									iPlanID				INTEGER		ID unique du régime
									vcPlanDesc			VARCHAR(75)	Description du régime	
									iYearQualif			INTEGER		Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
									iConventionCount	INTEGER		Nombre de convention
									fUnitQty				MONEY			Nombre d’unité
									fCotisation			MONEY			Montant d’épargne et d’épargne transitoire.
									fFee					MONEY			Montant des frais
									fSusbsInsur			MONEY			Montant de prime d'assurance souscripteur.
									fBenefInsur			MONEY			Montant de prime d'assurance bénéficiaire.
									fTaxOnInsur			MONEY			Taxes sur les primes d'assurances.
									fINM_OUT				MONEY			Intérêts sur cotisation payés au promoteur
									fINM_IN				MONEY			Intérêts sur cotisation reçus d’un promoteur
									fTotal			MONEY			fCotisation+fFee+fSubscInsur+fBenefInsur+fTaxOnInsur+fINM_OUT+
																		fINM_IN

Note                :	
ADX0001171	IA	2006-11-15	Bruno Lapointe		Création.
ADX0001367	IA	2007-04-24	Alain Quirion		Modification : Ajout du statut Fermé seulement
ADX0003058	UR	2007-09-11	Bruno Lapointe		Inclure les transferts de fonds (TRA)
				2010-04-16	Donald Huppé		GLPI 3157
				2010-10-06	Donald Huppé		Inclure l'état PRP dans le choix REE,TRA , afin de contourner le problème des alternance d'état causé par les procédure de É Dehais, 
												et aussi, MC Breton mentionne que ce serait bien de toute façon qu'il soit inclut
				2010-10-06	Donald Huppé		Ajout de  partout
				2011-05-20	Donald Huppé		glpi 5510 retirer les colones "Intérêts sur cotisation payés au promoteur" et Reçu
				2014-05-29	Donald Huppé		glpi 11584 : option d'inclure l'opération TFR ( @InclureTFR )
				2016-04-18	Donald Huppé		jira ti-2720 : Ajout du paramètre @Contribution
				
exec RP_UN_SumContByPlanAndQualifYear 0, '2015-01-01', '2015-12-31','REE,TRA',0,1, 'ALL'
				
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_SumContByPlanAndQualifYear] (	
	@bAll INTEGER, -- Champ booléen qui détermine si l'on veut le rapport sans période (1) ou pour une période saisie (0).
	@dtStart DATETIME, -- Date de début saisie
	@dtEnd DATETIME, -- Date de fin saisie
	@cReportFilter VARCHAR(20), -- Filtre sur les états de conventions :
									-- 	REE,TRA = REEE et Transitoire
									-- 	REE = REEE
									--	TRA = Transitoire
									--  FRM = Fermé
	@iColumnFilter INTEGER --	Filtre sur les colonnes associées à des comptes G/L du rapport :
									--		0 = Une des colonnes (pas de filtre)
									--		1 = Épargne /épargne transitoire
									--		2 = Frais
									--		3 = Ass. bénéficiaire
									--		4 = Ass. souscripteur
									--		5 = Taxes
									--		6 = Intérêts sur cotisation payés au promoteur
									--		7 = Intérêts sur cotisation reçus d’un promoteur
	,@InclureTFR	INT = 0
	,@Contribution	VARCHAR(10) = 'ALL' -- ALL, OLD, NEW
							)
AS
BEGIN

	--set @dtStart ='2016-01-01'
	--set @dtEnd ='2016-01-01'


	IF @cReportFilter <> 'TRA' AND @cReportFilter <> 'FRM'
		SET @cReportFilter = @cReportFilter + ',PRP,FRM'

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
				JOIN dbo.Un_Convention C  ON C.ConventionID = S.ConventionID
				WHERE S.StartDate <= @dtEnd -- État à la date de fin de la période
				GROUP BY S.ConventionID
				) T
			JOIN Un_ConventionConventionState CCS  ON T.ConventionID = CCS.ConventionID AND T.MaxDate = CCS.StartDate -- Retrouve l'état correspondant à la plus grande date par convention
			GROUP BY T.ConventionID
			) V
		JOIN Un_ConventionConventionState CCS  ON V.ConventionConventionStateID = CCS.ConventionConventionStateID
		WHERE CHARINDEX(CCS.ConventionStateID, @cReportFilter) > 0 -- L'état doit être un de ceux sélectionné dans le filtre

	CREATE TABLE #tCotisation (
		ConventionID INTEGER PRIMARY KEY,
		fCotisation MONEY NOT NULL,
		fFee MONEY NOT NULL,
		fSubscInsur MONEY NOT NULL,
		fBenefInsur MONEY NOT NULL,
		fTaxOnInsur MONEY NOT NULL	)

	IF @bAll = 1
		INSERT INTO #tCotisation
			SELECT
				U.ConventionID,
				fCotisation = SUM(Ct.Cotisation),
				fFee = SUM(Ct.Fee),
				fSubscInsur = SUM(Ct.SubscInsur),
				fBenefInsur = SUM(Ct.BenefInsur),
				fTaxOnInsur = SUM(Ct.TaxOnInsur)
			FROM dbo.Un_Unit U 
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			WHERE Ct.OperID NOT IN (
				SELECT O.OperID
				FROM Un_Oper O 
				JOIN Un_OperType OT  ON OT.OperTypeID = O.OperTypeID
				WHERE O.OperDate > @dtEnd -- Opération en dehors de la période sélectionnée.
					OR	( OT.TotalZero = 1 -- Inclus les opérations de type BEC ou TFR
						AND O.OperTypeID <> 'TRA' -- Exclus les TRA
						)
				)
				
			GROUP BY
				U.ConventionID
			HAVING SUM(Ct.Cotisation) <> 0 -- Au moins un des montants doit être différent de 0.00$
				OR SUM(Ct.Fee) <> 0
				OR SUM(Ct.SubscInsur) <> 0
				OR SUM(Ct.BenefInsur) <> 0
				OR SUM(Ct.TaxOnInsur) <> 0
	ELSE
		INSERT INTO #tCotisation
			SELECT
				U.ConventionID,
				fCotisation = SUM(Ct.Cotisation),
				fFee = SUM(Ct.Fee),
				fSubscInsur = SUM(Ct.SubscInsur),
				fBenefInsur = SUM(Ct.BenefInsur),
				fTaxOnInsur = SUM(Ct.TaxOnInsur)
			FROM dbo.Un_Unit U 
			JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
			WHERE 
				(
					Ct.OperID IN 
						(
						SELECT O.OperID
						FROM Un_Oper O 
						JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
						WHERE O.OperDate BETWEEN @dtStart AND @dtEnd -- Opération de la période sélectionnée.
							AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
								OR O.OperTypeID = 'TRA' -- Inclus les TRA
								)
						)
				
					OR 
						(
						@InclureTFR = 1
						AND
						Ct.OperID IN (
							SELECT O.OperID
							FROM Un_Oper O 
							WHERE O.OperDate BETWEEN @dtStart AND @dtEnd -- Opération de la période sélectionnée.
								AND O.OperTypeID = 'TFR'
							)
						)						
					)
			AND
				(	 
					 @Contribution = 'ALL'
				 OR (@Contribution = 'OLD' AND U.dtFirstDeposit < @dtStart)
				 OR (@Contribution = 'NEW' AND U.dtFirstDeposit >= @dtStart)
				)





				
			GROUP BY
				U.ConventionID
			HAVING SUM(Ct.Cotisation) <> 0 -- Au moins un des montants doit être différent de 0.00$
				OR SUM(Ct.Fee) <> 0
				OR SUM(Ct.SubscInsur) <> 0
				OR SUM(Ct.BenefInsur) <> 0
				OR SUM(Ct.TaxOnInsur) <> 0

/*
	CREATE TABLE #tConventionOper (
		ConventionID INTEGER PRIMARY KEY,
		fINM_OUT MONEY NOT NULL,
		fINM_IN MONEY NOT NULL)

	INSERT INTO #tConventionOper
		SELECT
			V.ConventionID,
			fINM_OUT = SUM(V.fINM_OUT),
			fINM_IN = SUM(V.fINM_IN)
		FROM (
			SELECT -- Montant d'intérêt sur cotisations reçu d'un promoteur (Int. TIN des opérations TIN)
				CO.ConventionID,
				fINM_OUT = 0,
				fINM_IN = SUM(CO.ConventionOperAmount)
			FROM Un_ConventionOper CO 
			JOIN Un_Oper O  ON O.OperID = CO.OperID
			WHERE CO.ConventionOperTypeID = 'ITR' -- Int. TIN
				AND O.OperDate BETWEEN @dtStart AND @dtEnd -- Dans la période
				AND O.OperTypeID = 'TIN' -- Opérations TIN
			GROUP BY CO.ConventionID
			---------
			UNION ALL
			---------
			SELECT -- Montant d'intérêt sur cotisations payé à un promoteur (Int. TIN et Int. Capital des opérations OUT)
				CO.ConventionID,
				fINM_OUT = SUM(CO.ConventionOperAmount),
				fINM_IN = 0
			FROM Un_ConventionOper CO 
			JOIN Un_Oper O  ON O.OperID = CO.OperID
			WHERE CO.ConventionOperTypeID IN ('INM', 'ITR') -- Int. capital et Int. TIN
				AND O.OperDate BETWEEN @dtStart AND @dtEnd -- Dans la période
				AND O.OperTypeID = 'OUT' -- Opérations OUT
			GROUP BY CO.ConventionID
			) V
		GROUP BY V.ConventionID
		HAVING SUM(V.fINM_OUT) <> 0 -- Au moins un des montants doit être différent de 0.00$
			OR SUM(V.fINM_IN) <> 0 
*/
	SELECT
		PlanID, -- ID unique du régime
		PlanDesc, -- Description du régime
		YearQualif, -- Année de qualification
		iConventionCount = COUNT(ConventionNo), -- Nombre de convention
		fUnitQty = SUM(fUnitQty), -- Nombre d’unité
		fCotisation = SUM(fCotisation), -- SCEE
		fFee = SUM(fFee), -- SCEE+
		fSubscInsur = SUM(fSubscInsur), -- BEC
		fBenefInsur = SUM(fBenefInsur), -- Intérêts créditeurs - SCEE
		fTaxOnInsur = SUM(fTaxOnInsur), -- SCEE et SCEE+ reçue (TIN)
		--fINM_OUT = SUM(fINM_OUT), -- BEC reçu (TIN)
		--fINM_IN = SUM(fINM_IN), -- SCEE et SCEE+ payée (OUT)
		fTotal = SUM(fTotal) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
	FROM (
		SELECT
			P.OrderOfPlanInReport,
			P.PlanID, -- ID unique du régime
			P.PlanDesc, -- Description du régime
			YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
			C.ConventionNo, -- Numéro de convention
			vcSubscriber = S.LastName+', '+S.FirstName, -- Nom, prénom du souscripteur
			fUnitQty = U.UnitQty, -- Nombre d’unité
			fCotisation = ISNULL(Ct.fCotisation,0), -- Montant d’épargne et d’épargne transitoire.
			fFee = ISNULL(Ct.fFee,0), -- Montant des frais
			fSubscInsur = ISNULL(Ct.fSubscInsur,0), -- Montant de prime d'assurance souscripteur.
			fBenefInsur = ISNULL(Ct.fBenefInsur,0), -- Montant de prime d'assurance bénéficiaire.
			fTaxOnInsur = ISNULL(Ct.fTaxOnInsur,0), -- Taxes sur les primes d'assurances.
			--fINM_OUT = ISNULL(CO.fINM_OUT,0), -- Intérêts sur cotisation payés au promoteur
			--fINM_IN = ISNULL(CO.fINM_IN,0), -- Intérêts sur cotisation reçus d’un promoteur
			fTotal = 
				ISNULL(Ct.fCotisation,0) + -- Montant d’épargne et d’épargne transitoire.
				ISNULL(Ct.fFee,0) + -- Montant des frais
				ISNULL(Ct.fSubscInsur,0) + -- Montant de prime d'assurance souscripteur.
				ISNULL(Ct.fBenefInsur,0) + -- Montant de prime d'assurance bénéficiaire.
				ISNULL(Ct.fTaxOnInsur,0)  -- Taxes sur les primes d'assurances.
				--+ ISNULL(CO.fINM_OUT,0)  -- Intérêts sur cotisation payés au promoteur
				--+ ISNULL(CO.fINM_IN,0) -- Intérêts sur cotisation reçus d’un promoteur
		FROM #tConventionState CS
		JOIN dbo.Un_Convention C  ON C.ConventionID = CS.ConventionID
		JOIN Un_Plan P  ON C.PlanID = P.PlanID
		LEFT JOIN Un_ConventionYearQualif Y  ON Y.ConventionID = C.ConventionID AND @dtEnd BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnd+1)
		JOIN dbo.Mo_Human S  ON S.HumanID = C.SubscriberID
		LEFT JOIN ( -- GLPI 3157 faire un LEFT JOIN plutot qu'un JOIN
			SELECT
				CS.ConventionID,
				UnitQty = SUM(U.UnitQty+ISNULL(UR.UnitQty, 0))
			FROM #tConventionState CS
			JOIN dbo.Un_Unit U  ON U.ConventionID = CS.ConventionID
			LEFT JOIN (
		 		SELECT
					UnitID,
					UnitQty = SUM(UnitQty)
				FROM Un_UnitReduction 
				WHERE ReductionDate > @dtEnd -- Résiliation d'unités faites après la date de fin de période.
				GROUP BY UnitID
				) UR ON UR.UnitID = U.UnitID
			--WHERE U.dtFirstDeposit <= @dtEnd -- GLPI 3157 dtFirstDeposit peut être null dans le cas d'un RIO -- Et cette clause ne sert à rien selon PLS
			GROUP BY CS.ConventionID
			) U ON U.ConventionID = C.ConventionID
		LEFT JOIN #tCotisation Ct ON Ct.ConventionID = C.ConventionID
		--LEFT JOIN #tConventionOper CO ON CO.ConventionID = C.ConventionID
		WHERE ( Ct.ConventionID IS NOT NULL
				--OR CO.ConventionID IS NOT NULL
				)
		) V
	GROUP BY
		V.PlanID, -- ID unique du régime
		V.PlanDesc, -- Description du régime
		V.YearQualif, -- Année de qualification
		V.OrderOfPlanInReport
	HAVING @iColumnFilter = 0
		OR	( @iColumnFilter = 1	 -- 1 = Épargne /épargne transitoire
			AND SUM(fCotisation) <> 0
			)
		OR ( @iColumnFilter = 2 -- 2 = Frais
			AND SUM(fFee) <> 0
			)
		OR ( @iColumnFilter = 3 -- 3 = Ass. bénéficiaire
			AND SUM(fBenefInsur) <> 0
			)
		OR ( @iColumnFilter = 4 -- 4 = Ass. souscripteur
			AND SUM(fSubscInsur) <> 0
			)
		OR ( @iColumnFilter = 5 -- 5 = Taxes
			AND SUM(fTaxOnInsur) <> 0
			)
		--OR ( @iColumnFilter = 6 -- 6 = Intérêts sur cotisation payés au promoteur
		--	AND SUM(fINM_OUT) <> 0
		--	)
		--OR ( @iColumnFilter = 7 -- 7 = Intérêts sur cotisation reçus d’un promoteur
		--	AND SUM(fINM_IN) <> 0
		--	)
	ORDER BY
		V.OrderOfPlanInReport,
		V.YearQualif
END


