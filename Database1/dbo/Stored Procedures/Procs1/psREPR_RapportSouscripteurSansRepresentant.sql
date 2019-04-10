/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service		: psREPR_RapportSouscripteurSansRepresentant
Nom du service		: psREPR_RapportSouscripteurSansRepresentant
But 				: Obtenir la liste des souscripteurs qui n'ont pas de représentant actif attribué
Facette				: REPR

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------

Exemple d’appel		:	exec psREPR_RapportSouscripteurSansRepresentant 0, 1

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2017-04-19		Donald Huppé						Création du service
		2017-09-22		Donald Huppé						jira ti-9189
		2017-09-25		Donald Huppé						Ajustement jira ti-9189
		2017-09-29		Donald Huppé						Ajout de Deces
*********************************************************************************************************************/
CREATE procedure [dbo].[psREPR_RapportSouscripteurSansRepresentant] 
	(
	@iInclureSiegeSocial INT = 0,
	@iInclureSousSansContratOuvert INT = 0
	) 

AS
BEGIN

	select DISTINCT
		s.SubscriberID
		,PrenomSousc = hs.FirstName
		,NomSousc = hs.LastName
		,NAS = case WHEN hs.SocialNumber is null then 'Manquant' ELSE 'Ok' end
		,CodePostal =dbo.fn_Mo_FormatZIP( ad.ZipCode,ad.CountryID)
		,Ville = ad.City
		,Representant = hr.FirstName + ' ' + hr.LastName
		,CodeRep = r.RepCode
		,DateFinRep = cast(r.BusinessEnd as date)
		,Agence = hd.FirstName + ' ' + hd.LastName
									-- Au moins un contrat ouvert
		,ContratOuvert =			CASE WHEN Ouvert.SubscriberID IS NOT NULL /*AND ferme.SubscriberID IS		NULL*/ THEN 'Oui' ELSE 'Non' END
									-- Aucun contrat ouvert. seulement des contrats fermés
		,ContratFerme =				CASE WHEN Ouvert.SubscriberID IS	 NULL AND ferme.SubscriberID IS NOT	NULL THEN 'Oui' ELSE 'Non' END
									-- aucubn contrat ouvert ni fermé
		,AucunContrat =				CASE WHEN Ouvert.SubscriberID IS NULL	  AND ferme.SubscriberID IS     NULL THEN 'Oui' ELSE 'Non' END
		,Deces =					CASE WHEN ISNULL(hs.DeathDate,'9999-12-31') < GETDATE() THEN 'Oui' ELSE 'Non' END
	--	,ContratOuvertEtFerme =		CASE WHEN Ouvert.SubscriberID IS NOT NULL AND ferme.SubscriberID IS NOT	NULL THEN 1 ELSE 0 END
		
	FROM Un_Subscriber s --on c.SubscriberID = s.SubscriberID
	JOIN Mo_Human hs on s.SubscriberID = hs.HumanID
	JOIN Mo_Adr ad on ad.AdrID = hs.AdrID
	LEFT JOIN Un_Rep r on r.RepID = s.RepID
	LEFT JOIN Mo_Human hr on r.RepID = hr.HumanID
	LEFT JOIN (
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
		)BR ON BR.RepID = r.RepID
	LEFT JOIN Mo_Human hd on br.BossID = hd.HumanID

	LEFT JOIN (
		SELECT DISTINCT c.SubscriberID
		from Un_Convention c
		JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				JOIN (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					--WHERE startDate < DATEADD(d,1 ,'2013-12-31')
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID <> 'FRM' -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		)Ouvert on Ouvert.SubscriberID = s.SubscriberID


	LEFT JOIN (
		SELECT DISTINCT c.SubscriberID
		from Un_Convention c
		JOIN (
			select 
				Cs.conventionid ,
				ccs.startdate,
				cs.ConventionStateID
			from 
				un_conventionconventionstate cs
				JOIN (
					select 
					conventionid,
					startdate = max(startDate)
					from un_conventionconventionstate
					--WHERE startDate < DATEADD(d,1 ,'2013-12-31')
					group by conventionid
					) ccs on ccs.conventionid = cs.conventionid 
						and ccs.startdate = cs.startdate 
						and cs.ConventionStateID = 'FRM' -- je veux les convention qui ont cet état
			) css on C.conventionid = css.conventionid
		)ferme on ferme.SubscriberID = s.SubscriberID

	WHERE --s.RepID = 783514
			(
			isnull( r.BusinessEnd,'9999-12-31') <= getdate()
			OR s.RepID is null
			OR (@iInclureSiegeSocial = 1 and hr.LastName LIKE '%social%') 
			)
			AND
			(
				-- Par défaut, sortir ceux qui ont un contrat ouvert
				(Ouvert.SubscriberID IS NOT NULL)
				OR
					(	
					-- Optionel, sortir ceux qui ont un contrat fermé
					@iInclureSousSansContratOuvert = 1 AND 
							(
								(ferme.SubscriberID IS NOT NULL)
								OR
								(Ouvert.SubscriberID IS NULL AND ferme.SubscriberID IS NULL)
							)
					)

			)

	ORDER BY r.RepCode, s.SubscriberID

END