/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	RP_UN_EAFBByPlanAndYearQualif
Description         :	Retourne les données pour le rapport par plan et année de qualification des EAFB
Exemple d'appel		:
						
						DBCC FREEPROCCACHE
						GO
						
						EXEC dbo.RP_UN_EAFBByPlanAndYearQualif 
											@ConnectID	= 2,
											@All		= 1, 				-- détermine si l'on veut le rapport pour toutes les opérations du système (1) ou pour une période (0)
											@StartDate	= '2009-01-01', 	-- Date de début de l'interval inclusivement
											@EndDate	= '2009-12-31',		-- Date de fin de l'interval inclusivement
											@ReportFilter = 'ALL'			-- Filtre : ALL = Tous, CNV = Convention seulement, PRP = Proposition seulement
						GO				
						
Valeurs de retours  :	Dataset contenant les données
Note                :	ADX0000624	IA	2005-01-04	Bruno Lapointe		Création
			ADX0001258	BR	2005-02-08	Bruno Lapointe			Optimisation et subdivision pour éviter le ASTA Time Out
			ADX0001206	IA	2006-12-12	Alain Quirion			Optimisation
			ADX0001235	IA	2007-02-14	Alain Quirion			Utilisation de dtRegStartDate pour la date de début de régime
							2009-12-10	Jean-François Gauthier	Modification pour remplacer INT parIN+/IN-	
							2009-12-17	Jean-François Gauthier	Intégration modif. Rémy
							2010-01-15	Jean-François Gauthier	Remplacement de fnOPER_ObtenirTypesOperationConvCategorie par fnOPER_ObtenirTypesOperationCategorie
							2010-03-29	Jean-François Gauthier	Appel de FN_CRQ_DateNoTime pour éliminer les heures/min/sec de dtRegStartDate
                            2017-12-12  Pierre-Luc Simard       Ajout du compte RST dans le compte BRS
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_EAFBByPlanAndYearQualif] (
	@ConnectID INTEGER,	-- ID de connexion
	@All BIT, 		-- détermine si l'on veut le rapport pour toutes les opérations du système (1) ou pour une période (0)
	@StartDate DATETIME, 	-- Date de début de l'interval inclusivement
	@EndDate DATETIME, 	-- Date de fin de l'interval inclusivement
	@ReportFilter CHAR(3)) 	-- Filtre : ALL = Tous, CNV = Convention seulement, PRP = Proposition seulement
AS
BEGIN	
	DECLARE
		@dtBegin DATETIME,
		@dtEnd DATETIME,
		@siTraceReport SMALLINT,
		@vcOPER_RENDEMENT_POSITIF_NEGATIF VARCHAR(200)

	SET @vcOPER_RENDEMENT_POSITIF_NEGATIF = [dbo].[fnOPER_ObtenirTypesOperationCategorie]('OPER_RENDEMENT_POSITIF_NEGATIF')

	SET @dtBegin = GETDATE()

	IF @All = 1
	BEGIN
		SET @StartDate = 0
		SELECT @EndDate = MAX(OperDate) --1sec
		FROM Un_Oper
	END

	SET @EndDate = @EndDate + 1

	-- Création d'une table contenant les conventions qui doivent sortir dans le rapport
	CREATE TABLE #ActiveConvention 
					(
						ConventionID	INT, 
						YearQualif		INT,
						UnitQty			MONEY,
						PlanID			INT,
						UnitID			INT
					)
					
	CREATE INDEX idx_UnitID ON #ActiveConvention(UnitID)

	IF @ReportFilter = 'ALL' --Tous
	BEGIN		
		-- Insertion des données dans la table temporaire des conventions qui doivent sortir dans le rapport
		INSERT INTO #ActiveConvention --12sec
		(
			ConventionID
			,YearQualif	
			,UnitQty
			,PlanID	
			,UnitID	
		)
		SELECT DISTINCT
			C.ConventionID,
			YQ.YearQualif,
			UnitQty = SUM(U.UnitQty),
			C.PlanID,
			U.UnitID
		FROM 
			Un_Convention C 
			JOIN dbo.Un_Unit U 
				ON U.ConventionID = C.ConventionID
			JOIN Un_ConventionYearQualif YQ 
				ON YQ.ConventionID = C.ConventionID
			LEFT JOIN ( -- Pas encore de bourse
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					) S ON S.ConventionID = C.ConventionID
			LEFT JOIN ( -- Bourse de disponible
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					WHERE 
						ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
					) SD ON SD.ConventionID = C.ConventionID
		WHERE 	
			@EndDate BETWEEN YQ.EffectDate AND ISNULL(YQ.TerminatedDate, @EndDate)
			AND	
			ISNULL(U.TerminatedDate, @EndDate) >= @EndDate
			AND	
			U.InForceDate >= @StartDate
			AND	
			U.InForceDate < @EndDate
			AND	
				(	
					S.ConventionID IS NULL
					OR 
					SD.ConventionID IS NOT NULL
				)
		GROUP BY 
			C.ConventionID,
			YQ.YearQualif,
			C.PlanID,
			U.UnitID	
	END
	ELSE IF @ReportFilter = 'CNV' --Convention
	BEGIN
		INSERT INTO #ActiveConvention --12sec
		(
			ConventionID
			,YearQualif	
			,UnitQty
			,PlanID	
			,UnitID	
		)
		SELECT DISTINCT
			C.ConventionID,
			YQ.YearQualif,
			UnitQty = SUM(U.UnitQty),
			C.PlanID,
			U.UnitID
		FROM 
			Un_Convention C 
			JOIN dbo.Un_Unit U 
				ON U.ConventionID = C.ConventionID
			JOIN Un_ConventionYearQualif YQ 
				ON YQ.ConventionID = C.ConventionID
			LEFT JOIN ( -- Pas encore de bourse
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					) S ON S.ConventionID = C.ConventionID
			LEFT JOIN ( -- Bourse de disponible
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					WHERE 
						ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
					) SD ON SD.ConventionID = C.ConventionID
		WHERE 	
			@EndDate BETWEEN YQ.EffectDate AND ISNULL(YQ.TerminatedDate, @EndDate)
			AND	
			ISNULL(U.TerminatedDate, @EndDate) >= @EndDate
			AND	
			U.InForceDate >= @StartDate
			AND	
			U.InForceDate < @EndDate
			AND	
				(	
					S.ConventionID IS NULL
					OR 
					SD.ConventionID IS NOT NULL
				)
			AND
			(	@All = 1 AND C.dtRegStartDate IS NOT NULL)
				OR 
				(	@All = 0 
					AND C.dtRegStartDate IS NOT NULL 
					AND (@EndDate >= dbo.FN_CRQ_DateNoTime(C.dtRegStartDate))
			)		
		GROUP BY 
			C.ConventionID,
			YQ.YearQualif,
			C.PlanID,
			U.UnitID		
	END
	ELSE --Proposition
	BEGIN
		INSERT INTO #ActiveConvention --12sec
		(
			ConventionID
			,YearQualif	
			,UnitQty
			,PlanID	
			,UnitID	
		)
		SELECT DISTINCT
			C.ConventionID,
			YQ.YearQualif,
			UnitQty = SUM(U.UnitQty),
			C.PlanID,
			U.UnitID
		FROM 
			Un_Convention C 
			JOIN dbo.Un_Unit U 
				ON U.ConventionID = C.ConventionID
			JOIN Un_ConventionYearQualif YQ 
				ON YQ.ConventionID = C.ConventionID
			LEFT JOIN ( -- Pas encore de bourse
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					) S ON S.ConventionID = C.ConventionID
			LEFT JOIN ( -- Bourse de disponible
					SELECT 
						DISTINCT ConventionID
					FROM 
						Un_Scholarship 
					WHERE 
						ScholarshipStatusID IN ('RES','ADM','WAI','TPA')
					) SD ON SD.ConventionID = C.ConventionID
		WHERE 	
			@EndDate BETWEEN YQ.EffectDate AND ISNULL(YQ.TerminatedDate, @EndDate)
			AND	
			ISNULL(U.TerminatedDate, @EndDate) >= @EndDate
			AND	
			U.InForceDate >= @StartDate
			AND	
			U.InForceDate < @EndDate
			AND
			(	@All = 1 AND C.dtRegStartDate IS NULL)
			OR 
			(	@All = 0
				AND	(C.dtRegStartDate IS NULL
					 OR (@EndDate < dbo.FN_CRQ_DateNoTime(C.dtRegStartDate)))
			)	
		GROUP BY 
			C.ConventionID,
			YQ.YearQualif,
			C.PlanID,
			U.UnitID		
	END
	
	-- Table temporaire du rapport
	CREATE TABLE #EAFBSumary 
		(
			PlanID INTEGER,
			YearQualif INTEGER,
			ConventionQty INTEGER,
			UnitQty MONEY,
			Cotisation MONEY,
			IntClient MONEY,
			IntEAFB MONEY, 
			FraisRIN MONEY, 
			Bourse MONEY, 
			Avance MONEY, 
			IntRI MONEY, 
			IntIND MONEY, 
			IntTIN MONEY,
				CONSTRAINT PK_EAFBSumary PRIMARY KEY (PlanID,YearQualif)
		) 

		INSERT INTO #EAFBSumary ( -- 1min 35
			PlanID,
			YearQualif,
			ConventionQty,
			UnitQty,
			Cotisation,
			IntClient,
			IntEAFB, 
			FraisRIN, 
			Bourse, 
			Avance, 
			IntRI, 
			IntIND, 
			IntTIN)
		SELECT
			C.PlanID,
			AC.YearQualif,
			ConventionQty = COUNT(DISTINCT C.ConventionID),
			UnitQty = 0,
			Cotisation = 0,
			IntClient = 0,
			IntEAFB = 0,
			FraisRIN = 0,
			Bourse = 0,
			Avance = 0,
			IntRI = 0,
			IntIND = 0,
			IntTIN = 0
		FROM 
			#ActiveConvention AC
			JOIN dbo.Un_Convention C 
				ON C.ConventionID = AC.ConventionID
			JOIN Un_Plan P 
				ON P.PlanID = C.PlanID
		GROUP BY 
			C.PlanID,
			AC.YearQualif

	/** DEBUT DES UPDATE **/
	UPDATE #EAFBSumary
	SET IntClient = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'INC'
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET IntEAFB = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'EFB'
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET Bourse = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID IN ('BRS', 'RST')
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET Avance = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'AVC'
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET IntRI = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID AND ISNULL(P.PlanTypeID,'') = 'COL'	
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'INM'
		JOIN Un_Oper O ON CO.OperID = O.OperID AND (CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) > 0)
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET IntIND = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'INM'
		JOIN Un_Oper O ON CO.OperID = O.OperID 
		WHERE (CHARINDEX(O.OperTypeID,@vcOPER_RENDEMENT_POSITIF_NEGATIF) = 0)
			OR ISNULL(P.PlanTypeID,'') <> 'COL'	
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	UPDATE #EAFBSumary
	SET IntTIN = V.SUMOper
	FROM #EAFBSumary
	JOIN (	SELECT 
			C.PlanID,
			AC.YearQualif,
			SUMOper = SUM(ISNULL(CO.ConventionOperAmount,0))
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		JOIN Un_Plan P ON P.PlanID = C.PlanID
		JOIN Un_ConventionOper CO ON CO.ConventionID = C.ConventionID AND CO.ConventionOperTypeID = 'ITR'
		GROUP BY 
			C.PlanID,
			AC.YearQualif) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif
	/** FIN TEST UPDATE **/

	UPDATE #EAFBSumary --3sec
	SET UnitQty = V.UnitQty
	FROM #EAFBSumary
	JOIN (
		SELECT
			C.PlanID,
			AC.YearQualif,
			UnitQty = SUM(AC.UnitQty)
		FROM #ActiveConvention AC
		JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
		GROUP BY 
			C.PlanID,
			AC.YearQualif
		) V ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	DECLARE @tCot TABLE 
					(
						PlanID			INT
						,YearQualif		INT		
						,Cotisation		MONEY
					)
						
	INSERT INTO @tCot
	(
		PlanID
		,YearQualif
		,Cotisation
	)
	SELECT
		AC.PlanID,
		AC.YearQualif,
		Cotisation = SUM(Ct.Cotisation)
	FROM 
		#ActiveConvention AC
		INNER JOIN Un_Cotisation Ct	WITH(READUNCOMMITTED)
			ON Ct.UnitID = AC.UnitID
		INNER JOIN Un_Oper O		WITH(READUNCOMMITTED)
			ON O.OperID = Ct.OperID	
	WHERE
		(@All = 1 OR 
		(O.OperDate >= @StartDate AND O.OperDate < @EndDate))		
	GROUP BY 
		AC.PlanID,
		AC.YearQualif

	UPDATE t
	SET 
		t.Cotisation = V.Cotisation
	FROM 
		#EAFBSumary t
		INNER JOIN @tCot V 
			ON 	V.PlanID = t.PlanID AND V.YearQualif = t.YearQualif

	UPDATE #EAFBSumary --5sec
	SET 
		FraisRIN = V.FraisRIN 
	FROM 
		#EAFBSumary
		JOIN (
				SELECT
					C.PlanID,
					AC.YearQualif,
					FraisRIN = SUM(Ct.Fee)
				FROM #ActiveConvention AC
				JOIN dbo.Un_Convention C ON C.ConventionID = AC.ConventionID
				JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
				JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
				JOIN Un_Oper O ON O.OperID = Ct.OperID	
				WHERE O.OperTypeID = 'RIN'
					AND O.OperDate >= @StartDate
					AND O.OperDate < @EndDate
				GROUP BY 
					C.PlanID,
					AC.YearQualif
			) V 
			ON V.PlanID = #EAFBSumary.PlanID AND V.YearQualif = #EAFBSumary.YearQualif

	-- RETOUR DES RÉSULTATS
	SELECT 
		P.PlanDesc,
		EAFB.PlanID,
		EAFB.YearQualif,
		EAFB.ConventionQty,
		EAFB.UnitQty,
		EAFB.Cotisation,
		EAFB.IntClient,
		EAFB.IntEAFB, 
		EAFB.FraisRIN, 
		EAFB.Bourse, 
		EAFB.Avance, 
		ColTotal = EAFB.IntClient+EAFB.IntEAFB+EAFB.FraisRIN+EAFB.Bourse+EAFB.Avance,
		EAFB.IntRI, 
		EAFB.IntIND, 
		EAFB.IntTIN,
		IndTotal = EAFB.IntRI+EAFB.IntIND+EAFB.IntTIN,
		Total = EAFB.IntClient+EAFB.IntEAFB+EAFB.FraisRIN+EAFB.Bourse+EAFB.Avance+EAFB.IntRI+EAFB.IntIND+EAFB.IntTIN
	FROM 
		#EAFBSumary EAFB
		JOIN Un_Plan P 
			ON P.PlanID = EAFB.PlanID
	ORDER BY 
		P.OrderOfPlanInReport,
		EAFB.YearQualif

	DROP TABLE #ActiveConvention
	DROP TABLE #EAFBSumary

	SET @dtEnd = GETDATE()
	SELECT @siTraceReport = siTraceReport FROM Un_Def

	IF DATEDIFF(SECOND, @dtBegin, @dtEnd) > @siTraceReport
	BEGIN
		-- Insère un log de l'objet inséré.
		INSERT INTO Un_Trace (
				ConnectID, -- ID de connexion de l’usager
				iType, -- Type de trace (1 = recherche, 2 = rapport)
				fDuration, -- Temps d’exécution de la procédure
				dtStart, -- Date et heure du début de l’exécution.
				dtEnd, -- Date et heure de la fin de l’exécution.
				vcDescription, -- Description de l’exécution (en texte)
				vcStoredProcedure, -- Nom de la procédure stockée
				vcExecutionString ) -- Ligne d’exécution (inclus les paramètres)
			SELECT
				@ConnectID,
				2,				
				DATEDIFF(SECOND, @dtBegin, @dtEnd),
				@dtBegin,
				@dtEnd,
				'Rapport du sommaire EAFB '+
								CASE
									WHEN @All = 1 THEN ' sans période '
									ELSE ' entre le '+CAST(@StartDate AS VARCHAR) + ' et le ' + CAST(@EndDate AS VARCHAR)
								END + 	CASE
										WHEN @ReportFilter = 'ALL' THEN ' sans filtre'
										WHEN @ReportFilter = 'CNV' THEN ' pour les conventions seulement'
										ELSE ' pour les propositions seulement'
									END,
				'RP_UN_EAFBByPlanAndYearQualif',
				'EXECUTE RP_UN_EAFBByPlanAndYearQualif @ConnectID ='+CAST(@ConnectID AS VARCHAR)+
				', @StartDate ='+CAST(@StartDate AS VARCHAR)+		
				', @EndDate ='+CAST(@EndDate AS VARCHAR)+
				', @ReportFilter ='+CAST(@ReportFilter AS VARCHAR)
	END	
END