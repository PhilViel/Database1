/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: psOPER_RapportSubventionsRecuesRetournees
Nom du service		: Rapport des subventions reçues et retournée au PCEE et IQEE
But 				: 
Facette				: 

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
		  				@dtDateDe					Date minimum d'opération
		  				@dtDateA					Date maximum d'opération	
						@iType						1 = PCEE seulement
													2 = IQEE seulement
													3 = PCEE et IQEE
Exemple d’appel		:	

exec psOPER_RapportSubventionsRecuesRetournees '2013-01-01','2014-01-15',0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-12-04		Donald Huppé						Création du service			
		2014-01-15		Donald Huppé						ajout des montant de TRI				
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportSubventionsRecuesRetournees] 
(
	@dtDateDe datetime,
	@dtDateA datetime,
	@iID_Regroupement_Regime int
)
AS
BEGIN

select *
from (

	SELECT 
	
		v.EntreeSortie,
		v.EntreeSortieTxt,
		p.OrderOfPlanInReport,
		--rr.iID_Regroupement_Regime,
		iID_Regroupement_Regime = CASE 
					WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 31 --'Individuel RIO' 
					WHEN rr.iID_Regroupement_Regime = 3 THEN 3 --'Individuel Autre'
					ELSE rr.iID_Regroupement_Regime
					end,
		
		--GroupeRegime = rr.vcDescription,
		GroupeRegime = CASE 
					WHEN rr.iID_Regroupement_Regime = 3 and r.iID_Convention_Destination IS NOT NULL AND (c.ConventionNo LIKE 'T%' or c.ConventionNo LIKE 'M%' ) THEN 'Individuel RIO' 
					WHEN rr.iID_Regroupement_Regime = 3 THEN 'Individuel Autre'
					ELSE rr.vcDescription
					end,
		c.YearQualif,
		C.ConventionNo,
		SCEE = SUM(SCEE),
		SCEEPlus = SUM(SCEEPlus),
		BEC = SUM(BEC),
		IQEE = SUM(IQEE),
		IQEEPlus = sum(IQEEPlus)
		
		,SCEE_TRI =  SUM(SCEE_TRI),
		SCEEPlus_TRI = SUM(SCEEPlus_TRI),
		BEC_TRI = SUM(BEC_TRI),
		PCEEtotal_TRI = SUM(SCEE_TRI+SCEEPlus_TRI+BEC_TRI)
		,IQEEtotal_TRI = SUM(IQEE_TRI)
		
	FROM
		(
		------------------------ PCEE --------------------------
		SELECT
			CE.ConventionID,
			O.OPERID,
			EntreeSortie = 0,
			EntreeSortieTxt = 'Reçues',
			SCEE = case when CE.fCESG > 0 THEN CE.fCESG ELSE 0 end,
			SCEEPlus = case when CE.fACESG > 0 THEN CE.fACESG ELSE 0 end,
			BEC = case when CE.fCLB > 0 THEN CE.fCLB ELSE 0 end,

			IQEE = 0,
			IQEEPlus = 0

			,SCEE_TRI =  0,
			SCEEPlus_TRI = 0,
			BEC_TRI = 0
			
			,IQEE_TRI =  0
			
		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID
		JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
		WHERE O.OperTypeID = 'SUB'
			--AND c.ConventionNo = 'R-20081215065'
			AND (CE.fCESG > 0 OR CE.fACESG > 0 or CE.fCLB > 0)
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			--and @iType in (1,3)
		
		UNION ALL	
			
		SELECT
			CE.ConventionID,
			O.OPERID,
			EntreeSortie = 0,
			EntreeSortieTxt = 'Reçues',	
		
			SCEE = 0,
			SCEEPlus = 0,
			BEC = 0,

			IQEE = 0,
			IQEEPlus = 0
			
			,SCEE_TRI =  CE.fCESG,
			SCEEPlus_TRI = CE.fACESG,
			BEC_TRI = CE.fCLB
			
			,IQEE_TRI =  0

		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID
		JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
		join (
			SELECT DISTINCT tri.iID_Convention_Destination from tblOPER_OperationsRIO tri where tri.bRIO_QuiAnnule = 0 and tri.OperTypeID = 'TRI'
			)t ON t.iID_Convention_Destination = c.ConventionID
		WHERE 
			O.OperTypeID = 'TRI'
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			
		UNION ALL
		
		SELECT
			CE.ConventionID,
			O.OPERID,
			EntreeSortie = 1,
			EntreeSortieTxt = 'Retournées',
			SCEE = case when CE.fCESG < 0 THEN CE.fCESG ELSE 0 end,
			SCEEPlus = case when CE.fACESG < 0 THEN CE.fACESG ELSE 0 end,
			BEC = case when CE.fCLB < 0 THEN CE.fCLB ELSE 0 end,
			
			IQEE = 0,
			IQEEPlus = 0
			
			,SCEE_TRI =  0,
			SCEEPlus_TRI = 0,
			BEC_TRI = 0
			
			,IQEE_TRI =  0
						
		FROM Un_CESP CE
		JOIN Un_Oper O ON O.OperID = CE.OperID
		JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
		WHERE O.OperTypeID = 'SUB'
			AND (CE.fCESG < 0 OR CE.fACESG < 0 or CE.fCLB < 0)
			--AND c.ConventionNo = 'R-20081215065'
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			--and @iType in (1,3)
			
		----------------------------- IQEE -------------------------------	
		
		UNION ALL	
				
		select 
			co.ConventionID,
			o.OperID,
			EntreeSortie = 0,
			EntreeSortieTxt = 'Reçues',	
			
			SCEE = 0,
			SCEEPlus = 0,
			BEC = 0,
			
			IQEE = case WHEN co.ConventionOperTypeID = 'CBQ' then co.ConventionOperAmount ELSE 0 end,
			IQEEPlus = case WHEN  co.ConventionOperTypeID = 'MMQ' then co.ConventionOperAmount ELSE 0 end
			
			,SCEE_TRI =  0,
			SCEEPlus_TRI = 0,
			BEC_TRI = 0
			
			,IQEE_TRI =  0
			
		FROM 
			Un_ConventionOper co
			join Un_Oper o ON co.OperID = o.OperID
		where 
			o.OperTypeID = 'IQE'
			and co.ConventionOperTypeID IN ('CBQ','MMQ')
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			AND co.ConventionOperAmount > 0
			--and @iType in (2,3)

		UNION ALL	
				
		select 
			co.ConventionID,
			o.OperID,
			EntreeSortie = 0,
			EntreeSortieTxt = 'Reçues',	
			
			SCEE = 0,
			SCEEPlus = 0,
			BEC = 0,
			
			IQEE = 0,
			IQEEPlus = 0
			
			,SCEE_TRI =  0,
			SCEEPlus_TRI = 0,
			BEC_TRI = 0
			
			,IQEE_TRI = co.ConventionOperAmount
			
		FROM 
			Un_ConventionOper co
			join Un_Oper o ON co.OperID = o.OperID
			join (
				SELECT DISTINCT tri.iID_Convention_Destination from tblOPER_OperationsRIO tri where tri.bRIO_QuiAnnule = 0 and tri.OperTypeID = 'TRI'
				)t ON t.iID_Convention_Destination = co.ConventionID
		WHERE 
			o.OperTypeID = 'TRI'
			and co.ConventionOperTypeID IN ('CBQ','MMQ')
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			
		UNION ALL	
			
		select 
			co.ConventionID,
			o.OperID,
			EntreeSortie = 1,
			EntreeSortieTxt = 'Retournées',	
			
			SCEE = 0,
			SCEEPlus = 0,
			BEC = 0,
			
			IQEE = case WHEN co.ConventionOperTypeID = 'CBQ' then co.ConventionOperAmount ELSE 0 end,
			IQEEPlus = case WHEN  co.ConventionOperTypeID = 'MMQ' then co.ConventionOperAmount ELSE 0 end
			
			,SCEE_TRI =  0,
			SCEEPlus_TRI = 0,
			BEC_TRI = 0
			
			,IQEE_TRI =  0
						
		FROM 
			Un_ConventionOper co
			join Un_Oper o ON co.OperID = o.OperID
		where 
			o.OperTypeID = 'IQE'
			and co.ConventionOperTypeID IN ('CBQ','MMQ')
			AND LEFT(CONVERT(VARCHAR, O.OperDate, 120), 10)BETWEEN @dtDateDe AND @dtDateA
			AND co.ConventionOperAmount < 0
			--and @iType in (2,3)
			
		)v
	JOIN dbo.Un_Convention c ON V.ConventionID = c.ConventionID
	join Un_Plan p ON c.PlanID = p.PlanID
	join tblCONV_RegroupementsRegimes rr on rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
	left join (
		SELECT DISTINCT rio.iID_Convention_Destination, c.ConventionNo
		from tblOPER_OperationsRIO rio
		JOIN dbo.Un_Convention c ON rio.iID_Convention_Destination = c.ConventionID
		where OperTypeID IN ( 'RIO','RIM')
		--AND rio.bRIO_Annulee = 0
		and rio.bRIO_QuiAnnule = 0
			) r on v.conventionid = r.iID_Convention_Destination
	--where (rr.iID_Regroupement_Regime = @iID_Regroupement_Regime or @iID_Regroupement_Regime = 0)
	GROUP BY
		v.EntreeSortie,
		v.EntreeSortieTxt,
		p.OrderOfPlanInReport,
		rr.iID_Regroupement_Regime,
		rr.vcDescription,
		c.YearQualif,
		C.ConventionNo,
		r.iID_Convention_Destination
	)T
	where (iID_Regroupement_Regime = @iID_Regroupement_Regime or @iID_Regroupement_Regime = 0)
	
order by T.iID_Regroupement_Regime
-- select * from tblCONV_RegroupementsRegimes

end


