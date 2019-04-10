/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_TRA_INM
Description         :	Rapport pour les finances sur les TRA INM (2ième SP)
Valeurs de retours  :	Dataset 
Note                :	2009-09-21	Donald Huppé	Créaton
						2010-06-10	Donald Huppé	Ajout des régime et groupe de régime

exec GU_RP_TRA_INM '2008-01-01'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[GU_RP_TRA_INM] (
	@StartDate DATETIME) -- On prend l'année du @StartDate dans les paramètre du rapport
AS
BEGIN

-- TRA_INM
	SELECT 
		Regime = P.PlanDesc,
		GrRegime = RR.vcDescription,
		OrderOfPlanInReport,	
		Year(OperDate) AS Ans, 
		Month(OperDate) AS Mois, 
		co.ConventionOperTypeID, 
		copt.ConventionOperTypeDesc, 
		Sum(co.ConventionOperAmount) AS SommeDeConventionOperAmount
	FROM Un_Oper op
	JOIN Un_ConventionOper co ON op.OperID = co.OperID
	JOIN Un_ConventionOperType copt ON co.ConventionOperTypeID = copt.ConventionOperTypeID
	JOIN dbo.Un_Convention c ON c.ConventionID = co.ConventionID
	JOIN UN_PLAN P ON P.PlanID = C.PlanID
	JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
	WHERE 
		op.OperTypeID='TRA'
	GROUP BY 
		Year(OperDate), 
		Month(OperDate), 
		co.ConventionOperTypeID, 
		copt.ConventionOperTypeDesc,
		P.PlanDesc,
		RR.vcDescription,
		OrderOfPlanInReport
	HAVING Year(OperDate)=year(@StartDate)
	ORDER BY RR.vcDescription,Month(OperDate)

end


