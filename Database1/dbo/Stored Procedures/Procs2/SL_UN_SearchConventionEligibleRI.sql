/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	SL_UN_SearchConventionEligibleRI
Description         :	
Valeurs de retours  :	Dataset de données
				IntOriginalEstimatedReimbDate	DATETIME	Date estimée originale de remboursement intégral.
				IntEstimatedReimbDate		DATETIME	Date estimée de remboursement intégral 
				ConventionID			INTEGER		ID de la convention.
				ConventionNo			VARCHAR(75)	Numéro de convention.
				SubscriberID			INTEGER		ID du souscripteur.
				SubscriberName			VARCHAR(87)	Nom, prénom du souscripteur.
				BeneficiaryID			INTEGER		ID du bénéficiaire
				BeneficiaryName			VARCHAR(87)	Nom, prénom du bénéficiaire.

Note:				ADX0001114	IA	2006-11-20	Alain Quirion		Création
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConventionEligibleRI] (				
	@SearchType CHAR(3),		-- Type de recherche effectuée ('CNo' = Numéro de Convention, 'BNa' = Nom du bénéficiaire, 'SNa' = Nom du souscripteur)
	@Search VARCHAR(75),		-- Contenu du champ pour la recherche.
	@RepID INTEGER = 0)		-- ID du représentant, 0 = tous les représentants. 

AS
BEGIN
	CREATE TABLE #TB_Rep (
		RepID INTEGER PRIMARY KEY)

	DECLARE 
		@iResult INTEGER,
		@dtRINToolLastTreatedDate DATETIME

	SELECT @dtRINToolLastTreatedDate = MAX(dtRINToolLastTreatedDate)
	FROM Un_Def

	-- INSÈRE TOUS LES REPRÉSENTANTS SOUS UN REP DANS LA TABLE TEMPORAIRE
	INSERT #TB_Rep
		EXECUTE SL_UN_BossOfRep @RepID

	IF @SearchType = 'SNa'
	BEGIN
		DECLARE @tSearchSubs TABLE (
			HumanID INTEGER PRIMARY KEY)

		-- Nom, prénom
		INSERT INTO @tSearchSubs
			SELECT 
				HumanID
			FROM dbo.Mo_Human
			WHERE LastName + ', ' + FirstName LIKE @Search

		SELECT 
			IntOriginalEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL),
			IntEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),	
			ConventionID = C.ConventionID,	
			ConventionNo = C.ConventionNo,	
			SubscriberID = C.SubscriberID,	
			SubscriberName = CASE HS.IsCompany
						WHEN 1 THEN ISNULL(HS.LastName,'')
						ELSE ISNULL(HS.LastName,'') + ', ' + ISNULL(HS.FirstName,'')
					END,	
			BeneficiaryID = C.BeneficiaryID,	
			BeneficiaryName	= ISNULL(HB.LastName,'') + ', ' + ISNULL(HB.FirstName,'')
		FROM @tSearchSubs SS
		JOIN dbo.Un_Convention C ON C.SubscriberID = SS.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		LEFT JOIN #TB_Rep B ON B.RepID = S.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID 
		LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		LEFT JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN(	
			SELECT 
				UnitID,
				MaxDate = MAX(StartDate)
			FROM Un_UnitUnitState
			GROUP BY UnitID) U2 ON U2.UnitID = U.UnitID	
		JOIN Un_UnitUnitState UUS ON UUS.UnitID = U2.UnitID AND UUS.StartDate = U2.MaxDate
		WHERE UUS.UnitStateID IN ('CPT','RIN') 	-- Capital Atteint, RI non effectué	
			AND @dtRINToolLastTreatedDate <= dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)	
			AND (B.RepID IS NOT NULL OR @RepID = 0)
		ORDER BY 
			IntEstimatedReimbDate, 
			IntOriginalEstimatedReimbDate,
			C.ConventionNo
	END
	ELSE IF @SearchType = 'BNa'
	BEGIN
		DECLARE @tSearchBenef TABLE (
			HumanID INTEGER PRIMARY KEY,
			LastName VARCHAR(50) NULL,
			FirstName VARCHAR(35) NULL )

		-- Nom, prénom
		INSERT INTO @tSearchBenef
			SELECT 
				HumanID,
				LastName,
				FirstName
			FROM dbo.Mo_Human
			WHERE LastName + ', ' + FirstName LIKE @Search

		SELECT 
			IntOriginalEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL),
			IntEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),	
			ConventionID = C.ConventionID,	
			ConventionNo = C.ConventionNo,	
			SubscriberID = C.SubscriberID,	
			SubscriberName = CASE HS.IsCompany
						WHEN 1 THEN ISNULL(HS.LastName,'')
						ELSE ISNULL(HS.LastName,'') + ', ' + ISNULL(HS.FirstName,'')
					END,	
			BeneficiaryID = C.BeneficiaryID,	
			BeneficiaryName	= ISNULL(HB.LastName,'') + ', ' + ISNULL(HB.FirstName,'')
		FROM @tSearchBenef SB
		JOIN dbo.Un_Convention C ON C.BeneficiaryID = SB.HumanID
		JOIN dbo.Un_Unit U ON U.ConventionID = C.ConventionID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		LEFT JOIN #TB_Rep B ON B.RepID = S.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID 
		LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		LEFT JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN(	
			SELECT 
				UnitID,
				MaxDate = MAX(StartDate)
			FROM Un_UnitUnitState
			GROUP BY UnitID) U2 ON U2.UnitID = U.UnitID	
		JOIN Un_UnitUnitState UUS ON UUS.UnitID = U2.UnitID AND UUS.StartDate = U2.MaxDate
		WHERE UUS.UnitStateID IN ('CPT','RIN') 	-- Capital Atteint, RI non effectué	
			AND @dtRINToolLastTreatedDate <= dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)	
			AND (B.RepID IS NOT NULL OR @RepID = 0)
		ORDER BY 
			IntEstimatedReimbDate, 
			IntOriginalEstimatedReimbDate,
			C.ConventionNo
	END
	ELSE IF @SearchType = 'CNo'
	BEGIN
		DECLARE @tSearchConv TABLE (
			ConventionID INTEGER PRIMARY KEY )

		-- Nom, prénom
		INSERT INTO @tSearchConv
			SELECT 
				ConventionID
			FROM dbo.Un_Convention 
			WHERE ConventionNo LIKE @Search

		SELECT 
			IntOriginalEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, NULL),
			IntEstimatedReimbDate =  dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust),	
			ConventionID = C.ConventionID,	
			ConventionNo = C.ConventionNo,	
			SubscriberID = C.SubscriberID,	
			SubscriberName = CASE HS.IsCompany
						WHEN 1 THEN ISNULL(HS.LastName,'')
						ELSE ISNULL(HS.LastName,'') + ', ' + ISNULL(HS.FirstName,'')
					END,	
			BeneficiaryID = C.BeneficiaryID,	
			BeneficiaryName	= ISNULL(HB.LastName,'') + ', ' + ISNULL(HB.FirstName,'')
		FROM @tSearchConv SC
		JOIN dbo.Un_Unit U ON U.ConventionID = SC.ConventionID
		JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
		JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
		LEFT JOIN #TB_Rep B ON B.RepID = S.RepID --OR B.RepID = 0 -- table temporaire, vide si aucun critère sur le directeur/représentant
		JOIN Un_Modal M ON M.ModalID = U.ModalID
		JOIN Un_Plan P ON P.PlanID = M.PlanID 
		LEFT JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
		LEFT JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
		JOIN(	
			SELECT 
				UnitID,
				MaxDate = MAX(StartDate)
			FROM Un_UnitUnitState
			GROUP BY UnitID) U2 ON U2.UnitID = U.UnitID	
		JOIN Un_UnitUnitState UUS ON UUS.UnitID = U2.UnitID AND UUS.StartDate = U2.MaxDate
		WHERE UUS.UnitStateID IN ('CPT','RIN') 	-- Capital Atteint, RI non effectué	
			AND @dtRINToolLastTreatedDate <= dbo.fn_Un_EstimatedIntReimbDate(M.PmtByYearID, M.PmtQty, M.BenefAgeOnBegining, U.InForceDate, P.IntReimbAge, U.IntReimbDateAdjust)	
			AND (B.RepID IS NOT NULL OR @RepID = 0)
		ORDER BY 
			IntEstimatedReimbDate, 
			IntOriginalEstimatedReimbDate,
			C.ConventionNo
	END

	DROP TABLE #TB_Rep 
END


