/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	GU_RP_VentesExcelRepConserv_2 ( basé sur GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Retourner le nombre de nouveaux bénéficiaires pour une préiode donnée par représentant ainsi que le 
						nombre d'unitées nettes vendues par plan et le nombre d'unitées nettes totale par représentant.  Donne
						aussi comme information le nom du Directeur qui était en cours durant cette période et qui avait le plus
						haut pourcentage ainsi que le taux de conservation du directeur ou celui du représentant si celui du 
						directeur est à 0.
Valeurs de retours  :	Dataset 
Note                :	2008-12-08  Donald Huppé	    Création	
                        2018-10-29  Pierre-Luc Simard   N'est plus utilisée
-- exec GU_RP_VentesExcelRepConserv_2 321
***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_VentesExcelRepConserv] ( 
	@ReptreatmentID integer)
AS
BEGIN
	
SELECT 1/0
/*
	SET NOCOUNT ON -- Pour que ça fonctionne avec Access

declare
		@StartDate DATETIME,
		@EndDate DATETIME,
		@CurrentTreatmentDate DATETIME,
		@TreatmentYear INTEGER

	-- retrouver la date du traitement demandé
	SELECT 
		@EndDate = RepTreatmentDate,
		@CurrentTreatmentDate = RepTreatmentDate,
		@TreatmentYear = YEAR(RepTreatmentDate)
	FROM Un_RepTreatment
	WHERE RepTreatmentID = @ReptreatmentID

	-- Retrouver la date du premier traitement de l'année
	select @StartDate = RepTreatmentDate 
	from Un_RepTreatment 
	where RepTreatmentID = (
		SELECT 
			FirstReptreatmentID = min(RepTreatmentID)
		FROM Un_RepTreatment
		WHERE YEAR(RepTreatmentDate) = @TreatmentYear)

	SELECT 
		RT.RepID,
		RT.RepCode,
		--reptreatmentdate,
		H.firstname,
		H.lastname,
		ConsPct = CASE RT.DirConsPct WHEN 0 THEN RT.REPConsPct ELSE RT.DIRConsPct END
	FROM 
		Un_Dn_RepTreatmentSumary RT
		JOIN dbo.Mo_Human H on RT.repid = H.humanid
	WHERE 
		RepTreatmentID = @ReptreatmentID
		AND RepTreatmentDate = @CurrentTreatmentDate
	order by
		H.lastname,
		H.firstname

/*

-- Va chercher le nombre de nouveaux bénéficiaire entre deux dates pour chaque représentant
	SELECT 
		U.RepID,
		NbBenef = COUNT(NB.BeneficiaryID)
	INTO #tRepNewBeneficiary
	FROM ( -- Va chercher la liste des nouveaux bénéficiaires avec son premier groupe d'unité
		SELECT
			NB.BeneficiaryID,
			MinUnitID = MIN(UnitID)
		FROM (
			SELECT 
				C.BeneficiaryID,
				MinInforceDate = MIN(U.InforceDate)
			FROM dbo.Un_Convention C
			JOIN dbo.Un_Unit U ON U.conventionID = C.ConventionID
			GROUP BY C.BeneficiaryID
			HAVING MIN(U.InforceDate) BETWEEN @StartDate AND @EndDate
			) NB 
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = NB.BeneficiaryID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID AND U.InforceDate = NB.MinInforceDate
		GROUP BY NB.BeneficiaryID
		) NB
	JOIN dbo.Un_Unit U ON U.UnitID = NB.MinUnitID
	GROUP BY U.RepID
	ORDER BY U.RepID

	-- Va chercher le nombre d'unités par plan, par représentant (Universitas:8, Individuel:4, Reeeflex: 10)
	SELECT 
		U.RepID,
		NbUniteBrutUniv = SUM(NbUniteBrutUniv),
		NbUnitNetUniv = SUM(NbUnitNetUniv),
		NbUniteBrutRFLEX = SUM(NbUniteBrutRFLEX),
		NbUnitNetRLEX = SUM(NbUnitNetRLEX),
		NbUniteBrutInd = SUM(NbUniteBrutInd),
		NbUnitNetInd = SUM(NbUnitNetInd)
	INTO #tRepPlanUnit
	FROM (
		SELECT
			U.RepID,
			U.UnitID,
			NbUniteBrutUniv = CASE WHEN C.PlanID = 8 THEN SUM(ISNULL(U.UnitQty,0)) + ISNULL(UR.UnitReductionQty,0) ELSE 0 END,
			NbUnitNetUniv = CASE WHEN C.PlanID = 8 THEN SUM(ISNULL(U.UnitQty,0)) ELSE 0 END, 
			NbUniteBrutRFLEX = CASE WHEN C.PlanID = 10 THEN SUM(ISNULL(U.UnitQty,0)) + ISNULL(UR.UnitReductionQty,0) ELSE 0 END,
			NbUnitNetRLEX = CASE WHEN C.PlanID = 10 THEN SUM(ISNULL(U.UnitQty,0)) ELSE 0 END, 
			NbUniteBrutInd = CASE WHEN C.PlanID = 4 THEN SUM(ISNULL(U.UnitQty,0)) + ISNULL(UR.UnitReductionQty,0) ELSE 0 END,
			NbUnitNetInd = CASE WHEN C.PlanID = 4 THEN SUM(ISNULL(U.UnitQty,0)) ELSE 0 END 
		FROM dbo.Un_Convention C
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		LEFT JOIN (
			SELECT 
				UR.UnitID,
				SUM(UR.UnitQty) AS UnitReductionQty
			FROM Un_UnitReduction UR 
			GROUP BY 
				UR.UnitID
			) UR ON UR.UnitID = U.UnitID
		WHERE U.InForceDate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			U.RepID,
			U.UnitID,
			C.PlanID,
			UR.UnitReductionQty
		) U
	GROUP BY U.RepID

	-- Va chercher le nom du représentant, du directeur et le taux de conservation du représentant
	SELECT
		R.RepID,
		R.RepCode,
		H.FirstName,
		H.LastName,
		HB.FirstName AS DirFirstName,
		HB.LastName AS DirLastName,
		NbBenef,
		NbUniteBrutUniv,
		NbUnitNetUniv,
		NbUniteBrutRFLEX,
		NbUnitNetRLEX,
		NbUniteBrutInd,
		NbUnitNetInd,
		ConsPct
	FROM Un_Rep R 
	JOIN dbo.Mo_Human H ON H.HumanID = R.RepID
	LEFT JOIN( -- Va chercher le directeur du représentant aux dates sélectionnées
		SELECT 
			RB.RepID,
			BossID = MAX(BossID)
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT 
					RB.RepID, 
					RepBossPct = MAX(RB.RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND RB.StartDate <= @StartDate
					AND ISNULL(RB.EndDate,GETDATE()) >= @EndDate
				GROUP BY
					RB.RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE 
			RepRoleID = 'DIR'
			AND RB.StartDate <= @StartDate
			AND ISNULL(RB.EndDate,GETDATE()) >= @EndDate
		GROUP BY 
			RB.RepID
		)TRB ON TRB.RepID = R.RepID
	LEFT JOIN dbo.Mo_Human HB ON HB.HumanID = TRB.BossID
	JOIN( -- Va chercher le taux de conservation du représentant ou du directeur
		SELECT 
			RepID,
			ConsPct = CASE DirConsPct WHEN 0 THEN REPConsPct ELSE DIRConsPct END
		FROM Un_Dn_RepTreatmentSumary
		WHERE RepTreatmentID = @ReptreatmentID
			AND  RepTreatmentDate = @CurrentTreatmentDate
		) TS ON TS.RepID = R.RepID
	LEFT JOIN #tRepPlanUnit PU ON PU.RepID = R.RepID
	LEFT JOIN #tRepNewBeneficiary NB ON NB.RepID = R.RepID
	WHERE (ISNULL(NbUniteBrutUniv,0) + ISNULL(NbUniteBrutRFLEX,0) + ISNULL(NbUniteBrutInd,0)) <> 0
	ORDER BY H.LastName, H.FirstName

*/*/
END

-- Exemple
-- EXEC GU_RP_VentesExcelRepConserv_2 '2008-01-01', '2008-11-30'