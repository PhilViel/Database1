/****************************************************************************************************
Copyrights (c) 2014 Gestion Universitas inc
Nom                 :	psOPER_RapportDDDJounalier
Description         :	Rapport journalier des DDD
Valeurs de retours  :	Dataset de données

Note                :	
					2015-09-25	Donald Huppé	Création 	glpi 15661
					2016-09-16	Donald Huppé	Exclure les DDD qui sont remplacée par une nouvelle DDD : Demande de MC Breton
exec psOPER_RapportDDDJounalier '2016-08-31'
DROP PROC psOPER_RapportDDDJounalier_test
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psOPER_RapportDDDJounalier] (
	@dtDateTo DATETIME -- Date de fin de l'intervalle des opérations
	)
AS
BEGIN

	select DISTINCT
		t.DateEtat,
		ddd.id,
		TypeDemande = o.OperTypeID,
		Convention = case 
				when o.OperTypeID = 'PAE' then cPAE.ConventionNo
				when o.OperTypeID = 'RIN' then cRIN.ConventionNo
				end,
		Regime = rr.vcDescription,
		p.OrderOfPlanInReport,
		Etat = t.Etat,
		/*
		Etat2 = 
			case 
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateEffetRetourne, 120), 10),'9999-12-31') <= @dtDateTo	then 'Refusée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateDecaissement, 120), 10),'9999-12-31') <= @dtDateTo	then 'Décaissée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateRejete, 120), 10),'9999-12-31') <= @dtDateTo			then 'Rejetée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateConfirmation, 120), 10),'9999-12-31') <= @dtDateTo	then 'Confirmée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateTransmission, 120), 10),'9999-12-31') <= @dtDateTo	then 'EnTraitement'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateAnnule, 120), 10),'9999-12-31') <= @dtDateTo			then 'Annulée'
			when isnull(LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10),'9999-12-31') <= @dtDateTo		then 'EnAttente'
			else 'ND'
			end,
		*/	
		ddd.Montant
		,ddd.InfoDemandeParent
	FROM DecaissementDepotDirect ddd
	JOIN DBO.fntOPER_ObtenirEtatDDD (NULL, @dtDateTo) t on ddd.Id = t.id
	JOIN un_oper o on ddd.IdOperationFinanciere = o.OperID

	-- lien vers le RIN
	LEFT JOIN Un_Cotisation ct on o.OperID = ct.OperID and o.OperTypeID = 'RIN'
	LEFT JOIN dbo.Un_Unit uRIN on ct.UnitID = uRIN.UnitID
	LEFT JOIN dbo.Un_Convention cRIN on uRIN.ConventionID = cRIN.ConventionID
	
	-- Lien vers le PAE
	LEFT JOIN Un_ConventionOper CoPAE on CoPAE.OperID = o.OperID and o.OperTypeID = 'PAE'
	LEFT JOIN dbo.Un_Convention cPAE on CoPAE.ConventionID = cPAE.ConventionID

	LEFT JOIN Un_Plan p on cRIN.PlanID = p.PlanID or cPAE.PlanID = p.PlanID
	LEFT JOIN tblCONV_RegroupementsRegimes rr on p.iID_Regroupement_Regime = rr.iID_Regroupement_Regime


	LEFT JOIN DecaissementDepotDirect DDDInitial on ddd.Id = DDDInitial.IdDecaissementDepotDirectInitial and CAST(DDDInitial.DateCreation AS DATE) <= @dtDateTo

	/*
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
	*/
	WHERE 1=1
		AND LEFT(CONVERT(VARCHAR, t.DateEtat, 120), 10) = @dtDateTo
		AND LEFT(CONVERT(VARCHAR, ddd.DateCreation, 120), 10) <= @dtDateTo -- La DDD doit être créée en date demandée
		AND DDDInitial.IdDecaissementDepotDirectInitial is null -- n'a pas été remplacé par une nouvelle DDD en date demandée


		/*
		and dddDecaisse.Id is null
		and dddinactif.Id is NULL
		*/

		--and t.Etat <> 'Confirmée' -- glpi 12730

end


