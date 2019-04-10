/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionWithAvailableFee
Description         :	RRecherche des conventions avec frais disponibles. 
Valeurs de retours  :	Dataset contenant les données :
				ConventionID		INTEGER		ID de la convention.
				ConventionNo		VARCHAR(75)	Numéro de convention
				SubscriberID		INTEGER		ID du souscripteur.
				BeneficiaryID		INTEGER		ID du bénéficiaire.
				SubscriberName		VARCHAR(77)	Nom, prénom du souscripteur.
				BeneficiaryName		VARCHAR(77)	Nom, prénom du bénéficiaire
				AvailableFee		MONEY		Montant des frais disponibles sur une convention. 
				NbUnitOfAvailableFee	MONEY		Nombre d’unité correspondant aux frais disponibles de la convention. 

Note                :		ADX0001119	IA	2006-10-31	Alain Quirion			Création
											2012-09-26	Donald Huppé			Dans SR, Faire sum(FeeSumByUnit) au lieu de regrouper sur FeeSumByUnit (suite au GLPI 8249)
*********************************************************************************************************************/

-- EXEC SL_UN_SearchConventionWithAvailableFee 'CNo','U-20071127014',0

CREATE PROCEDURE [dbo].[SL_UN_SearchConventionWithAvailableFee](
	@cSearchType CHAR(3),	-- Type de recherche : BNa = Nom, prénom du bénéficiaire. CNo = Numéro de convention, SNa = Nom, prénom du souscripteur
	@vcSearch VARCHAR(75),	-- Valeur recherchée
	@iRepID	INTEGER 	-- ID du représentant (Limiter les résultats selon un représentant, 0 pour tous)
)
AS
BEGIN
	CREATE TABLE #TB_Rep (
		iRepID INTEGER PRIMARY KEY)

	CREATE TABLE #TB_Conv (
		iConventionID INTEGER PRIMARY KEY,
		vcConventionNo VARCHAR(30),
		iSubscriberID INTEGER,
		iBeneficiaryID INTEGER,
		vcSubscriberName VARCHAR(75),
		vcBeneficiaryName VARCHAR(75))

	-- INSÈRE TOUS LES REPRÉSENTANTS SOUS UN REP DANS LA TABLE TEMPORAIRE
	INSERT #TB_Rep
		EXECUTE SL_UN_BossOfRep @iRepID

	-- Restreint la recherche au convention qui correspondent au critère de recherche
	INSERT INTO #TB_Conv
	SELECT DISTINCT 
			C.ConventionID,
			C.ConventionNo,
			C.SubscriberID,
			C.BeneficiaryID,
			SubscriberName = CASE 
						WHEN HS.IsCompany = 1 THEN HS.LastName
						ELSE HS.LastName + ', ' + HS.FirstName
					END,
			BeneficiaryName = HB.LastName + ', ' + HB.FirstName
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN #TB_Rep R ON S.RepID = R.iRepID --OR R.iRepID = 0 
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	WHERE CASE @cSearchType 
			WHEN 'BNa' THEN 
				ISNULL(HB.LastName, '') + ', ' + ISNULL(HB.FirstName, '')
			WHEN 'CNo' THEN 
				C.ConventionNo
			WHEN 'SNa' THEN 
				ISNULL(HS.LastName, '') + ', ' + ISNULL(HS.FirstName, '')
		END LIKE @vcSearch 	
		AND (R.iRepID IS NOT NULL OR @iRepID = 0	)

	SELECT 
		C.iConventionID,
		C.vcConventionNo,
		C.iSubscriberID,
		C.iBeneficiaryID,
		vcSubscriberName,
		vcBeneficiaryName,
		AvailableFee = ISNULL(MIN(CF.AvailableFeeAmount), 0),
		NbUnitOfAvailableFee = SUM(ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0))
	FROM #TB_Conv C
	LEFT JOIN (-- Retourne le total des frais disponibles par convention
		SELECT 
			CO.ConventionID,
			AvailableFeeAmount = SUM(ISNULL(ConventionOperAmount,0))
		FROM Un_ConventionOper CO
		JOIN #TB_Conv TC ON TC.iConventionID = CO.ConventionID
		WHERE ConventionOperTypeID = 'FDI'
		GROUP BY CO.ConventionID
		) CF ON CF.ConventionID = C.iConventionID
	LEFT JOIN ( -- Unité résiliés
			SELECT 
				U.ConventionID, 
				UnitRes = SUM(UR.UnitQty),
				--FeeSumByUnit,
				FeeSumByUnit = sum(FeeSumByUnit)
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			JOIN #TB_Conv  TC ON TC.iConventionID = U.ConventionID
			GROUP BY U.ConventionID/*, FeeSumByUnit*/) SR ON SR.ConventionID = C.iConventionID
	LEFT JOIN ( -- Unité utilisés
			SELECT 
				U.ConventionID, 
				UnitUse = SUM(A.fUnitQtyUse)
			FROM Un_UnitReduction UR
			JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID	
			JOIN #TB_Conv  TC ON TC.iConventionID = U.ConventionID
			GROUP BY U.ConventionID) SU ON SU.ConventionID = C.iConventionID	
	WHERE 1=1
		and ISNULL(CF.AvailableFeeAmount, 0) > 0 	-- Dont les frais disponibles sont supérieurs à 0
		AND (ISNULL(SR.UnitRes,0) - ISNULL(SU.UnitUse,0)) <> 0 --Supprime les autres unités résiliés de la même convention qui n'ont plus de frais disponibles
		AND ISNULL(SR.FeeSumByUnit,0) <> 0
	GROUP BY
		C.iConventionID,
		C.vcConventionNo,
		C.iSubscriberID,
		C.iBeneficiaryID,
		vcSubscriberName,
		vcBeneficiaryName
	ORDER BY C.vcConventionNo

/*
		SELECT 
			CO.ConventionID,
			AvailableFeeAmount = SUM(ISNULL(ConventionOperAmount,0))
		FROM Un_ConventionOper CO
		where CO.ConventionID = 304064
		and ConventionOperTypeID = 'FDI'
		GROUP BY CO.ConventionID

		SELECT 
			CO.ConventionID,
			o.OperDate,
			AvailableFeeAmount = ConventionOperAmount
		FROM Un_ConventionOper CO
		join Un_Oper o ON CO.OperID = o.OperID
		WHERE ConventionOperTypeID = 'FDI' and CO.ConventionID = 304064
		---GROUP BY CO.ConventionID

			SELECT 
				U.ConventionID, 
				UnitRes = SUM(UR.UnitQty),
				FeeSumByUnit = sum(FeeSumByUnit)
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			where U.ConventionID = 304064
			GROUP BY U.ConventionID, FeeSumByUnit

			SELECT 
				U.ConventionID, 
				UnitRes = SUM(UR.UnitQty),
				FeeSumByUnit = sum(FeeSumByUnit)
			FROM Un_UnitReduction UR
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID
			JOIN #TB_Conv  TC ON TC.iConventionID = U.ConventionID
			GROUP BY U.ConventionID, FeeSumByUnit
			
			SELECT 
				U.ConventionID, 
				UnitUse = SUM(A.fUnitQtyUse)
			FROM Un_UnitReduction UR
			JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID	
			JOIN #TB_Conv  TC ON TC.iConventionID = U.ConventionID
			GROUP BY U.ConventionID

			SELECT 
				U.ConventionID, 
				A.*
				,UR.*
			FROM Un_UnitReduction UR
			left JOIN Un_AvailableFeeUse A ON A.UnitReductionID = UR.UnitReductionID
			JOIN dbo.Un_Unit U ON U.UnitID = UR.UnitID	
			where  U.ConventionID = 304064
			
	select * from Un_Oper where OperID in (22616486,22616489)
*/
	DROP TABLE #TB_Rep 
	DROP TABLE #TB_Conv
END


