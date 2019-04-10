/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportSoldeEpargneFraisPourConvAvecRIEstimeDepasse
Description         :	Rapport : Sommaire des cotisations selon l'échéance de la date de RI estimé
Valeurs de retours  :	Dataset :
								
Note                :	

2014-08-25	Donald Huppé		Création.
				
exec psOPER_RapportSoldeEpargneFraisPourConvAvecRIEstimeDepasse '2014-08-25', '2014-08-25', 'REE,TRA'
		drop proc psOPER_RapportSoldeEpargneFraisPourConvAvecRIEstimeDepasse		
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportSoldeEpargneFraisPourConvAvecRIEstimeDepasse] (	
	
	@dtRIAvantLe datetime,
	@dtEnDatedu DATETIME, -- Date de début saisie
	@cReportFilter VARCHAR(20) -- Filtre sur les états de conventions :
									-- 	REE,TRA = REEE et Transitoire
									-- 	REE = REEE
									--	TRA = Transitoire
									--  FRM = Fermé
							)
AS
BEGIN

set ARITHABORT on

	IF @cReportFilter <> 'TRA' AND @cReportFilter <> 'FRM'
		SET @cReportFilter = @cReportFilter + ',PRP,FRM'

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
				WHERE S.StartDate <= @dtEnDatedu -- État à la date de fin de la période
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
				Ct.OperID IN 
					(
					SELECT O.OperID
					FROM Un_Oper O 
					JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
					WHERE O.OperDate <= @dtEnDatedu --BETWEEN @dtStart AND @dtEnd -- Opération de la période sélectionnée.
						AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
							OR O.OperTypeID = 'TRA' -- Inclus les TRA
							)
					)
				
					OR (
					Ct.OperID IN (
						SELECT O.OperID
						FROM Un_Oper O 
						JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
						WHERE O.OperDate <= @dtEnDatedu --BETWEEN @dtStart AND @dtEnd -- Opération de la période sélectionnée.
							AND O.OperTypeID = 'TFR'
						)
					)				
				
			GROUP BY
				U.ConventionID
			HAVING SUM(Ct.Cotisation) <> 0 -- Au moins un des montants doit être différent de 0.00$
				OR SUM(Ct.Fee) <> 0
				OR SUM(Ct.SubscInsur) <> 0
				OR SUM(Ct.BenefInsur) <> 0
				OR SUM(Ct.TaxOnInsur) <> 0

	SELECT
		RIAvantLe,
		PlanID, -- ID unique du régime
		PlanDesc, -- Description du régime
		RegroupementRegime,
		YearQualif, -- Année de qualification
		iConventionCount = COUNT(ConventionNo), -- Nombre de convention
		fUnitQty = SUM(fUnitQty), -- Nombre d’unité
		fCotisation = SUM(fCotisation), -- SCEE
		fFee = SUM(fFee), -- SCEE+
		fSubscInsur = SUM(fSubscInsur), -- BEC
		fBenefInsur = SUM(fBenefInsur), -- Intérêts créditeurs - SCEE
		fTaxOnInsur = SUM(fTaxOnInsur), -- SCEE et SCEE+ reçue (TIN)
		fTotal = SUM(fTotal) -- SCEE, SCEE+, BEC et Intérêts versés en bourse.
		,OrderOfPlanInReport
	FROM (
		SELECT
			RIAvantLe = case when ri.IntEstimatedReimbDate is not null then 'Après échéance' else 'Avant échéance' end,
			P.OrderOfPlanInReport,
			P.PlanID, -- ID unique du régime
			P.PlanDesc, -- Description du régime
			RegroupementRegime = rr.vcDescription,
			YearQualif = ISNULL(Y.YearQualif,C.YearQualif), -- Année de qualification aux bourses de la convention. C'est l'année à laquelle le bénéficiaire de la convention pourra toucher sa première bourse pour cette convention s'il rempli les conditions.
			C.ConventionNo, -- Numéro de convention
			vcSubscriber = S.LastName+', '+S.FirstName, -- Nom, prénom du souscripteur
			fUnitQty = U.UnitQty, -- Nombre d’unité
			fCotisation = ISNULL(Ct.fCotisation,0), -- Montant d’épargne et d’épargne transitoire.
			fFee = ISNULL(Ct.fFee,0), -- Montant des frais
			fSubscInsur = ISNULL(Ct.fSubscInsur,0), -- Montant de prime d'assurance souscripteur.
			fBenefInsur = ISNULL(Ct.fBenefInsur,0), -- Montant de prime d'assurance bénéficiaire.
			fTaxOnInsur = ISNULL(Ct.fTaxOnInsur,0), -- Taxes sur les primes d'assurances.
			fTotal = 
				ISNULL(Ct.fCotisation,0) + -- Montant d’épargne et d’épargne transitoire.
				ISNULL(Ct.fFee,0) + -- Montant des frais
				ISNULL(Ct.fSubscInsur,0) + -- Montant de prime d'assurance souscripteur.
				ISNULL(Ct.fBenefInsur,0) + -- Montant de prime d'assurance bénéficiaire.
				ISNULL(Ct.fTaxOnInsur,0)  -- Taxes sur les primes d'assurances.

		FROM #tConventionState CS
		JOIN dbo.Un_Convention C  ON C.ConventionID = CS.ConventionID
		JOIN Un_Plan P  ON C.PlanID = P.PlanID and p.PlanID <> 4
		join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
		JOIN #tCotisation Ct ON Ct.ConventionID = C.ConventionID
		LEFT JOIN Un_ConventionYearQualif Y  ON Y.ConventionID = C.ConventionID AND @dtEnDatedu BETWEEN Y.EffectDate AND ISNULL(Y.TerminatedDate,@dtEnDatedu+1)
		JOIN dbo.Mo_Human S  ON S.HumanID = C.SubscriberID
		LEFT JOIN (
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
				WHERE ReductionDate > @dtEnDatedu -- Résiliation d'unités faites après la date de fin de période.
				GROUP BY UnitID
				) UR ON UR.UnitID = U.UnitID

			GROUP BY CS.ConventionID
			) U ON U.ConventionID = C.ConventionID
		left join (
			select
				c.ConventionID,
				IntEstimatedReimbDate = min(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, /*NULL*/ U.IntReimbDateAdjust))
			FROM dbo.Un_Convention c
			join Un_Plan p on c.PlanID = p.PlanID
			JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
			join Un_Modal m on u.ModalID = m.ModalID
			group by c.ConventionID
			HAVING min(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge,  U.IntReimbDateAdjust)) < @dtRIAvantLe
			) RI on ri.ConventionID = c.ConventionID
		) V
	GROUP BY
		v.RIAvantLe,
		V.PlanID, -- ID unique du régime
		V.PlanDesc, -- Description du régime
		RegroupementRegime,
		V.YearQualif, -- Année de qualification
		V.OrderOfPlanInReport

	ORDER BY
		V.OrderOfPlanInReport,
		V.YearQualif

set ARITHABORT OFF

END


