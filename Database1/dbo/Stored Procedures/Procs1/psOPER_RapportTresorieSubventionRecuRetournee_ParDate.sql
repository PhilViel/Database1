/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Nom                 :	psOPER_RapportTresorieSubventionRecuRetournee_ParDate
Description         :	Rapport : TRÉSORIE DES SubventionRecuRetournee
Valeurs de retours  :	Dataset :
								
Note                :	

	2018-10-16	Donald Huppé		Création.
				
exec psOPER_RapportTresorieSubventionRecuRetournee_ParDate 
	@dtStartDateFROM = '2014-01-01',
	@dtStartDate = '2018-09-01', 
	@dtEndDate = '2018-09-30'

exec psOPER_RapportTresorieSubventionRecuRetournee_ParDate 
	@dtStartDate = NULL, 
	@dtEndDate = NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportTresorieSubventionRecuRetournee_ParDate] (	
	@dtStartDateFROM DATETIME = '2014-01-01',
	@dtStartDate DATETIME,
	@dtEndDate DATETIME
				)

AS
BEGIN

--SET ARITHABORT ON


	IF @dtStartDate IS NOT NULL AND DATEDIFF(DAY,@dtStartDate,@dtEndDate) > 31
		BEGIN
		SELECT

		DateDu = CAST(@dtStartDateFROM AS DATE),
		DateAuDu = CAST(@dtStartDate AS DATE),
		DateAuAu = CAST(@dtEndDate AS DATE),
		LaDate = '',
		TypeConv = 'Période trop longue',

		SUB_TOTAL = 0

		RETURN
		END



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


	CREATE TABLE #Jour (LaDate DATETIME) 

	DECLARE 
		@Ladate datetime

	
	SET	@Ladate = @dtStartDate

	-- Loader la table de date de la période
	WHILE @Ladate <= @dtEndDate
		BEGIN
		INSERT INTO #Jour VALUES (@Ladate)
		SET @Ladate = DATEADD(DAY,1, @Ladate)
		END



	------------ Liste de base
	CREATE TABLE #TC (TypeConvention VARCHAR (50))
	INSERT INTO #TC VALUES ('Individuel RIO')
	INSERT INTO #TC VALUES ('Individuel Autre')

	SELECT 
		j.LaDate,
		TypeConvention
	INTO #Liste
	FROM #Jour j
	JOIN #TC TC ON 1 =1
	ORDER BY j.LaDate,TypeConvention
	----------------------------------------------



	SELECT 
		DateDu = CAST(@dtStartDateFROM AS DATE),
		DateAuDu = CAST(@dtStartDate AS DATE),
		DateAuAu = CAST(@dtEndDate AS DATE),
		LaDate,
		TypeConv,
		SUB_TOTAL = SUM(V.SCEE) + SUM(V.IQEE)
	FROM (
			SELECT
				j.LaDate,
				TypeConv = CASE 
						WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'Individuel RIO' 
						WHEN rr.iID_Regroupement_Regime = 3 THEN 'Individuel Autre'
						end,
				SCEE = SUM(CE.fCESG + CE.fACESG + CE.fCLB),
				IQEE = 0
			FROM Un_CESP CE
			JOIN Un_Oper O ON O.OperID = CE.OperID
			JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN tblCONV_RegroupementsRegimes rr ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
			JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
			LEFT JOIN (
				SELECT DISTINCT tri.iID_Convention_Destination from tblOPER_OperationsRIO tri where tri.bRIO_QuiAnnule = 0 and tri.OperTypeID = 'TRI'
				)t ON t.iID_Convention_Destination = c.ConventionID
			LEFT JOIN (
				SELECT DISTINCT rio.iID_Convention_Destination, c.ConventionNo
				from tblOPER_OperationsRIO rio
				JOIN dbo.Un_Convention c ON rio.iID_Convention_Destination = c.ConventionID
				WHERE OperTypeID IN ( 'RIO','RIM')
				and rio.bRIO_QuiAnnule = 0
					) r on c.conventionid = r.iID_Convention_Destination

			WHERE 
				(	
					O.OperTypeID = 'SUB' 
				OR 
					(t.iID_Convention_Destination IS NOT NULL AND O.OperTypeID = 'TRI')
				)
				AND P.PlanTypeID = 'IND'
				--AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN '2014-01-01' AND '2018-09-30'
			GROUP BY j.LaDate,
						CASE 
						WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'Individuel RIO' 
						WHEN rr.iID_Regroupement_Regime = 3 THEN 'Individuel Autre'
						end

			UNION ALL

			SELECT 
				j.LaDate,
				TypeConv = CASE 
						WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'Individuel RIO' 
						WHEN rr.iID_Regroupement_Regime = 3 THEN 'Individuel Autre'
						end,
				SCEE = 0,
				IQEE = SUM(co.ConventionOperAmount)
			
			FROM Un_ConventionOper co
			JOIN dbo.Un_Convention c ON c.ConventionID = co.ConventionID
			JOIN Un_Plan P ON P.PlanID = C.PlanID
			JOIN tblCONV_RegroupementsRegimes rr ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
			JOIN Un_Oper o ON co.OperID = o.OperID
			JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
			LEFT join (
				SELECT DISTINCT tri.iID_Convention_Destination from tblOPER_OperationsRIO tri where tri.bRIO_QuiAnnule = 0 and tri.OperTypeID = 'TRI'
				)t ON t.iID_Convention_Destination = co.ConventionID
			LEFT JOIN (
				SELECT DISTINCT rio.iID_Convention_Destination, c.ConventionNo
				from tblOPER_OperationsRIO rio
				JOIN dbo.Un_Convention c ON rio.iID_Convention_Destination = c.ConventionID
				WHERE OperTypeID IN ( 'RIO','RIM')
				and rio.bRIO_QuiAnnule = 0
					) r on c.conventionid = r.iID_Convention_Destination
			WHERE 
				(	
					O.OperTypeID = 'IQE' 
				OR 
					(t.iID_Convention_Destination IS NOT NULL AND O.OperTypeID = 'TRI')
				)
				AND P.PlanTypeID = 'IND'
				and co.ConventionOperTypeID IN ('CBQ','MMQ')
				--AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10) BETWEEN '2014-01-01' AND '2018-09-30'
			GROUP BY j.LaDate,
						CASE 
						WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'Individuel RIO' 
						WHEN rr.iID_Regroupement_Regime = 3 THEN 'Individuel Autre'
						end

		)V
	GROUP BY LaDate,TypeConv
	ORDER BY LaDate,TypeConv

END