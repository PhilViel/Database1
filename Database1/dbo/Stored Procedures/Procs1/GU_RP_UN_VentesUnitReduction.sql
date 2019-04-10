/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	GU_RP_UN_VentesUnitReduction
Description         :	PROCEDURE DU RAPPORT DE LA LISTE DES CONVENTIONS RÉSILIÉE OU RÉDUCTION D'UNITÉ DES 24 
						DERNIERS MOIS
Valeurs de retours  :	DATASET
Note                :	2008-10-14 	Josée Parent		Création de la procédures stockée
						2008-10-27	Josée Parent		Modification pour l'ajout de champs dans la sélection ainsi
														que pour lister seulement les représentants actif et les 
														résiliations complète sans tenir compte des rétentions.
						2009-02-23	Pierre-Luc Simard	Ajout des frais disponibles, correction au niveau de la rétention,
														dates en paramètres, etc.
*******************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_UN_VentesUnitReduction](
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME) -- Date de fin
AS
BEGIN
	-- SET NOCOUNT ON -- Pour que ça fonctionne avec Access
	SET @StartDate = '2007-01-01'	
	SET @EndDate = '2009-02-23'

	-- Va chercher le directeur du représentant aux dates sélectionnées
	DECLARE @tMaxPctBoss TABLE (
		RepID INTEGER PRIMARY KEY,
		BossID INTEGER NOT NULL )
	INSERT INTO @tMaxPctBoss
		SELECT 
			RB.RepID,
			BossID = MAX(BossID)
		FROM Un_RepBossHist RB
		LEFT JOIN (
			SELECT 
				RB.RepID, 
				RepBossPct = MAX(RB.RepBossPct)
			FROM Un_RepBossHist RB
			WHERE RepRoleID = 'DIR'
				AND RB.StartDate <= @EndDate
				AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
			GROUP BY RB.RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
		WHERE 
			RepRoleID = 'DIR'
			AND RB.StartDate <= @EndDate
			AND ISNULL(RB.EndDate,@EndDate) >= @EndDate
		GROUP BY 
			RB.RepID
	
	-- Table temporaire contenant le total des ré-utilisation de frais disponibles par résiliation (UnitReduction)
	DECLARE @tReUsedUnits TABLE (
		UnitReductionID INTEGER PRIMARY KEY,
		NbReUsedUnits MONEY NOT NULL )
	INSERT INTO @tReUsedUnits
		SELECT 
			UnitReductionID,
			NbReUsedUnits = SUM(A.fUnitQtyUse)
		FROM Un_AvailableFeeUse A
		GROUP BY UnitReductionID
		ORDER BY UnitReductionID

	-- Retraits 
	SELECT 
		UR.UnitReductionID,
		UnitQtyReduct = 
			CASE WHEN ISNULL(RU.NbReUsedUnits, 0) > 0 
			THEN UR.UnitQty - RU.NbReUsedUnits
			ELSE UR.UnitQty
			END
	INTO #Terminated
	FROM Un_UnitReduction UR
	JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
	JOIN Un_Modal M ON M.ModalID = U.ModalID	
	LEFT JOIN @tReUsedUnits RU ON UR.UnitReductionID = RU.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	WHERE (URR.bReduitTauxConservationRep = 1
			OR URR.bReduitTauxConservationRep IS NULL) -- La raison de la résiliation doit être marquée comme affectant le taux de conservation ou encore non-définie
		--AND UR.ReductionDate BETWEEN @StartDate AND @EndDate
		AND U.TerminatedDate IS NOT NULL
		-- AND UR.FeeSumByUnit < M.FeeByUnit -- frais non couverts
	
	SELECT
		C.ConventionNo,
		U.InforceDate,
		UT.UnitQtyReduct,
		HS.FirstName,
		HS.LastName,
		HB.FirstName,
		HB.LastName,
		A.Address,
		A.City,
		A.StateName,
		A.CountryID,
		CodePostal = CASE WHEN LEN(A.ZipCode) = 6 THEN LEFT(A.ZipCode, 3) + ' ' + RIGHT(A.ZipCode, 3) ELSE A.ZipCode END,
		A.Phone1,
		A.Phone2,
		A.Mobile,
		UR.ReductionDate,
		URR.UnitReductionReason,
		HR.FirstName,
		HR.LastName,
		HD.FirstName,
		HD.LastName,
		U.TerminatedDate,
		--CAST(Ct.Frais AS MONEY),
		ISNULL(CF.AvailableFeeAmount, 0),
		M.PmtByYearID,
		M.PmtQty,
		C.PmtTypeID,
		Depot = CAST(M.PmtRate * (U.UnitQty + ISNULL(URB.UnitRESBefore,0)) AS MONEY)
	FROM dbo.Un_Convention C
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	JOIN dbo.Mo_Adr A ON A.AdrID = HS.AdrID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
	LEFT JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Rep R ON R.RepID = U.RepID
	JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID
	LEFT JOIN @tMaxPctBoss D ON D.RepID = U.RepID
	LEFT JOIN dbo.Mo_Human HD ON HD.HumanID = D.BossID
	JOIN Un_UnitReduction UR ON UR.UnitID = U.UnitID
	JOIN #Terminated UT ON UT.UnitReductionID = UR.UnitReductionID
	LEFT JOIN Un_UnitReductionReason URR ON URR.UnitReductionReasonID = UR.UnitReductionReasonID
	LEFT JOIN ( 
		SELECT 	
			UR.UnitReductionID,
			UnitRESBefore = SUM (UR.UnitQty)
		FROM Un_UnitReduction UR
		JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
		JOIN Un_UnitReduction UR2 ON UR2.UnitID = U.UnitID AND UR2.UnitReductionID >= UR.UnitReductionID --On utilise le ID au lieu de la date pour différencer deux réduciton le même jour
		GROUP BY UR.UnitReductionID) URB ON URB.UnitReductionID = UR.UnitReductionID	
	/*LEFT JOIN (
		SELECT 
			Ct.UnitID,
			Frais = SUM(Ct.Fee)
		FROM Un_Cotisation Ct
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		WHERE Ct.EffectDate <= @EndDate
			AND ((O.OperTypeID NOT IN ('RES','TFR'))
				OR (O.OperTypeID = 'TFR' 
					OR Ct.Fee > 0))
		GROUP BY Ct.UnitID
		) Ct ON Ct.UnitID = U.UnitID*/
	LEFT JOIN (-- Retourne la somme des frais disponibles par convention
		SELECT
			CO.ConventionID,
			AvailableFeeAmount = SUM(CO.ConventionOperAmount)
		FROM Un_ConventionOper CO
		JOIN dbo.Un_Convention C ON C.ConventionID = CO.ConventionID
		WHERE CO.ConventionOperTypeID = 'FDI'
		GROUP BY CO.ConventionID				
		) CF ON CF.ConventionID = C.ConventionID
	WHERE UR.ReductionDate BETWEEN @StartDate AND @EndDate--DATEADD(MONTH,-24,GETDATE())
		AND R.BusinessStart <= @EndDate
		AND (R.BusinessEnd IS NULL OR R.BusinessEnd > @EndDate)
		AND UT.UnitQtyReduct > 0
	ORDER BY 	
		HD.LastName,
		HD.FirstName,
		HR.LastName,
		HR.FirstName,
		UR.ReductionDate,
		C.ConventionNo

	DROP TABLE #Terminated

END 

-- EXEC GU_RP_UN_VentesUnitReduction '2007-01-01', '2009-02-23'


