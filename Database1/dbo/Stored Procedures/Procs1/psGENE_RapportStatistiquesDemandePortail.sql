
/****************************************************************************************************
Code de service		:		psGENE_RapportStatistiquesPortail
Nom du service		:		Rapport sur les statistiques des demande RIN et PAE sur le portail et des DDD en découlant
But					:		
Facette				:		GENE
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:
                
				EXEC psGENE_RapportStatistiquesDemandePortail '2015-01-01','2015-10-20'

Parametres de sortie :												
                   
Historique des modifications :
			
						Date						Programmeur								Description							Référence
						----------					-------------------------------------	----------------------------		---------------
						2015-09-29					Donald Huppé							Création du service
						2015-10-21					Donald Huppé							Utilisation de la table PreDemande

exec psGENE_RapportStatistiquesDemandePortail '2015-05-01', '2015-10-21'

 ****************************************************************************************************/
-- sp_recompile psGENE_RapportStatistiquesDemandePortail
CREATE PROCEDURE dbo.psGENE_RapportStatistiquesDemandePortail

	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

AS
BEGIN

--set ARITHABORT on

/*
je dois être en mesure de compiler en indiquant une date de début et fin :

-	# de demandes PAE reçues via portail
-	# de demandes RIN reçues via portail
-	# de DDD découlant des demandes PAE faites par le portail (donc ne doit pas inclure les versements par chèque)
-	# de DDD découlant des demandes RIN faites par le portail (donc ne doit pas inclure les versements par chèque)

TypeDemande : Type de demande : 0 = PAE ; 1 = RIN. Je te propose de vérifier avec Steve Picard si des changements sont à prévoir concernant la projet PRA.
Type : Provenance : 1= Portail ; 0 = Kofax 

*/

select 
	QteDemandePortailPAE = COUNT(DISTINCT IdDemandePAE)
	,QteDemandePortailRIN = COUNT(DISTINCT IdDemandeRIN)
	,QteDepotDirectPAE = COUNT(DISTINCT OperID_PAE)
	,QteDepotDirectRIN = COUNT(DISTINCT OperID_RIN)
from (

	-- le nombre de demande de PAE reçus par le portail
	select
		IdDemandePAE = DP.Id --demande PAE
		,IdDemandeRIN = NULL -- Demande RIN
		,OperID_PAE = NULL
		,OperID_RIN = NULL
	from 
		dbo.PreDemande PD
		join dbo.Demande D on d.IdPreDemande = pd.Id
		join dbo.DemandePAE DP on DP.Id = d.Id
		
	where 
		pd.TypeDemande = 0  -- Type PAE
		and pd.Type = 1 -- Portail
		and isnull(pd.DateCreation,'9999-12-31') BETWEEN @StartDate and @EndDate

	UNION ALL

	-- le nombre de demande de RIN reçus par le portail
	select
		IdDemandePAE = NULL --demande PAE
		,IdDemandeRIN = DR.Id -- Demande RIN
		,OperID_PAE = NULL
		,OperID_RIN = NULL
	from 
		dbo.PreDemande PD
		join dbo.Demande D on d.IdPreDemande = pd.Id
		join dbo.DemandeRin DR on DR.Id = d.Id
		
	where 
		pd.TypeDemande = 1 -- Type RIN 
		and pd.Type = 1 -- Portail
		and isnull(pd.DateCreation,'9999-12-31') BETWEEN @StartDate and @EndDate

	UNION ALL

	select
		IdDemandePAE = NULL
		,IdDemandeRIN = NULL
		,OperID_PAE = CoPAE.OperID
		,OperID_RIN = ctRIN.OperID

	from 
		DecaissementDepotDirect DDD
		join un_oper o on ddd.IdOperationFinanciere = o.OperID and o.OperTypeID in ('RIN','PAE')
		left join Un_OperCancelation oc1 on o.OperID = oc1.OperSourceID
		left join Un_OperCancelation oc2 on o.OperID = oc2.OperID

		-- vient d'une demande RIN ou PAE
		join ( 
			Select IdOperationFinanciere as IdOper from DemandePAE
			union 
			select IdOperationRin  as IdOper from DemandeRin
		) d on d.IdOper = o.OperID

		-- Lien vers le PAE
		left join Un_ConventionOper CoPAE on CoPAE.OperID = o.OperID and o.OperTypeID = 'PAE'
		left JOIN dbo.Un_Convention cPAE on CoPAE.ConventionID = cPAE.ConventionID

		-- Lien vers le RIN
		left join Un_Cotisation ctRIN on o.OperID = ctRIN.OperID and o.OperTypeID = 'RIN'
		left JOIN dbo.Un_Unit uRIN on uRIN.UnitID = ctRIN.UnitID
		left JOIN dbo.Un_Convention cRIN on cRIN.ConventionID = uRIN.ConventionID

	where 
		o.OperDate BETWEEN @StartDate and @EndDate
		and oc1.OperSourceID is NULL
		and oc2.OperID is null
		and DateEffetRetourne is null -- sans effet retourné
		and DateDecaissement is not NULL -- vraiment décaissé
		--and cPAE.ConventionNo = 'C-20000706028'

	)V

--set ARITHABORT off

END


