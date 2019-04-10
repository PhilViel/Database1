/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepConcours
Description         :	Dataset pour la création du fichier Excel du concours des ventes
Valeurs de retours  :	Dataset 
Note                :	2008-03-06 Pierre-Luc	Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepConcours] (
	@StartDateSign DATETIME, -- Date de début de l'interval pour la signature
	@EndDateSign DATETIME, -- Date de fin de l'interval pour la signature
	@EndDatePRD DATETIME) -- Date de fin de l'interval pour le PRD
AS
BEGIN
	-- Va chercher le nombre d'unités qui ont été réduit
	CREATE TABLE #tUnitReduction (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL )
	INSERT INTO #tUnitReduction
		SELECT 
			UR.UnitID, 
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		WHERE U.SignatureDate BETWEEN @StartDateSign AND @EndDateSign 
			AND U.dtFirstDeposit <= @EndDatePRD
		GROUP BY 
			UR.UnitID	
	
	-- Va chercher le nombre d'unités signées
	CREATE TABLE #tUnitSign (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL)
	INSERT INTO #tUnitSign
		SELECT 
			U.UnitID,
			UnitQty = U.UnitQty + ISNULL(UR.UnitQty,0)
		FROM dbo.Un_Unit U
		LEFT JOIN #tUnitReduction UR ON UR.UnitID = U.UnitID
		WHERE U.SignatureDate BETWEEN @StartDateSign AND @EndDateSign 
			AND U.dtFirstDeposit <= @EndDatePRD
			-- U.ValidationConnectID IS NOT NULL -- convention validé, en REEE
	
	-- Va chercher le nombre d'unités qui ont été réduit pendant la période choisie
	CREATE TABLE #tUnitReductionInPeriod (
		UnitID INTEGER PRIMARY KEY,
		UnitQty MONEY NOT NULL )
	INSERT INTO #tUnitReductionInPeriod
		SELECT 
			UR.UnitID, 
			UnitQty = SUM(UR.UnitQty)
		FROM Un_UnitReduction UR
		JOIN #tUnitSign U ON U.UnitID = UR.UnitID
		WHERE UR.ReductionDate BETWEEN @StartDateSign AND @EndDateSign
		GROUP BY 
			UR.UnitID		

	CREATE TABLE #tUnit (
		UnitID INTEGER NOT NULL PRIMARY KEY,
		ConventionID INTEGER NOT NULL,
		ConventionNo VARCHAR(15) NOT NULL,
		SignDate DATETIME NOT NULL,
		PRDDate DATETIME NOT NULL,
		InForceDate DATETIME NOT NULL,
		UnitQtySign MONEY NOT NULL,
		UnitQtyReduct MONEY NOT NULL,
		RepID INTEGER NOT NULL,
		RepCode VARCHAR(50),
		DLastName VARCHAR(50), --Directeur
		DFirstName VARCHAR(50), 
		RLastName VARCHAR(50), --Représentant
		RFirstName VARCHAR(50), 
		SLastName VARCHAR(50), --Souscripteur
		SFirstName VARCHAR(50),
		SAdr VARCHAR(100))
	INSERT INTO #tUnit
		SELECT
			U.UnitID,
			U.ConventionID,
			C.ConventionNo,
			SignDate = U.SignatureDate,
			PRDDate = U.dtFirstDeposit,
			InForceDate = U.InForceDate,
			UnitQtySign = V.UnitQtySign,
			UnitQtyReduct = V.UnitQtyReduct,
			U.RepID,
			R.RepCode,
			HD.LastName, 
			HD.FirstName, 
			HR.LastName, 
			HR.FirstName, 
			HS.LastName, 
			HS.FirstName,
			SAdr = A.Address
		FROM dbo.Un_Unit U
		JOIN (
			SELECT
				US.UnitID,
				US.UnitQty As UnitQtySign,
				ISNULL(UR.UnitQty,0) As UnitQtyReduct
			FROM #tUnitSign US
			LEFT JOIN #tUnitReductionInPeriod UR ON UR.UnitID = US.UnitID
			) V ON V.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN dbo.Mo_Human HR ON HR.HumanID = U.RepID
		LEFT JOIN (
			SELECT 
				RB.RepID, 
				BossID = MAX(BossID)
			FROM Un_RepBossHist RB
			JOIN (
				SELECT 
					RB.RepID, 
					RepBossPct = MAX(RB.RepBossPct)
				FROM Un_RepBossHist RB
				WHERE RepRoleID = 'DIR'
					AND RB.StartDate <= @EndDateSign
					AND ISNULL(RB.EndDate,@EndDateSign) >= @EndDateSign
				GROUP BY 
					RB.RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDateSign
				AND ISNULL(RB.EndDate,@EndDateSign) >= @EndDateSign
			GROUP BY 
				RB.RepID
			) RD ON RD.RepID = R.RepID
		LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
		ORDER BY 
			HD.LastName, --Directeur
			HD.FirstName, 
			HR.LastName, --Représentant
			HR.FirstName, 
			HS.LastName, --Souscripteur
			HS.FirstName, 
			C.ConventionNo	
	
	-- Sommaire
	SELECT
		U.RepID,
		U.RepCode,
		U.DLastName,
		U.DFirstName, 
		U.RLastName,
		U.RFirstName, 
		A.NBAdr,
		A.PointAdr,
		U.UnitQtySign AS UnitQtyBrutes,
		U.UnitQtyReduct AS UnitQtyResil,
		U.UnitQtySign - U.UnitQtyReduct AS UnitQtyNettes, 
		A.PointAdr + (U.UnitQtySign - U.UnitQtyReduct) AS PointTotal
	FROM --Nombre d'unités
		(SELECT 
			RepID,
			RepCode,
			DLastName,
			DFirstName, 
			RLastName,
			RFirstName, 
			SUM(UnitQtySign) AS UnitQtySign,
			SUM(UnitQtyReduct) AS UnitQtyReduct
		FROM #tUnit
		GROUP BY 
			RepID,
			RepCode,
			DLastName,
			DFirstName, 
			RLastName,
			RFirstName
		) U
	JOIN --Nombre d'adresses
		(SELECT 
			AD.RepID,
			AD.DLastName,
			AD.DFirstName, 
			AD.RLastName,
			AD.RFirstName, 
			COUNT(AD.SAdr) AS NBAdr,
			COUNT(AD.SAdr) * 5 AS PointAdr
			FROM
				(SELECT 
					RepID,
					DLastName,
					DFirstName, 
					RLastName,
					RFirstName, 
					SAdr
				FROM #tUnit
				GROUP BY 
					RepID,
					DLastName,
					DFirstName, 
					RLastName,
					RFirstName, 
					SAdr) AD
			GROUP BY 
				RepID,
				DLastName,
				DFirstName, 
				RLastName,
				RFirstName
		) A ON A.RepID = U.RepID

	-- Liste détaillée
	SELECT
			U.UnitID,
			U.ConventionID,
			C.ConventionNo,
			SignDate = U.SignatureDate,
			PRDDate = U.dtFirstDeposit,
			InForceDate = U.InForceDate,
			UnitQtySign = V.UnitQtySign,
			UnitQtyReduct = V.UnitQtyReduct,
			U.RepID,
			R.RepCode,
			HD.LastName, 
			HD.FirstName, 
			HR.LastName, 
			HR.FirstName, 
			HS.LastName, 
			HS.FirstName,
			SAdr = A.Address
		FROM dbo.Un_Unit U
		JOIN (
			SELECT
				US.UnitID,
				US.UnitQty As UnitQtySign,
				ISNULL(UR.UnitQty,0) As UnitQtyReduct
			FROM #tUnitSign US
			LEFT JOIN #tUnitReductionInPeriod UR ON UR.UnitID = US.UnitID
			) V ON V.UnitID = U.UnitID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
		JOIN Un_Rep R ON R.RepID = U.RepID
		JOIN dbo.Mo_Human HR ON HR.HumanID = U.RepID
		LEFT JOIN (
			SELECT 
				RB.RepID, 
				BossID = MAX(BossID)
			FROM Un_RepBossHist RB
			JOIN (
				SELECT 
					RB.RepID, 
					RepBossPct = MAX(RB.RepBossPct)
				FROM Un_RepBossHist RB
				WHERE RepRoleID = 'DIR'
					AND RB.StartDate <= @EndDateSign
					AND ISNULL(RB.EndDate,@EndDateSign) >= @EndDateSign
				GROUP BY 
					RB.RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDateSign
				AND ISNULL(RB.EndDate,@EndDateSign) >= @EndDateSign
			GROUP BY 
				RB.RepID
			) RD ON RD.RepID = R.RepID
		LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = RD.BossID
	
END

-- GU_RP_VentesExcelRepConcours '2008-02-11', '2008-04-27', '2008-05-03'


