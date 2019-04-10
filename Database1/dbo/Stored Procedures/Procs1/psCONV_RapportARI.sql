/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportEAFB
Nom du service		: Rapport des EAFB
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	

	EXECUTE psCONV_RapportARI '2013-04-01','2013-04-15', NULL, NULL, NULL, 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2013-04-15		Donald Huppé						Création du service			
		2013-10-17		Donald Huppé						glpi 10372 : ajout de la date du dernier PAE de la convention
				
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportARI] 
(
	@dtDateDe datetime
	,@dtDateA datetime
	,@iGroupeRegime int = NULL
	,@iYearQualif int = NULL
	,@cConventionno varchar(15) = NULL -- Filtre optionnel sur un numéro de convention
	,@iSoldeErreur int = 0 -- Flag indiquant si on veut sortir les ARi en erreur seulement
)
AS
BEGIN

	SELECT 
		
		OperDate = LEFT(CONVERT(VARCHAR, o.OperDate, 120), 10), 
		GrRegime = rr.vcDescription,
		p.OrderOfPlanInReport,
		c.ConventionNo,
		c.YearQualif,
		Souscripteur = hs.lastname + ', ' + hs.FirstName,
		INM = sum(CASE WHEN co.ConventionOperTypeID = 'INM' THEN co.ConventionOperAmount ELSE 0 END),
		ITR = sum(CASE WHEN co.ConventionOperTypeID = 'ITR' THEN co.ConventionOperAmount ELSE 0 END),
		INS = sum(CASE WHEN co.ConventionOperTypeID = 'INS' THEN co.ConventionOperAmount ELSE 0 END),
		ISPlus = sum(CASE WHEN co.ConventionOperTypeID = 'IS+' THEN co.ConventionOperAmount ELSE 0 END),
		IBC = sum(CASE WHEN co.ConventionOperTypeID = 'IBC' THEN co.ConventionOperAmount ELSE 0 END),
		IST = sum(CASE WHEN co.ConventionOperTypeID = 'IST' THEN co.ConventionOperAmount ELSE 0 END),
		MIM = sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END),
		ICQ = sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END),
		IMQ = sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END),
		III = sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END),
		IIQ = sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END),
		IQI = sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END),
		EAFB = ISNULL(oa.OtherAccountOperAmount,0),
		O.OperID,
		DateDernierPAE = LEFT(CONVERT(VARCHAR, pae.DateDernierPAE, 120), 10)
	from 
		Un_Convention c
		JOIN dbo.Mo_Human hs ON c.SubscriberID = hs.HumanID
		join Un_Plan p ON c.PlanID = p.PlanID
		join tblCONV_RegroupementsRegimes rr ON rr.iID_Regroupement_Regime = p.iID_Regroupement_Regime
		join Un_ConventionOper co on c.ConventionID = co.Conventionid	
		JOIN Un_Oper o ON co.OperID = o.OperID
		left join Un_OtherAccountOper oa ON o.OperID = oa.OperID
		left join (
			select 
				c.ConventionID,
				DateDernierPAE = Max(o.OperDate)
			from dbo.Un_Convention c
			join dbo.Un_Scholarship s ON c.ConventionID = s.ConventionID
			join dbo.Un_ScholarshipPmt sp ON s.ScholarshipID = sp.ScholarshipID
			join dbo.Un_Oper o ON sp.OperID = o.OperID
			left JOIN dbo.Un_OperCancelation oc1 ON oc1.OperSourceID = o.OperID
			left JOIN dbo.Un_OperCancelation oc2 ON o.OperID = oc2.OperID
			where oc1.OperSourceID is NULL
			and oc2.OperID is NULL
			group by c.ConventionID
			)pae on pae.ConventionID = c.ConventionID
	WHERE 
		o.OperTypeID = 'ARI'
		and o.OperDate between @dtDateDe and @dtDateA
		and (RR.iID_Regroupement_Regime = @iGroupeRegime OR isnull(@iGroupeRegime,0) = 0)
		AND (c.ConventionNo = @cConventionno or @cConventionno is NULL)
		and (c.YearQualif = @iYearQualif or @iYearQualif is NULL)
	GROUP BY
		O.OperID,
		LEFT(CONVERT(VARCHAR, o.OperDate, 120), 10), 
		rr.vcDescription,
		p.OrderOfPlanInReport,
		c.ConventionNo,
		c.YearQualif,
		hs.lastname + ', ' + hs.FirstName,
		ISNULL(oa.OtherAccountOperAmount,0),
		LEFT(CONVERT(VARCHAR, pae.DateDernierPAE, 120), 10)
	having
		(
			(
			sum(CASE WHEN co.ConventionOperTypeID = 'INM' THEN co.ConventionOperAmount ELSE 0 END) +
			sum(CASE WHEN co.ConventionOperTypeID = 'ITR' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'INS' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IS+' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IBC' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IST' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'MIM' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'ICQ' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IMQ' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'III' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IIQ' THEN co.ConventionOperAmount ELSE 0 END)+
			sum(CASE WHEN co.ConventionOperTypeID = 'IQI' THEN co.ConventionOperAmount ELSE 0 END)+
			ISNULL(oa.OtherAccountOperAmount,0)
			) <> 0
			
		or
			(@iSoldeErreur = 0)
		
		)

End


