/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SL_UN_SearchConvWithDiffInAssOrTaxe
Description         :	Rechercher des conventions annuelles payant par chèque avec dépôt en écart en assurance et/ou en taxes
Valeurs de retours  :	Dataset :
				ConventionID	INTEGER		ID de la convention
				ConventionNo	VARCHAR(15)	Numéro de convention.
				LastName	VARCHAR(50)	Nom du souscripteur.
				FirstName	VARCHAR(35)	Prénom du souscripteur.
				InForceDate	DATETIME	Date d’entrée en vigueur du groupe d’unités
				UnitQty		MONEY		Nombre d’unités du groupe d’unités.
				OperTypeID	CHAR(3)		Type d’opération (CHQ, PRD)
				OperDate	DATETIME	Date d’opération
				fSubscInsurCalc	MONEY		Montant d’assurance souscripteur calculé.
				SubscInsur	MONEY		Montant d’assurance souscripteur de la cotisation.
				fBenefInsurCalc	MONEY		Montant d’assurance bénéficiaire calculé.
				BenefInsur	MONEY		Montant d’assurance bénéficiaire de la cotisation.
				fTaxOnInsurCalc	MONEY		Montant de taxes calculé.
				TaxOnInsur	MONEY		Montant de taxes de la cotisation.

Note                :	ADX0000831	IA	2006-11-15	Alain Quirion Création
										2018-09-11	Maxime Martel JIRA MP-699 Ajout de OpertypeID COU
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SL_UN_SearchConvWithDiffInAssOrTaxe] (
	@dtStartDate DATETIME,		-- Date de début de recherche (0 pour inclure toutes les dates)
	@dtEndDate DATETIME)		-- Date de fin de recherche (0 pour inclure toutes les dates)
AS
BEGIN
	SELECT
		C.ConventionID,
		C.ConventionNo,	
		HS.LastName,	
		HS.FirstName,	
		U.InForceDate,	
		U.UnitQty,	
		O.OperTypeID,	
		O.OperDate,	
		fSubscInsurCalc = CASE  
					WHEN U.WantSubscriberInsurance = 0 THEN 0
					WHEN MU.UnitID IS NULL THEN 
						ROUND(U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate),2)
					WHEN U.UnitQty >= 1 THEN
						ROUND(ROUND(1 * M.SubscriberInsuranceRate,2) + 
						((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate)),2)
					ELSE 
						ROUND(U.UnitQty * M.SubscriberInsuranceRate,2) 
				END,	
		CT.SubscInsur,	
		fBenefInsurCalc = ROUND(ISNULL(BI.BenefInsurRate,0),2),
		CT.BenefInsur,	
		fTaxOnInsurCalc = CASE 
					WHEN U.WantSubscriberInsurance = 0 THEN ROUND(((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
					WHEN MU.UnitID IS NULL THEN 
						ROUND((((U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate) +
						ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)							
					WHEN U.UnitQty >= 1 THEN
						ROUND((((ISNULL(BI.BenefInsurRate,0) +
						(1 * ISNULL(M.SubscriberInsuranceRate,0)) +
						((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0)))) *
						ISNULL(St.StateTaxPct,0)) + 0.0049),2)
					ELSE
						ROUND((((U.UnitQty * M.SubscriberInsuranceRate + ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0))+ 0.0049),2)
					END,	
		CT.TaxOnInsur
	FROM dbo.Un_Convention C
	JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
	LEFT JOIN Mo_State ST ON ST.StateID = S.StateID
	JOIN dbo.Mo_Human HS ON S.SubscriberID = HS.HumanID
	JOIN dbo.Mo_Human HB ON C.BeneficiaryID = HB.HumanID
	JOIN dbo.Un_Unit U ON C.ConventionID = U.ConventionID
	JOIN Un_Modal M ON M.ModalID = U.ModalID	
	LEFT JOIN Un_HalfSubscriberInsurance HSI ON HSI.ModalID = M.ModalID
	LEFT JOIN Un_BenefInsur BI ON BI.BenefInsurID = U.BenefInsurID	
	LEFT JOIN (
			SELECT MIN(UnitID) AS UnitID 
			FROM dbo.Un_Unit 
			GROUP BY ConventionID 
			) MU ON MU.UnitID = U.UnitID
	JOIN Un_Cotisation CT ON CT.UnitID = U.UnitID
	JOIN Un_Oper O ON O.OperID = CT.OperID
	WHERE C.PmtTypeID = 'CHQ'	
		AND (CT.SubscInsur <> CASE  
						WHEN U.WantSubscriberInsurance = 0 THEN 0
						WHEN MU.UnitID IS NULL THEN 
							ROUND(U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate),2)
						WHEN U.UnitQty >= 1 THEN
							ROUND(ROUND(1 * M.SubscriberInsuranceRate,2) + 
							((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate)),2)
						ELSE 
							ROUND(U.UnitQty * M.SubscriberInsuranceRate,2) 
					END
			OR CT.BenefInsur <> ROUND(ISNULL(BI.BenefInsurRate,0),2)
			OR CT.TaxOnInsur <> CASE 
						WHEN U.WantSubscriberInsurance = 0 THEN ROUND(((ISNULL(BI.BenefInsurRate,0) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)
						WHEN MU.UnitID IS NULL THEN 
							ROUND((((U.UnitQty * ISNULL(HSI.HalfSubscriberInsuranceRate,M.SubscriberInsuranceRate) +
							ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0)) + 0.0049),2)							
						WHEN U.UnitQty >= 1 THEN
							ROUND((((ISNULL(BI.BenefInsurRate,0) +
							(1 * ISNULL(M.SubscriberInsuranceRate,0)) +
							((U.UnitQty-1) * ISNULL(HSI.HalfSubscriberInsuranceRate,ISNULL(M.SubscriberInsuranceRate,0)))) *
							ISNULL(St.StateTaxPct,0)) + 0.0049),2)
						ELSE
							ROUND((((U.UnitQty * M.SubscriberInsuranceRate + ISNULL(BI.BenefInsurRate,0)) * ISNULL(St.StateTaxPct,0))+ 0.0049),2)
						END)
		AND O.OperDate BETWEEN @dtStartDate AND @dtEndDate
		AND (O.OperTypeID = 'CHQ' 
			OR O.OperTypeID = 'PRD'
			OR O.OperTypeID = 'COU')
	ORDER BY C.ConventionNo
END