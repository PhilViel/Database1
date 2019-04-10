/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Nom                 :	psOPER_RapportTresorieSubvention_ParDate
Description         :	Rapport : TRÉSORIE DES SUBVENTION PAR DATE
Valeurs de retours  :	Dataset :
								
Note                :	

	2018-10-03	Donald Huppé		Création.
	2018-10-17	Donald Huppé		Correction : remplacer 2012-04-20 par @dtStartDateFROM dans section SCEE
	2018-10-22	Donald Huppé		Correction du join sur OT pour le SCEE
				
exec psOPER_RapportTresorieTIO_ParDate 
	@dtStartDateFROM = '2014-01-01',
	@dtStartDate = '2018-07-01', 
	@dtEndDate = '2018-07-07'


*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportTresorieTIO_ParDate] (	
	
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
			LaDate = NULL,
			Regime = 'Periode trop longue',
			SCEE_et_SCEEPlus_et_BEC = 0,
			IQEE_et_IQEEPlus = 0
		RETURN
		END


IF @dtStartDateFROM IS NULL
	SET @dtStartDateFROM = '2014-01-01'

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
	WHERE RR.vcCode_Regroupement = 'IND'
	ORDER BY j.LaDate,rr.vcDescription



	CREATE TABLE #tOperTable(
		OperID INT,-- PRIMARY KEY,
		iTioId integer
		)

	-- Seulement les opération relié à UN_TIO, car c'est un rapport sur les TIO
	INSERT INTO #tOperTable
		SELECT 
			o.OperID,
			TioTIN.iTioId

		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioTIN on TioTIN.iTINOperID = o.operid
		WHERE OperDate BETWEEN @dtStartDateFROM AND @dtEndDate

		UNION

		SELECT 
			o.OperID,
			TioOUT.iTioId
		FROM Un_Oper o WITH(NOLOCK) 
		join Un_Tio TioOUT on TioOUT.iOUTOperID = o.operid
		WHERE OperDate BETWEEN @dtStartDateFROM AND @dtEndDate


	-- IQEE
	SELECT 
		j.LaDate,
		Regime = rr.vcDescription,
		IQEE_et_IQEEPlus = SUM(CASE WHEN CO.ConventionOperTypeID IN ('CBQ','MMQ') THEN CO.ConventionOperAmount ELSE 0 END)
		
	INTO #IQEE 
	FROM Un_Convention C
	JOIN Un_Plan P  ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on P.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	JOIN #tOperTable OT ON OT.OperID = O.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
	WHERE P.PlanTypeID = 'IND'
		AND CO.ConventionOperTypeID IN ('CBQ','MMQ')
	GROUP BY
		j.LaDate,rr.vcDescription
	ORDER BY j.LaDate,rr.vcDescription

	--SCEE
	SELECT
		j.LaDate,
		Regime = rr.vcDescription,
		SCEE_et_SCEEPlus_et_BEC = SUM(CE.fCESG + CE.fACESG + CE.fCLB )
	INTO #SCEE 
	FROM Un_Convention C
	JOIN Un_Plan P ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_CESP CE on CE.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CE.OperID
	JOIN #tOperTable OT ON OT.OperID = O.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate AND O.OperDate >= @dtStartDateFROM
	WHERE P.PlanTypeID = 'IND'
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
		SCEE_et_SCEEPlus_et_BEC = ISNULL(S.SCEE_et_SCEEPlus_et_BEC,0),
		IQEE_et_IQEEPlus = ISNULL(Q.IQEE_et_IQEEPlus,0)
	FROM #Liste L
	LEFT JOIN #SCEE	S ON S.LaDate = L.LaDate AND S.Regime = L.Regime
	LEFT JOIN #IQEE	Q ON Q.LaDate = L.LaDate AND Q.Regime = L.Regime


--SET ARITHABORT OFF
END
