/****************************************************************************************************
Copyrights (c) 2019 Gestion Universitas inc
Nom                 :	psOPER_RapportEpargeEncaisseeParMois
Description         :	Rapport : Épargne encaissée par mois et par régime pour des cohortes données
Valeurs de retours  :	Dataset :
	
								
Note                :	Comme le rapport est lourd, il sera exécuté dans une copie de la base de données de production --> SRVSQLSUPPORTPROD.UnivBase

	2019-01-09	Donald Huppé		Création (JIRA PROD-12913)
	2019-01-23	Donald Huppé		Ajouter 16 cohorte au lieu de 9			

	EXEC psOPER_RapportEpargeEncaisseeParMois 2019


*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportEpargeEncaisseeParMois] (	
	
	@YearQualif INT
				)

AS
BEGIN

--SET ARITHABORT ON
	--select * from tmp_JIRAPROD12913

	--RETURN

	CREATE TABLE #TAB (DateFin DATETIME, GrRegime VARCHAR(45) , YearQualif INT , fCotisation MONEY  ) -- DROP TABLE #TAB

	DECLARE 
		@DateDu datetime,
		@DateAu datetime, --FIN DU MOIS COURANT
		@Ladate datetime,
		@DateDebut datetime,
		@DateFin datetime,
		@DateBD datetime


	SELECT @DateBD =  DATEADD(DAY,1,LastVerifDate) from un_def

	-- 17 ANS AVANT LA 1ERE COHORTE
	SET @DateDu = CAST( @YearQualif - 17 AS VARCHAR) + '-01-01'

	-- FIN DU MOIS COURANT
	SELECT @DateAu = DATEADD(DAY,-1,  DATEADD(MONTH,1,  DATEADD(mm, DATEDIFF(mm,0,GETDATE()), 0) ))

	SELECT @DateBD = DATEADD(DAY,1,LastVerifDate) from Un_Def
	


	SET	@Ladate = @DateDu

	WHILE @Ladate <= @DateAu
		BEGIN

		SELECT @DateDebut = DATEADD(mm, DATEDIFF(mm,0,@Ladate), 0)  
		IF @DateDebut = @DateDu
			SET @DateDebut = '1901-01-01'
		
		SELECT @DateFin = DATEADD(DAY,-1,  DATEADD(MONTH,1,  DATEADD(mm, DATEDIFF(mm,0,@Ladate), 0) ))

		IF @DateBD BETWEEN @DateDebut AND @DateFin
			SET @DateFin = @DateBD
		--SELECT @DateDebut, @DateFin

		INSERT INTO #TAB
		SELECT
			DateFin = @DateFin,
			GrRegime = rr.vcDescription,
			C.YearQualif,
			fCotisation = SUM(Ct.Cotisation)
		FROM dbo.Un_Unit U 
		JOIN Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
		JOIN Un_Cotisation Ct  ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O on O.OperID = Ct.OperID
		JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
		WHERE 1=1
			AND P.PlanTypeID = 'COL'
			AND O.OperDate BETWEEN @DateDebut AND @DateFin
			AND C.YearQualif BETWEEN @YearQualif AND @YearQualif + 16 --9
				AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
					OR O.OperTypeID = 'TRA' -- Inclus les TRA
					)
		GROUP BY rr.vcDescription,C.YearQualif
			
		SET @Ladate = DATEADD(MONTH,1, @Ladate)

		END


	SELECT
		DateFin,
		GrRegime,
		YearQualif,
		fCotisation 
	FROM #TAB 
	ORDER BY DateFin, GrRegime, YearQualif


	--SET ARITHABORT OFF
END

