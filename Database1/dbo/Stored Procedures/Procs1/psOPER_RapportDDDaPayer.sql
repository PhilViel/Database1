/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportDDDaPayer
Description         :	Rapport des DDD à payer
Valeurs de retours  :	Dataset de données

Note                :	
					2014-09-23	Donald Huppé	Création 	
					2014-10-27	Donald Huppé	GLI 12730 : exclure des DDD confirmées
					2014-11-06	Donald Huppé	glpi 12797 : changer appel de fntOPER_ObtenirEtatDDD	
					2015-10-23	Donald Huppé	Exclure les DDD associé aux opérations annulées
					2018-11-28	Donald Huppé	Ajout des frais
					2018-11-28	Donald Huppé	JIRA PROD-12948 : AJOUT de EpargneRIN et FraisRIN
					2019-01-11	Donald Huppé	suite à JIRA PROD-12948 : faire une somme et regroupemement de EpargneRIN et FraisRIN

exec psOPER_RapportDDDaPayer '2018-12-31'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportDDDaPayer] (
	@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	)
AS
BEGIN

	select DISTINCT
		ddd.id,
		TypeDemande = o.OperTypeID,
		Convention = case 
				when o.OperTypeID = 'PAE' then cPAE.ConventionNo
				when o.OperTypeID = 'RIN' then cRIN.ConventionNo
				end,
		Regime = rr.vcDescription,
		p.OrderOfPlanInReport,
		Etat = t.Etat,
		ddd.Montant
		,ddd.InfoDemandeParent
		,EpargneRIN = SUM(CASE WHEN o.OperTypeID = 'RIN' THEN CT.Cotisation * -1 ELSE 0 END)
		,FraisRIN = SUM(CASE WHEN o.OperTypeID = 'RIN' THEN CT.Fee * -1 ELSE 0 END)
	from DecaissementDepotDirect ddd
	join DBO.fntOPER_ObtenirEtatDDD (NULL, @dtDateTo) t on ddd.Id = t.id
	join un_oper o on ddd.IdOperationFinanciere = o.OperID

	left join Un_OperCancelation oc1 on oc1.OperSourceID = o.OperID
	left join un_oper oCancel on oCancel.operID = oc1.OperID and cast(oCancel.OperDate as date) <= cast(@dtDateTo as date)

	-- lien vers le RIN
	left join Un_Cotisation ct on o.OperID = ct.OperID and o.OperTypeID = 'RIN'
	left JOIN dbo.Un_Unit uRIN on ct.UnitID = uRIN.UnitID
	left JOIN dbo.Un_Convention cRIN on uRIN.ConventionID = cRIN.ConventionID
	
	-- Lien vers le PAE
	left join Un_ConventionOper CoPAE on CoPAE.OperID = o.OperID and o.OperTypeID = 'PAE'
	left JOIN dbo.Un_Convention cPAE on CoPAE.ConventionID = cPAE.ConventionID

	left join Un_Plan p on cRIN.PlanID = p.PlanID or cPAE.PlanID = p.PlanID
	left join tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime

	left join ( -- décaissée active
		select * 
		from DecaissementDepotDirect 
		where 
			--avec une date de décaissement
			isnull(LEFT(CONVERT(VARCHAR, DateDecaissement, 120), 10),'9999-12-31') <= @dtDateTo
			-- sans date finale
			and isnull(LEFT(CONVERT(VARCHAR, DateFinalise, 120), 10),'9999-12-31') > @dtDateTo
			-- sans date de non décaissement
			and isnull(LEFT(CONVERT(VARCHAR, DateRejete, 120), 10),'9999-12-31') > @dtDateTo
			and isnull(LEFT(CONVERT(VARCHAR, DateAnnule, 120), 10),'9999-12-31') > @dtDateTo
			and isnull(LEFT(CONVERT(VARCHAR, DateEffetRetourne, 120), 10),'9999-12-31') > @dtDateTo
			)dddDecaisse on ddd.Id = dddDecaisse.Id
	left join ( -- inactive
		select id 
		from DecaissementDepotDirect 
		where isnull(LEFT(CONVERT(VARCHAR, DateFinalise, 120), 10),'9999-12-31') <= @dtDateTo
			)dddinactif on ddd.Id = dddinactif.Id
	WHERE	
		LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10) <= @dtDateTo -- La DDD doit être créée en date demandée

		and oCancel.operID is null -- n'est pas annulé en date du	

		and dddDecaisse.Id is null
		and dddinactif.Id is NULL
	
		and t.Etat <> 'Confirmée' -- glpi 12730

	GROUP BY
		ddd.id,
		o.OperTypeID,
		case 
		when o.OperTypeID = 'PAE' then cPAE.ConventionNo
		when o.OperTypeID = 'RIN' then cRIN.ConventionNo
		end,
		rr.vcDescription,
		p.OrderOfPlanInReport,
		t.Etat,
		ddd.Montant
		,ddd.InfoDemandeParent

end


