/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportTransfertAutrePromoteur_SectionOUT
Nom du service		: Portion OUT du rapport de transfert avec autres promoteur
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportTransfertAutrePromoteur_SectionOUT '2014-01-01' , '2014-04-30', 0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-11		Donald Huppé						Création du service		

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportTransfertAutrePromoteur_SectionOUT] 
(
	@dtDateFrom datetime,
	@dtDateTo datetime,
	@RepID int

)
AS
BEGIN

	SELECT 
		Promoteur = cp.CompanyName,
		EP.ExternalPromoID,
		Rep = hr.FirstName + ' ' + hr.LastName,
		Directeur = hb.FirstName + ' ' + hb.LastName,
		Souscripteur = hs.FirstName + ' ' + hs.LastName,
		C.ConventionNo,
		UnitQty = sum(Ur.UnitQty),
		Montant = sum(ot.fMarketValue),
		FraisComble = case when sum(UR.FeeSumByUnit) < sum(M.FeeByUnit) then 'Non' ELSE 'Oui' end,
		DateReception = min(LEFT(CONVERT(VARCHAR, t.dtDateCreation, 120), 10)),
		OperDate = min(O.OperDate),
		CotisationFrais,
		IQEE,
		Rendement,
		SCEE_BEC,
		Total		

	FROM
		Un_Convention C	 	  
		JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
		join Un_Modal m ON u.ModalID = m.ModalID
		join Un_Cotisation ct ON u.UnitID = ct.UnitID
		JOIN Un_Oper O ON O.OperID = ct.OperID	
		join Un_OUT ot on O.OperID = ot.OperID 
		JOIN Un_ExternalPlan EX ON EX.ExternalPlanID = ot.ExternalPlanID
		JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = EX.ExternalPromoID
		JOIN Mo_Company cp ON cp.CompanyID = EP.ExternalPromoID	

		join (
			SELECT 
				ConventionNo,
				ConventionID,
				CotisationFrais = sum(CotisationFrais)*-1,
				IQEE = SUM(IQEE)*-1,
				Rendement = SUM(Rendement)*-1,
				SCEE_BEC = SUM(SCEE_BEC)*-1,
				Total = sum(CotisationFrais+IQEE+Rendement+SCEE_BEC)*-1
				
			from (

				SELECT 
					c.ConventionNo,
					c.ConventionID,
					CotisationFrais = sum(ct.Cotisation + ct.Fee),
					IQEE = 0,
					Rendement = 0,
					SCEE_BEC = 0
				FROM dbo.Un_Convention C	 	  
				JOIN dbo.Un_Unit u ON c.ConventionID = u.ConventionID
				join Un_Modal m ON u.ModalID = m.ModalID
				join Un_Cotisation ct ON u.UnitID = ct.UnitID
				JOIN Un_Oper O ON O.OperID = ct.OperID	
				join Un_OUT ot on O.OperID = ot.OperID 
				JOIN Un_ExternalPlan EX ON EX.ExternalPlanID = ot.ExternalPlanID
				JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = EX.ExternalPromoID
				left JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
				left JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE 
					o.OperTypeID = 'OUT'
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL
					AND	ot.ExternalPlanID NOT IN (86,87,88) 
					AND o.OperDate between @dtDateFrom and @dtDateTo
					--and c.ConventionNo = 'X-20120419108'
				GROUP BY
					c.ConventionNo,
					c.ConventionID

				UNION all

				SELECT 
					c.ConventionNo,
					c.ConventionID,
					CotisationFrais = 0,
					IQEE = SUM(CASE WHEN co.ConventionOperTypeID IN ('CBQ','MMQ') THEN co.ConventionOperAmount ELSE 0 end),
					Rendement = SUM(CASE WHEN co.ConventionOperTypeID not IN ('CBQ','MMQ') THEN co.ConventionOperAmount ELSE 0 end),
					SCEE_BEC = 0	
					
				FROM dbo.Un_Convention C	 	  
				join Un_ConventionOper co on c.ConventionID = co.ConventionID
				JOIN Un_Oper O ON O.OperID = co.OperID	
				join Un_OUT ot on O.OperID = ot.OperID 
				JOIN Un_ExternalPlan EX ON EX.ExternalPlanID = ot.ExternalPlanID
				JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = EX.ExternalPromoID
				left JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
				left JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE 
					o.OperTypeID = 'OUT'
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL
					AND	ot.ExternalPlanID NOT IN (86,87,88) 
					AND o.OperDate between @dtDateFrom and @dtDateTo
					--and c.ConventionNo = 'X-20120419108'
				GROUP BY
					c.ConventionNo,
					c.ConventionID

				UNION all

				SELECT 
					c.ConventionNo,
					c.ConventionID,
					CotisationFrais = 0,
					IQEE = 0,
					Rendement = 0,
					SCEE_BEC = sum(ce.fCESG + ce.fACESG + ce.fCLB)
					
				from Un_Oper o
				join Un_OUT ot on O.OperID = ot.OperID 
				join Un_CESP ce ON o.OperID = ce.OperID
				JOIN dbo.Un_Convention c ON ce.ConventionID = c.ConventionID
				left JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
				left JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
				WHERE 
					o.OperTypeID = 'OUT'
					AND OC1.OperSourceID IS NULL
					AND OC2.OperSourceID IS NULL
					AND	ot.ExternalPlanID NOT IN (86,87,88) 
					AND o.OperDate between @dtDateFrom and @dtDateTo
					--and c.ConventionNo = 'X-20120419108'
				GROUP BY
					c.ConventionNo,
					c.ConventionID	
				)v
			group BY
				ConventionNo,
				ConventionID		
		
			)mnt on mnt.ConventionID = C.ConventionID

		join (
			SELECT 
				M.UnitID,
				BossID = MAX(RBH.BossID)
			FROM (
				SELECT 
					U.UnitID,
					U.RepID,
					RepBossPct = MAX(RBH.RepBossPct)
				FROM dbo.Un_Unit U
				JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
				JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
				JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
				GROUP BY U.UnitID, U.RepID
				) M
			JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
			JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
			GROUP BY 
				M.UnitID
				)bu on U.UnitID = bu.UnitID
		JOIN dbo.Mo_Human hr ON U.RepID = hr.HumanID
		JOIN dbo.Mo_Human hb on bu.BossID = hb.HumanID
		JOIN dbo.Mo_Human hs on C.SubscriberID = hs.HumanID	
		LEFT join Un_UnitReductionCotisation urc ON urc.CotisationID = Ct.CotisationID
		LEFT JOIN Un_UnitReduction ur ON urc.UnitReductionID = ur.UnitReductionID		  
		left JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
		left JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		LEFT join (
			SELECT DISTINCT iID_Client, dtDateCreation
			FROM sgrc.dbo.tblSGRC_Tache 
			where iID_TypeTache = 60
			)t ON t.iID_Client = C.subscriberID
	WHERE O.OperTypeID = 'OUT'
		and O.OperDate between @dtDateFrom and @dtDateTo
		AND OC1.OperSourceID IS NULL
		AND OC2.OperSourceID IS NULL
		AND	ot.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
		and (U.RepID = @Repid or bu.BossID = @Repid or @Repid = 0)
	group BY
		cp.CompanyName,
		EP.ExternalPromoID,
		hr.FirstName + ' ' + hr.LastName,
		hb.FirstName + ' ' + hb.LastName,
		hs.FirstName + ' ' + hs.LastName,
		C.ConventionNo	,
		CotisationFrais,
		IQEE,
		Rendement,
		SCEE_BEC,
		Total	
	order BY
		cp.CompanyName,
		hb.FirstName + ' ' + hb.LastName,
		hr.FirstName + ' ' + hr.LastName,
		hs.FirstName + ' ' + hs.LastName
		
end


