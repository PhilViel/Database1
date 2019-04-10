/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportTresorieCotisation_ParDate
Description         :	Rapport : TRÉSORIE DES COTISATIONS PAR DATE
Valeurs de retours  :	Dataset :
								
Note                :	

2018-10-04	Donald Huppé		Création.
				
exec psOPER_RapportTresorieCotisation_ParDate '2018-09-01', '2018-10-30'
exec psOPER_RapportTresorieCotisation_ParDate null, null
		drop proc psOPER_RapportSoldeEpargneFraisPourConvAvecRIEstimeDepasse		
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportTresorieCotisation_ParDate] (	
	
	@dtStartDate datetime,
	@dtEndDate DATETIME -- Date de début saisie
	--,@cReportFilter VARCHAR(20) -- Filtre sur les états de conventions :
									-- 	REE,TRA = REEE et Transitoire
									-- 	REE = REEE
									--	TRA = Transitoire
									--  FRM = Fermé
							)
AS
BEGIN

SET ARITHABORT ON


	IF @dtStartDate IS NULL
		BEGIN
		-- DÉBUT du mois dernier
		SET @dtStartDate = DATEADD(mm, DATEDIFF(mm,0,getdate()) -1, 0) 
		-- FIN du mois dernier
		SET @dtEndDate = DATEADD(DAY,-1,
							DATEADD(MONTH,1,
								 DATEADD(mm, DATEDIFF(mm,0,getdate()) -1, 0) 
								 )
								)
		END

	IF DATEDIFF(DAY,@dtStartDate,@dtEndDate) > 31
		BEGIN
		SELECT
			DateDu = CAST(@dtStartDate AS DATE),
			DateAu = CAST(@dtEndDate AS DATE),
			LaDate = '9999-12-31',
			Regime = 'Période trop longue',
			Echeance = '',
			Cotisations = 0,
			Frais = 0
		RETURN
		END

	CREATE TABLE #Jour (LaDate DATETIME)

	DECLARE 
		@Ladate datetime

	
	SET	@Ladate = @dtStartDate



	WHILE @Ladate <= @dtEndDate
		BEGIN
		INSERT INTO #Jour VALUES (@Ladate)
		SET @Ladate = DATEADD(DAY,1, @Ladate)
		END

/*
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
*/

	SELECT
		c.ConventionID,
		IntEstimatedReimbDate = min(dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, /*NULL*/ U.IntReimbDateAdjust))
	INTO #RI
	FROM dbo.Un_Convention c
	--JOIN #tConventionState CS on CS.ConventionID = c.ConventionID
	JOIN Un_Plan p on c.PlanID = p.PlanID
	JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
	JOIN Un_Modal m on m.ModalID = u.ModalID
	GROUP BY c.ConventionID

	SELECT
		DateDu = CAST(@dtStartDate AS DATE),
		DateAu = CAST(@dtEndDate AS DATE),
		LaDate = CAST(j.LaDate AS DATE),
		Regime = rr.vcDescription,
		Echeance = case when ri.IntEstimatedReimbDate is not null then 'Après échéance' else 'Avant échéance' end,
		Cotisations = SUM(Ct.Cotisation),
		Frais = SUM(Ct.Fee)
		--fSubscInsur = SUM(Ct.SubscInsur),
		--fBenefInsur = SUM(Ct.BenefInsur),
		--fTaxOnInsur = SUM(Ct.TaxOnInsur)
	FROM dbo.Un_Unit U 
	JOIN Un_Convention c on c.ConventionID = u.ConventionID
	JOIN Un_Plan P  ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O on O.OperID = Ct.OperID
	JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
	JOIN #Jour j on j.LaDate >= O.OperDate
	LEFT JOIN #RI RI on RI.ConventionID = U.ConventionID AND RI.IntEstimatedReimbDate < j.LaDate
	WHERE 1=1
		AND p.PlanID <> 4
		AND(
				( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
				OR O.OperTypeID = 'TRA' -- Inclus les TRA
				)
			OR  
				O.OperTypeID = 'TFR'
			)
			
				
	GROUP BY
		j.LaDate,
		case when ri.IntEstimatedReimbDate is not null then 'Après échéance' else 'Avant échéance' end,
		rr.vcDescription
	ORDER BY j.LaDate,case when ri.IntEstimatedReimbDate is not null then 'Après échéance' else 'Avant échéance' end,rr.vcDescription


set ARITHABORT OFF

END


