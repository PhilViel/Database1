/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Nom                 :	psOPER_RapportTresorieSubvention_ParDate
Description         :	Rapport : TRÉSORIE DES SUBVENTION PAR DATE
Valeurs de retours  :	Dataset :
								
Note                :	

	2018-10-03	Donald Huppé		Création.
	2018-10-17	Donald Huppé		Correction : remplacer 2012-04-20 par @dtStartDateFROM dans section SCEE
				
exec psOPER_RapportTresorieSubvention_ParDate 
	@dtStartDate = '2018-09-01', 
	@dtEndDate = '2018-09-30'

exec psOPER_RapportTresorieSubvention_ParDate 
	@dtStartDate = NULL, 
	@dtEndDate = NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportTresorieSubvention_ParDate] (	
	
	@dtStartDateFROM DATETIME = '2012-04-20',
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
			LaDate = NULL,
			Regime = 'Periode trop longue',
			SCEE = 0,
			SCEEPlus = 0,
			BEC = 0,
			IQEE = 0,
			IQEEPlus = 0
		RETURN
		END


IF @dtStartDateFROM IS NULL
	SET @dtStartDateFROM = '2012-04-20'

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

	-- Liste de base
	SELECT 
		j.LaDate,
		Regime = rr.vcDescription	
	INTO #Liste
	FROM #Jour j
	JOIN tblCONV_RegroupementsRegimes RR ON 1 =1
	ORDER BY j.LaDate,rr.vcDescription

	-- IQEE
	SELECT 
		j.LaDate,
		Regime = rr.vcDescription,
		IQEE = SUM(CASE WHEN CO.ConventionOperTypeID = 'CBQ' THEN CO.ConventionOperAmount ELSE 0 END),
		IQEEPlus = SUM(CASE WHEN CO.ConventionOperTypeID = 'MMQ' THEN CO.ConventionOperAmount ELSE 0 END)
	INTO #IQEE 
	FROM Un_Convention C
	JOIN Un_Plan P  ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on P.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
	WHERE O.OperTypeID = 'IQE' 
		 AND CO.ConventionOperTypeID IN ('CBQ','MMQ')
	GROUP BY
		j.LaDate,rr.vcDescription
	ORDER BY j.LaDate,rr.vcDescription

	--SCEE
	SELECT
		j.LaDate,
		Regime = rr.vcDescription,
		SCEE = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCESG ELSE 0 END),
		SCEEPlus = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fACESG ELSE 0 END),
		BEC = SUM(CASE WHEN O.OperTypeID = 'SUB' THEN CE.fCLB ELSE 0 END)
	INTO #SCEE 
	FROM Un_Convention C
	JOIN Un_Plan P ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_CESP CE on CE.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CE.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
	WHERE O.OperTypeID = 'SUB'
	GROUP BY
		j.LaDate,rr.vcDescription
	ORDER BY j.LaDate,rr.vcDescription


	-- résultat
	SELECT 
		DateDu = CAST(@dtStartDateFROM AS DATE),
		DateAuDu = CAST(@dtStartDate AS DATE),
		DateAuAu = CAST(@dtEndDate AS DATE),
		LaDate = cast(L.LaDate AS DATE),
		L.Regime,
		SCEE = ISNULL(S.SCEE,0),
		SCEEPlus = ISNULL(S.SCEEPlus,0),
		BEC = ISNULL(S.BEC,0),
		IQEE = ISNULL(Q.IQEE,0),
		IQEEPlus = ISNULL(Q.IQEEPlus,0)
	FROM #Liste L
	LEFT JOIN #SCEE	S ON S.LaDate = L.LaDate AND S.Regime = L.Regime
	LEFT JOIN #IQEE	Q ON Q.LaDate = L.LaDate AND Q.Regime = L.Regime


--SET ARITHABORT OFF
END