/****************************************************************************************************
Copyrights (c) 2011 Gestion Universitas inc.

Code du service		: psCONV_RapportTransfertAutrePromoteur_SectionTIN
Nom du service		: Portion TIN du rapport de transfert avec autres promoteur
But 				: 
Facette				: CONV

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psCONV_RapportTransfertAutrePromoteur_SectionTIN '2014-01-01' , '2014-02-28', 436381

Paramètres de sortie:	

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2014-04-11		Donald Huppé						Création du service		

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psCONV_RapportTransfertAutrePromoteur_SectionTIN] 
(
	@dtDateFrom datetime,
	@dtDateTo datetime,
	@RepID int

)
AS
BEGIN

	SELECT DISTINCT
		DateTransaction = O.OperDate,
		Promoteur = cp.CompanyName,
		EP.ExternalPromoID,
		Rep = hr.FirstName + ' ' + hr.LastName,
		Directeur = hb.FirstName + ' ' + hb.LastName,
		Souscripteur = hs.FirstName + ' ' + hs.LastName,
		C.ConventionNo,
		UnitQty = case when uss.UnitStateID = 'CPT' then U.UnitQty ELSE 0 end,
		Montant = t.fMarketValue
		,t.OperID
		--Epargne = ct.Cotisation,
		--Frais = Ct.Fee,
		--SCEE = t.fCESG,
		--BEC = t.fCLB,
		--RevenuAccumule = t.fAIP
		
	FROM         
		Un_Cotisation Ct
		JOIN Un_Oper O ON Ct.OperID = O.OperID 
		JOIN dbo.Un_Unit U ON Ct.UnitID = U.UnitID 
		join (
			select 
				us.unitid,
				uus.startdate,
				us.UnitStateID
			from 
				Un_UnitunitState us
				join (
					select 
					unitid,
					startdate = max(startDate)
					from un_unitunitstate
					where startDate < DATEADD(d,1 ,@dtDateTo)
					group by unitid
					) uus on uus.unitid = us.unitid 
						and uus.startdate = us.startdate 
						--and us.UnitStateID in ('epg')
			)uss ON U.unitid = uss.UnitID					
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
		JOIN dbo.Mo_Human hr ON U.RepID = hr.HumanID
		JOIN dbo.Mo_Human hb on bu.BossID = hb.HumanID
		JOIN dbo.Mo_Human hs on C.SubscriberID = hs.HumanID
		LEFT JOIN Un_OperCancelation OC1 ON OC1.OperSourceID = O.OperID
		LEFT JOIN Un_OperCancelation OC2 ON OC2.OperID = O.OperID
		
	WHERE 
		O.OperTypeID = 'TIN'
		AND OC1.OperSourceID IS NULL
		AND OC2.OperSourceID IS NULL	
		AND	t.ExternalPlanID NOT IN (86,87,88) -- Id correspondant au promoteur Universitas
		and O.OperDate between @dtDateFrom and @dtDateTo
		and (U.RepID = @Repid or bu.BossID = @Repid or @Repid = 0)
	ORDER BY
		cp.CompanyName,
		hb.FirstName + ' ' + hb.LastName,
		hr.FirstName + ' ' + hr.LastName,
		hs.FirstName + ' ' + hs.LastName

end


