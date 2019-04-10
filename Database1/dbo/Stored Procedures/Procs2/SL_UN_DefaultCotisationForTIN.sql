/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_DefaultCotisationForTIN
Description         :	Procédure retournant le montant en frais, épargnes réparti pour une liste de groupes d'unités
Valeurs de retours  :	Dataset de données
									UnitID : ID unique du groupe d'unités
									ConventionID : ID unique de la convention
									ConventionNo : Numéro de convention
									SubscriberName : Nom, Prénom du souscripteur
									BeneficiaryName : Nom, Prénom du bénéficiaire
									InForceDate : Date de vigueur
									UnitQty : Nombre d'unité du groupe d'unités
									EffectDate : Date effective
									Cotisation : Montant de cotisation
									Fee : Montant de frais
									SubscInsur : Montant d'assurance souscripteur
									BenefInsur : Montant d'assurance bénéficiaire
									TaxOnInsur : Montant de taxes sur l'assurance

Note                :	ADX0000925	IA	2006-05-18	Bruno Lapointe			Création
 ***********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_DefaultCotisationForTIN] (
	@cIDType CHAR(3), -- Donne le type de ID (SUB = SubscriberID, GUN = UnitID, CON = ConventionID)
	@iID INTEGER, -- ID du souscripteur ou de la convention ou du groupe d'unités selon le @cIDType
	@OperDate DATETIME, -- Date de l'opération
	@fAmount MONEY ) -- Montant à répartir parmi les groupes d'unités
AS
BEGIN
	DECLARE
		@iCntUnitID INTEGER,
		@iMinUnitID INTEGER,
		@fUnitAmount MONEY,
		@fRest MONEY

	-- Bâtis une table des groupes d'unités avec la liste de IDs passer en paramètre  
	CREATE TABLE #Unit (
		UnitID INTEGER PRIMARY KEY)

	IF @cIDType = 'SUB' 
		INSERT INTO #Unit
			SELECT DISTINCT
				U.UnitID
			FROM dbo.Un_Unit U
			JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
			WHERE C.SubscriberID = @iID
	ELSE IF @cIDType = 'CON'
		INSERT INTO #Unit
			SELECT DISTINCT
				UnitID
			FROM dbo.Un_Unit 
			WHERE ConventionID = @iID
	ELSE IF @cIDType = 'GUN'
		INSERT INTO #Unit
			SELECT DISTINCT
				UnitID
			FROM dbo.Un_Unit 
			WHERE UnitID = @iID

	SELECT
		@iCntUnitID = COUNT(UnitID),
		@iMinUnitID = MIN(UnitID)
	FROM #Unit

	-- Montant par unité
	SET @fUnitAmount = FLOOR(@fAmount/@iCntUnitID*100)/100
	-- Montant restant a distribuer suite à l'arrondissement
	SET @fRest = @fAmount - (@fUnitAmount*@iCntUnitID)

	SELECT 
		U.UnitID,
		C.ConventionID,
		C.ConventionNo,
		SubscriberName = HS.LastName+', '+HS.FirstName,
		BeneficiaryName = HB.LastName+', '+HB.FirstName,
		U.InForceDate,
		U.UnitQty,
		EffectDate = @OperDate,
		Cotisation = 
			CASE 
				WHEN (dbo.FN_UN_EstimatedFee( -- Calcul le montant de frais total
							ISNULL(Ct.Cotisation+Ct.Fee,0) + 
								CASE 
									WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
								ELSE @fUnitAmount
								END,
							U.UnitQty,
							M.FeeSplitByUnit,
							M.FeeByUnit) - 
						 ISNULL(Ct.Fee,0)) >= 0 THEN 
					CASE 
						WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
					ELSE @fUnitAmount
					END - -- Montant d'un dépôt en cotisations et frais combinés
					(dbo.FN_UN_EstimatedFee( -- Calcul le montant de frais total
						ISNULL(Ct.Cotisation+Ct.Fee,0) + 
							CASE 
								WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
							ELSE @fUnitAmount
							END,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit) - 
					 ISNULL(Ct.Fee,0)) -- Déduit les frais déjà déposé
			ELSE 
				CASE 
					WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
				ELSE @fUnitAmount
				END
			END,
		Fee = 
			CASE 
				WHEN (dbo.FN_UN_EstimatedFee( -- Calcul le montant de frais total
							ISNULL(Ct.Cotisation+Ct.Fee,0) + 
								CASE 
									WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
								ELSE @fUnitAmount
								END,
							U.UnitQty,
							M.FeeSplitByUnit,
							M.FeeByUnit) - 
						 ISNULL(Ct.Fee,0)) >= 0 THEN 
					dbo.FN_UN_EstimatedFee( -- Calcul le montant de frais total
						ISNULL(Ct.Cotisation+Ct.Fee,0) +
							CASE 
								WHEN U.UnitID = @iMinUnitID THEN @fUnitAmount + @fRest
							ELSE @fUnitAmount
							END,
						U.UnitQty,
						M.FeeSplitByUnit,
						M.FeeByUnit) - 
					ISNULL(Ct.Fee,0) -- Déduit les frais déjà déposé
			ELSE 0
			END,
		SubscInsur = 0,
		BenefInsur = 0,
		TaxOnInsur = 0,
		bIsContestWinner = ISNULL(SS.bIsContestWinner,0)
	FROM dbo.Un_Unit U
	JOIN #Unit T ON T.UnitID = U.UnitID -- Filtre selon la liste des passé en paramètre
	JOIN dbo.Un_Convention C ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID
	JOIN Un_Plan P ON P.PlanID = M.PlanID
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	JOIN dbo.Mo_Human HB ON HB.HumanID = C.BeneficiaryID
	JOIN dbo.Mo_Human HS ON HS.HumanID = C.SubscriberID
	LEFT JOIN Un_SaleSource SS ON SS.SaleSourceID = U.SaleSourceID
	LEFT JOIN (-- Retourne le total des cotisations et de frais par unité
		SELECT 
			Ct.UnitID, 
			Cotisation = SUM(Ct.Cotisation), 
			Fee = SUM(Ct.Fee)
		FROM #Unit U
		JOIN Un_Cotisation Ct ON Ct.UnitID = U.UnitID
		JOIN Un_Oper O ON O.OperID = Ct.OperID
		LEFT JOIN Un_OperBankFile OBF ON OBF.OperID = O.OperID
		WHERE	( O.OperTypeID = 'CPA' 
				AND ISNULL(OBF.OperID, 0) > 0
				)
			OR O.OperDate < = GETDATE()
		GROUP BY CT.UnitID
		) Ct ON Ct.UnitID = U.UnitID
	WHERE ISNULL(Ct.Cotisation + Ct.Fee,0) < ROUND(M.PmtRate * U.UnitQty,2) * M.PmtQty -- Pas les groupes d'unité dont le montant est souscrit
	 	AND U.TerminatedDate IS NULL -- Pas de groupe d'unités totalement résilié.
		AND(	( ISNULL(U.PmtEndConnectID,0) = 0 -- Pas de fin de paiement forcée.
				AND U.ActivationConnectID IS NOT NULL -- Groupe d'unités doit être activé
				)
			OR @cIDType = 'GUN'
			)

	DROP TABLE #Unit
END


