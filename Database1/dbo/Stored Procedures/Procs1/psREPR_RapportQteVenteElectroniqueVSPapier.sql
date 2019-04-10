/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_RapportQteVenteElectroniqueVSPapier
Nom du service		: Rapport sur les quantité de vente électronique (Proposition électronique) Vs les ventes papiers
But 				: 
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	EXECUTE psREPR_RapportQteVenteElectroniqueVSPapier '2015-03-01','2015-03-31'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2015-04-10		Donald Huppé						Création du service (SQL fourni par G. Carrier)
		2015-04-17		Donald Huppé						Refaite au complet et exlu ajout unité
		2015-04-21		Donald Huppé						ajouter tous les rep qui n'ont pas de vente
		2015-05-07		Donald Huppé						exclure concours, transfert d'unité, rechercer par SignatureDate au liue de DtFirstDeposit, exlure IND.

*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportQteVenteElectroniqueVSPapier] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

select 
	RepCode,
	Prenom,
	NomFamille,
	BossID,
	Prenom_Dir,
	NomFamille_Dir,
	Vente_electronique = sum(Vente_electronique),
	Vente_papier = sum(Vente_papier)
from (

	select 
		r.RepCode,
		Prenom = hr.FirstName,
		NomFamille = hr.LastName,
		bu.BossID,
		Prenom_Dir = hb.FirstName,
		NomFamille_Dir = hb.LastName,
		Vente_electronique = sum( case when u.PETransactionId is not null then 1 else 0 END),
		Vente_papier = sum(case when u.PETransactionId is null and sgrc.iID_Convention is NULL then 1 else 0 END)
	FROM dbo.Un_Convention c
	JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
	left join Un_SaleSource ss on ss.SaleSourceID = u.SaleSourceID
	join (
		select ConventionID, min_unitID = min(UnitID) FROM dbo.Un_Unit group by ConventionID
		) mu on u.UnitID = mu.min_unitID
	join un_rep r on u.RepID = r.RepID
	JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
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
		)bu on bu.UnitID = u.UnitID
	JOIN dbo.Mo_Human hb on bu.BossID = hb.HumanID

	left join (
		select DISTINCT tc.iID_Convention
		from sgrc.dbo.tblSGRC_Tache t
		join sgrc.dbo.tblSGRC_TacheConvention tc on tc.iID_Tache = t.iID_Tache
		where t.iID_TypeTache in (16,24,31,17)
		)sgrc on sgrc.iID_Convention = c.ConventionID

	where 
		u.SignatureDate BETWEEN LEFT(CONVERT(VARCHAR, @StartDate, 120), 10) AND LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)
		and c.PlanID <> 4
		and isnull(ss.SaleSourceDesc,'') not like '%concour%' 
	GROUP BY
		r.RepCode,
		hr.FirstName,
		hr.LastName,
		bu.BossID,
		hb.FirstName,
		hb.LastName

	union ALL

	select 
		r.RepCode,
		Prenom = hr.FirstName,
		NomFamille = hr.LastName,
		br.BossID,
		Prenom_Dir = hb.FirstName,
		NomFamille_Dir = hb.LastName,
		Vente_electronique = 0,
		Vente_papier = 0
	from un_rep r
	join (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
				GROUP BY
						RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
			GROUP BY
				RB.RepID
		)br on r.RepID = br.RepID
	JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
	JOIN dbo.Mo_Human hb on br.BossID = hb.HumanID
	where r.BusinessStart <= @StartDate
	and isnull(r.BusinessEnd,'9999-12-31') > @EndDate
	) v

group BY
	RepCode,
	Prenom,
	NomFamille,
	BossID,
	Prenom_Dir,
	NomFamille_Dir
ORDER BY
	BossID,
	RepCode

END


