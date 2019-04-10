/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc
Nom                 :	psGENE_RapportAssurance 
Description         :	SSRS - Rapport de souscription d'assurance
Valeurs de retours  :	Dataset 
Note                :	2017-11-24	Donald Huppé	Création jira ti-10169

exec psGENE_RapportAssuranceEncaissee '2017-09-01', '2017-09-30'

drop proc psGENE_RapportAssuranceEncaissee

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psGENE_RapportAssuranceEncaissee] (
	@StartDate DATETIME,
	@EndDate DATETIME)
AS

BEGIN



		SELECT
			Régime = p.PlanDesc,
			SubscInsur_AvecTaxe = SUM(case when Ct.TaxOnInsur <> 0 then Ct.SubscInsur else 0 end),
			BenefInsur_AvecTaxe = SUM(case when Ct.TaxOnInsur <> 0 then Ct.BenefInsur else 0 end),
			TaxOnInsur_AvecTaxe = SUM(case when Ct.TaxOnInsur <> 0 then Ct.TaxOnInsur else 0 end), 

			SubscInsur_SansTaxe = SUM(case when Ct.TaxOnInsur = 0 then Ct.SubscInsur else 0 end),
			BenefInsur_SansTaxe = SUM(case when Ct.TaxOnInsur = 0 then Ct.BenefInsur else 0 end),
			TaxOnInsur_SansTaxe = SUM(case when Ct.TaxOnInsur = 0 then Ct.TaxOnInsur else 0 end)						

		FROM dbo.Un_Unit U
		JOIN dbo.Un_Convention C ON C.conventionid = U.conventionid
		JOIN dbo.un_plan P ON P.Planid = C.Planid
		JOIN dbo.Un_Cotisation CT ON CT.UnitID = U.UnitID
		WHERE Ct.OperID IN 
				(
					SELECT O.OperID
					FROM Un_Oper O
					JOIN Un_OperType OT ON OT.OperTypeID = O.OperTypeID
					WHERE O.OperDate BETWEEN @StartDate AND @EndDate -- Opération de la période sélectionnée.
						AND( OT.TotalZero = 0 -- Exclu les opérations de type BEC ou TFR
							OR O.OperTypeID = 'TRA' -- Inclus les TRA
							)
				)

		GROUP BY
			p.plandesc
		HAVING 
			SUM(case when Ct.TaxOnInsur <> 0 then Ct.SubscInsur else 0 end) <> 0
			OR SUM(case when Ct.TaxOnInsur <> 0 then Ct.BenefInsur else 0 end) <> 0
			--OR SUM(case when Ct.TaxOnInsur <> 0 then Ct.TaxOnInsur else 0 end) <> 0
			OR SUM(case when Ct.TaxOnInsur = 0 then Ct.SubscInsur else 0 end) <> 0
			OR SUM(case when Ct.TaxOnInsur = 0 then Ct.BenefInsur else 0 end) <> 0
			--OR SUM(case when Ct.TaxOnInsur = 0 then Ct.TaxOnInsur else 0 end) <> 0
		ORDER BY
			p.plandesc
END

