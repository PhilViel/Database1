/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_TRA
Description         :	Rapport pour les finances sur les TRA (1ère SP)
Valeurs de retours  :	Dataset 
Note                :	2009-09-21	Donald Huppé	Créaton
						2010-06-10	Donald Huppé	Ajout des régime et groupe de régime
						
exec GU_RP_TRA '2008-01-01', '2008-12-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_TRA] (
	@StartDate DATETIME,
	@EndDate DATETIME)
AS
BEGIN

-- TRA

	SELECT 
		Regime = P.PlanDesc,
		GrRegime = RR.vcDescription,
		OrderOfPlanInReport,			
		Month(OperDate) AS Mois, 
		Sum(ct.Cotisation) AS SommeDeCotisation, 
		Sum(ct.Fee) AS SommeDeFee, 
		Sum(ct.BenefInsur) AS SommeDeBenefInsur, 
		Sum(ct.SubscInsur) AS SommeDeSubscInsur, 
		Sum(ct.TaxOnInsur) AS SommeDeTaxOnInsur
	FROM dbo.Un_Unit U
	JOIN Un_Cotisation ct ON U.UnitID = ct.UnitID
	JOIN Un_Oper op ON ct.OperID = op.OperID
	JOIN Un_OperType opt ON op.OperTypeID = opt.OperTypeID
	JOIN dbo.Un_Convention c ON u.ConventionID = c.ConventionID
	JOIN UN_PLAN P ON P.PlanID = C.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	WHERE 
		op.OperDate Between @StartDate and @EndDate 
		AND op.OperTypeID='TRA'
	GROUP BY 
		P.PlanDesc,
		RR.vcDescription,
		OrderOfPlanInReport,
		Month(OperDate)

end


