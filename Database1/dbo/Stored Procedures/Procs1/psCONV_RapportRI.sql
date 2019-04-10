/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	psCONV_RapportRI (basé sur SL_UN_SearchConventionWithRI)
Description         :	Procédure stockée de recherche de convention avec remboursement intégral.
Valeurs de retours  :	Dataset  
Note                :				2004-06-03	Bruno Lapointe		Création
									2004-08-19	Bruno Lapointe		Adpatation pour le point 10.28.
					ADX0001601	BR	2005-10-11	Bruno Lapointe		Retourner 0 au lieu de NULL pour le champ GrantAmount.
					ADX0000831	IA	2006-04-06	Bruno Lapointe		Si le souscripteur est une compagnie retourner seulement le nom sans virgule.
									2006-11-30	Alain Quirion		Optimisation						
					ADX0002426	BR	2007-05-22	Alain Quirion		Modification : Un_CESP au lieu de Un_CESP900
									2013-07-31  Maxime Martel		ajout de l'option tous pour les directeurs d'agence
									2018-09-07	Maxime Martel		JIRA MP-699 Ajout de OpertypeID COU
					exec psCONV_RapportRI '2013-01-15', 149602, 2
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportRI] (
	@dtReimbDate DATETIME, 
	@RepID INTEGER = 0,
	@UserID integer
	) -- Limiter les résultats selon un représentant, 0 pour tous
AS
BEGIN
	CREATE TABLE #TB_Rep (
			RepID INTEGER PRIMARY KEY)

	-- Insère tous les représentants sous un rep dans la table temporaire
	declare @rep bit = 0
			
	select @rep = count(distinct repid) from Un_Rep where @UserID = RepID

	if @rep = 1
	begin
		INSERT #TB_Rep
			EXEC SL_UN_BossOfRep @userID
		end
	else
	begin
		INSERT #TB_Rep
			select RepID from Un_Rep
	end

	if @RepID <> 0
	begin
		delete #TB_Rep where RepID <> @RepID
	end

	DECLARE @dtTreatment DATETIME
	SET @dtTreatment = GETDATE()

	CREATE TABLE #tUnitRI (
		UnitID INTEGER PRIMARY KEY, 
		ConventionID INTEGER,
		Estimated MONEY NOT NULL)

	INSERT INTO #tUnitRI
		SELECT
			U.UnitID, 
			U.ConventionID,
			Estimated = ROUND(M.PmtRate * U.UnitQty,2)* M.PmtQty
		FROM dbo.Un_Unit U 
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID
		WHERE ISNULL(U.TerminatedDate, 0) < 1 -- Exclus les résiliés
			AND P.PlanTypeID <> 'IND' -- Exclus les individuels
			AND dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust) = @dtReimbDate						

	CREATE TABLE #tConvRI (
		ConventionID INTEGER PRIMARY KEY)

	INSERT INTO #tConvRI
		SELECT DISTINCT URI.ConventionID
		FROM #tUnitRI URI

	CREATE TABLE #tBreaking (
		BreakingID INTEGER PRIMARY KEY,
		ConventionID INTEGER,
		BreakingStartDate DATETIME,
		BreakingEndDate DATETIME 
		)

	-- Cherche les conventions qui sont en arrêt de paiement à la date du jour
	INSERT INTO #tBreaking
		SELECT   
			BreakingID,
			C.ConventionID,   
			BreakingStartDate = dbo.fn_Mo_DateNoTime(B.BreakingStartDate),  
			BreakingEndDate = dbo.fn_Mo_DateNoTime(B.BreakingEndDate)  
		FROM #tConvRI CRI
		JOIN dbo.Un_Convention C ON C.ConventionID = CRI.ConventionID
		JOIN Un_Breaking B ON B.ConventionID = C.ConventionID
		WHERE	B.BreakingStartDate < @dtTreatment
				AND ISNULL(B.BreakingEndDate, @dtTreatment) >= @dtTreatment					
		GROUP BY 
			B.BreakingID,
			C.ConventionID, 
			B.BreakingStartDate, 
			B.BreakingEndDate 

	CREATE TABLE #tConvRICESP (
		ConventionID INTEGER PRIMARY KEY,
		fCESG MONEY NOT NULL,
		fACESG MONEY NOT NULL,
		fCLB MONEY NOT NULL )	

	INSERT INTO #tConvRICESP
		SELECT 
			CRI.ConventionID,
			fCESG = SUM(CE.fCESG),
			fACESG = SUM(CE.fACESG),
			fCLB = SUM(CE.fCLB)
		FROM #tConvRI CRI
		JOIN Un_CESP CE ON CE.ConventionID = CRI.ConventionID
		GROUP BY CRI.ConventionID

	DROP TABLE #tConvRI

	CREATE TABLE #tCotisationRI(
		ConventionID INTEGER PRIMARY KEY,
		CotisationAndFee MONEY
	)		

	INSERT INTO #tCotisationRI
		SELECT 
			U.ConventionID, 
			CotisationAndFee = SUM(Cotisation) + SUM(Fee)
		FROM #tUnitRI URI
		JOIN dbo.Un_Unit U ON U.UnitID = URI.UnitID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		GROUP BY U.ConventionID

	CREATE TABLE #tOperDateRI(
		ConventionID INTEGER PRIMARY KEY,
		OperDate DATETIME
	)	

	INSERT INTO #tOperDateRI
		SELECT 
			U.ConventionID, 
			OperDate = dbo.fn_Mo_DateNoTime(MAX(OperDate))
		FROM #tUnitRI URI
		JOIN dbo.Un_Unit U ON U.UnitID = URI.UnitID
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE O.OperTypeID IN ('CHQ', 'CPA', 'PRD', 'TRA', 'COU')
		GROUP BY U.ConventionID

	CREATE TABLE #tBenefInsurRI(
		UnitID INTEGER PRIMARY KEY,
		BenefInsur CHAR(3)
	)	

	INSERT INTO #tBenefInsurRI
		SELECT 
			U.UnitID,
			BenefInsur = 1	
		FROM Un_BenefInsur BI
		JOIN dbo.Un_Unit U ON BI.BenefInsurID = U.BenefInsurID	
		JOIN #tUnitRI URI ON URI.UnitID = U.UnitID
		GROUP BY U.UnitID

	SELECT
		@rep as estRep,
		rh.LastName + ', ' + rh.FirstName + ' (' + r.RepCode + ')' as representant,
		C.ConventionID,
		C.ConventionNo,
		C.SubscriberID,
		SubscriberName =
			CASE 
				WHEN H.IsCompany = 1 THEN H.LastName
				ELSE H.LastName + ', ' + H.FirstName
			END,
		BeneficiaryName = B.LastName + ', ' + B.FirstName,
		BenefInsur = CASE
				WHEN MAX(ISNULL(BI.BenefInsur,0)) = 0 THEN 'Non'
				ELSE 'Oui'
			END,
		C.YearQualif,
		Amount = ISNULL(Ct.CotisationAndFee,0),
		Estimated = SUM(URI.Estimated),
		Ecart = ISNULL(Ct.CotisationAndFee,0) - SUM(URI.Estimated),
		Deposit = SUM(ROUND(M.PmtRate * U.UnitQty,2)),
		fCESG = ISNULL(VG.fCESG,0),
		fACESG = ISNULL(VG.fACESG,0),
		fCLB = ISNULL(VG.fCLB,0),
		stopPayment =
			CASE 
				WHEN CB.ConventionID IS NOT NULL THEN 'Oui'
				ELSE 'Non'
			END, 
		BreakingStartDate,
		BreakingEndDate,
		LastDepositDate = VO.OperDate,
		a.Phone1
	FROM #tUnitRI URI
	JOIN dbo.Un_Unit U ON URI.UnitID = U.UnitID
	JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID	
	LEFT JOIN #TB_Rep B2 ON S.RepID = B2.RepID
	JOIN dbo.Mo_Human H ON H.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr A ON A.AdrID = H.AdrID
	JOIN dbo.Mo_Human B ON B.HumanID = C.BeneficiaryID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Plan P ON P.PlanID = C.PlanID
	LEFT JOIN #tBreaking CB ON CB.ConventionID = C.ConventionID
	LEFT JOIN #tBenefInsurRI BI ON BI.UnitID = U.UnitID			
	LEFT JOIN #tCotisationRI Ct ON Ct.ConventionID = C.ConventionID
	LEFT JOIN #tOperDateRI VO ON VO.ConventionID = C.ConventionID
	LEFT JOIN #tConvRICESP VG ON VG.ConventionID = C.ConventionID
	LEFT JOIN un_rep r on r.RepID = s.RepID
	LEFT JOIN dbo.Mo_Human rh on rh.HumanID = s.RepID	
	WHERE B2.RepID in (select * from #TB_Rep)
	GROUP BY 
		C.ConventionID, 
		C.ConventionNo, 
		C.SubscriberID, 
		H.LastName, 
		H.FirstName,
		H.IsCompany,
		B.LastName, 
		B.FirstName, 
		C.YearQualif, 		
		VO.OperDate, 
		VG.fCESG,
		VG.fACESG,
		VG.fCLB,
		CB.ConventionID,
		CB.BreakingStartDate,
		CB.BreakingEndDate,
		Ct.CotisationAndFee,
		VO.OperDate,
		rh.LastName,
		rh.FirstName,
		r.RepCode,
		a.Phone1
	ORDER BY C.ConventionNo

	DROP TABLE #tOperDateRI
	DROP TABLE #tCotisationRI
	DROP TABLE #tConvRICESP
	DROP TABLE #tBreaking
	DROP TABLE #tUnitRI	
	DROP TABLE #TB_Rep	
	
	-- FIN DES TRAITEMENTS
	RETURN 0
END