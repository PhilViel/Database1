/****************************************************************************************************
Copyrights (c) 2018 Gestion Universitas inc
Nom                 :	psOPER_RapportTresorieINDIVIDUEL_ParDate
Description         :	Rapport : TRÉSORIE DES INDIVIDUEL PAR DATE
Valeurs de retours  :	Dataset :
								
Note                :	

	2018-10-16	Donald Huppé		Création.
				
exec psOPER_RapportTresorieINDIVIDUEL_ParDate 
	@dtStartDate = '2018-09-01', 
	@dtEndDate = '2018-09-01'

exec psOPER_RapportTresorieSubvention_ParDate 
	@dtStartDate = NULL, 
	@dtEndDate = NULL

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportTresorieINDIVIDUEL_ParDate] (	
	
	@dtStartDate DATETIME,
	@dtEndDate DATETIME
				)

AS
BEGIN

--SET ARITHABORT ON


	IF @dtStartDate IS NOT NULL AND DATEDIFF(DAY,@dtStartDate,@dtEndDate) > 31
		BEGIN
		SELECT

		DateDu = CAST(@dtStartDate AS DATE),
		DateAu = CAST(@dtEndDate AS DATE),
		LaDate = '',
		TypeConvention = 'Période trop longue',

		Epargne = 0,
		RendInd = 0,
		SCEE = 0,
		RendSCEE = 0,
		
		BEC = 0,
		RendBEC = 0,
		IQEE = 0,
		RendIQEE = 0

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
	CREATE TABLE #TC (TypeConvention VARCHAR (15))
	INSERT INTO #TC VALUES ('RIO')
	INSERT INTO #TC VALUES ('Autre')

	SELECT 
		j.LaDate,
		TypeConvention
	INTO #Liste
	FROM #Jour j
	JOIN #TC TC ON 1 =1
	ORDER BY j.LaDate,TypeConvention
	----------------------------------------------


	SELECT DISTINCT
		c.ConventionID,
		TypeConvention = CASE WHEN r.iID_Convention_Destination IS NOT NULL 
						AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'RIO' ELSE 'Autre' END
	INTO #typeConv
	FROM Un_Convention C
	LEFT JOIN (
		SELECT DISTINCT rio.iID_Convention_Destination, c.ConventionNo
		from tblOPER_OperationsRIO rio
		join Un_Oper o ON rio.iID_Oper_RIO = o.OperID
		JOIN dbo.Un_Convention c ON rio.iID_Convention_Destination = c.ConventionID
		where rio.OperTypeID IN ( 'RIO','RIM')
		--AND rio.bRIO_Annulee = 0
		and rio.bRIO_QuiAnnule = 0
		and o.OperDate <= @dtEndDate
		) r on C.conventionid = r.iID_Convention_Destination
	WHERE c.PlanID = 4

	SELECT
		LaDate = CAST(j.LaDate AS DATE),
		TC.TypeConvention,
		Epargne = SUM(Ct.Cotisation)
	INTO #EPARGNE
	FROM dbo.Un_Unit U 
	JOIN Un_Convention c on c.ConventionID = u.ConventionID
	JOIN Un_Plan P  ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
	JOIN Un_Oper O on O.OperID = Ct.OperID
	JOIN Un_OperType  OT ON OT.OperTypeID = O.OperTypeID
	JOIN #Jour j on j.LaDate >= O.OperDate
	LEFT JOIN #typeConv TC ON TC.ConventionID = C.ConventionID
	WHERE 1=1
		AND p.PlanID = 4
		AND(
				( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
				OR O.OperTypeID = 'TRA' -- Inclus les TRA
				)
			OR  
				O.OperTypeID = 'TFR'
			)
	GROUP BY 
		CAST(j.LaDate AS DATE),
		TC.TypeConvention

	-- IQEE
	SELECT 
		j.LaDate,
		TC.TypeConvention,
		IQEE = sum(case when co.conventionopertypeid IN ('CBQ','MMQ') then ConventionOperAmount else 0 end ),
		
		RendSCEE = SUM(case when co.conventionopertypeid IN ( 'INS','IST','IS+') then ConventionOperAmount else 0 end ), --ISNULL(INS,0) + ISNULL(IST,0) + ISNULL(ISPlus,0)
		RendBEC = SUM(case when co.conventionopertypeid IN ( 'IBC') then ConventionOperAmount else 0 end ), --ISNULL(IBC,0)
		RendIQEE = sum(case when co.conventionopertypeid IN ( 'ICQ','III','IIQ','IMQ','MIM','IQI') then ConventionOperAmount else 0 end ), 
		
		RendInd = sum(case when co.conventionopertypeid IN ( 'INM','ITR') then ConventionOperAmount else 0 end )

	INTO #IQEE 
	FROM Un_Convention C
	JOIN Un_Plan P  ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on P.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CO.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate
	JOIN #typeConv TC ON TC.ConventionID = C.ConventionID
	WHERE 
		p.PlanTypeID = 'IND'
		AND CO.ConventionOperTypeID IN ( 'CBQ','MMQ','IBC','ICQ','III','IIQ','IMQ','INS','IS+','IST','INM','ITR','MIM','IQI')
	GROUP BY
		j.LaDate,TC.TypeConvention
	ORDER BY j.LaDate,TC.TypeConvention

	--SCEE
	SELECT
		j.LaDate,
		TC.TypeConvention,
		SCEE = SUM(CE.fCESG+CE.fACESG),
		BEC = SUM(CE.fCLB)
	INTO #SCEE 
	FROM Un_Convention C
	JOIN Un_Plan P ON C.PlanID = P.PlanID 
	JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime
	JOIN Un_CESP CE on CE.ConventionID = C.ConventionID
	JOIN Un_Oper O ON O.OperID = CE.OperID
	JOIN #Jour j on j.LaDate >= O.OperDate
	LEFT JOIN #typeConv TC ON TC.ConventionID = C.ConventionID
	WHERE 1=1
	GROUP BY
		j.LaDate,TC.TypeConvention
	ORDER BY j.LaDate,TC.TypeConvention


	-- résultat
	SELECT 
		DateDu = CAST(@dtStartDate AS DATE),
		DateAu = CAST(@dtEndDate AS DATE),
		LaDate = cast(L.LaDate AS DATE),
		L.TypeConvention,

		Epargne = ISNULL(Epargne,0),
		RendInd = ISNULL(RendInd,0),
		SCEE = ISNULL(SCEE,0),
		RendSCEE = ISNULL(RendSCEE,0),
		
		BEC = ISNULL(BEC,0),
		RendBEC = ISNULL(RendBEC,0),
		IQEE = ISNULL(IQEE,0),
		RendIQEE = ISNULL(RendIQEE,0)
	FROM #Liste L
	LEFT JOIN #SCEE	S ON S.LaDate = L.LaDate AND S.TypeConvention = L.TypeConvention
	LEFT JOIN #IQEE	Q ON Q.LaDate = L.LaDate AND Q.TypeConvention = L.TypeConvention
	LEFT JOIN #EPARGNE E ON E.LaDate = L.LaDate AND E.TypeConvention = L.TypeConvention


--SET ARITHABORT OFF
END