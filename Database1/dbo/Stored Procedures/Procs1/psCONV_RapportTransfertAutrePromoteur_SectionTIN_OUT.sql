/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportTransfertAutrePromoteur_SectionTIN_OUT
Nom du service		: Portion TIN et OUT du rapport de transfert avec autres promoteur
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportTransfertAutrePromoteur_SectionTIN_OUT '2014-01-01' , '2014-02-28',0

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-11		Donald Huppé						Création du service		

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportTransfertAutrePromoteur_SectionTIN_OUT] 
(
	@dtDateFrom datetime,
	@dtDateTo datetime,
	@RepID int

)
AS
BEGIN

select 
	Promoteur,
	QteTransfertTIN = sum(QteTransfertTIN),
	QteUniteTIN = sum(QteUniteTIN),
	MontantTIN = sum(MontantTIN),
	QteTransfertOUT = sum(QteTransfertOUT),
	QteUniteOUT = SUM(QteUniteOUT),
	MontantOUT = sum(MntTotalOUTReel),--SUM(MontantOUT),
	DiffMontant = sum(MontantTIN) - sum(MntTotalOUTReel),--SUM(MontantOUT),
	MntTotalOUTReel = SUM(MntTotalOUTReel)

from (

	SELECT 
		Promoteur = cp.CompanyName,
		EP.ExternalPromoID,
		QteTransfertTIN = COUNT(DISTINCT O.OperID),
		QteUniteTIN = sum(U.UnitQty),
		MontantTIN = sum(t.fMarketValue),
		QteTransfertOUT = 0,
		QteUniteOUT = 0,
		MontantOUT = 0 ,
		MntTotalOUTReel = 0
		
	FROM         
		Un_Cotisation Ct
		JOIN Un_Oper O ON Ct.OperID = O.OperID 
		JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID 
		JOIN dbo.Un_Convention C ON U.ConventionID = C.ConventionID
		JOIN Un_TIN t ON O.OperId = t.OperId
		JOIN Un_ExternalPlan EX ON EX.ExternalPlanID = t.ExternalPlanID
		JOIN Un_ExternalPromo EP ON EP.ExternalPromoID = EX.ExternalPromoID
		JOIN Mo_Company cp ON cp.CompanyID = EP.ExternalPromoID
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
		LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		
	WHERE 
		O.OperTypeID = 'TIN'
		AND OC1.OperSourceID IS NULL
		AND OC2.OperSourceID IS NULL	
		AND	t.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
		and O.OperDate between @dtDateFrom and @dtDateTo
		and (U.RepID = @Repid or bu.BossID = @Repid or @Repid = 0)
	group by 
		cp.CompanyName,
		EP.ExternalPromoID

	UNION ALL
	
	SELECT 

		Promoteur = cp.CompanyName,
		EP.ExternalPromoID,
		QteTransfertTIN = 0,
		QteUniteTIN = 0,
		MontantTIN = 0,
		QteTransfertOUT = COUNT(DISTINCT O.OperID),
		QteUniteOUT = sum(Ur.UnitQty),
		MontantOUT = SUM(ot.fMarketValue),
		MntTotalOUTReel = SUM(TotalOUT)

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
				TotalOUT = sum(CotisationFrais+IQEE+Rendement+SCEE_BEC)*-1
				
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
	group by
		cp.CompanyName,
		EP.ExternalPromoID	
		
	) v
group BY
	Promoteur

order by Promoteur
end


