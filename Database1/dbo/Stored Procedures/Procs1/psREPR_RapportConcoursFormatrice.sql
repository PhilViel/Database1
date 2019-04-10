/****************************************************************************************************
Copyrights (c) 2016 Gestion Universitas inc
Nom                 :	psREPR_RapportConcoursFormatrice
Description         :	Pour le rapport de concours de la Formatrice
Valeurs de retours  :	Dataset 
Note                :	2016-01-25	Donald Huppé			Création
						2016-01-26	Pierre-Luc Simard		Utilisation des paramètres applicatifs 
						2016-03-18	Donald Huppé			ajout des reps qui n'ont pas fait de vente, pour avoir la liste de tous les reps élligibles
															Ajout des vente dans proacces qui ne proviennent pas de la propo (u.PETransactionId is NULL)
						2016-06-13	Donald Huppé			Création de la vue "View_Transaction" et utilisation de celle ci dans le script
						2016-09-08	Donald Huppé			Exclure les rep de l'Agence Siège Social. Ce sont des employés
						2016-10-04	Donald Huppé			jira ti-4949 : Exclure les rep corpo
						2016-10-17	Donald Huppé			jira ti-5177 : augmenter semaine de 10 à 14, et 18 pour Sylvie Brouillette.
						2016-11-29	Donald Huppé			changer le JOIN  u.PETransactionId = PP.PersonalizedPlanID  au lieu de : View_Transaction.TransactionID
						2017-02-06	Donald Huppé			jira ti-6751 : Ajouter 2 semaines à Vincent Matte
						2017-11-08	Donald Huppé			jira ti-9951 : sortir juste les vente de la propo avec Approval <> 3 (non rejeté)
						2017-11-29	Donald Huppé			Demande de Annie Bergeron : on passe de 14 à 16 semaines

exec psREPR_RapportConcoursFormatrice '2017-02-05'
exec psREPR_RapportConcoursFormatrice '2017-11-05'

drop proc psREPR_RapportConcoursFormatrice

****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportConcoursFormatrice] (
	@EndateDu DATETIME)
AS
BEGIN

SET ARITHABORT ON 

--DECLARE @EndateDu datetime = '2015-03-19'
DECLARE 
	@SQL VARCHAR(8000),
	@vcServeurPropo VARCHAR(255),
	@vcBDPropo VARCHAR(255),
	@LundiSemaineEnCour DATETIME,
	@DimancheSemaineEnCour DATETIME

SET @vcServeurPropo = dbo.fnGENE_ObtenirParametre('GENE_SERVEUR_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) 
SET @vcBDPropo = dbo.fnGENE_ObtenirParametre('GENE_BD_PROPELECT', NULL, NULL, NULL, NULL, NULL, NULL) 

select @LundiSemaineEnCour = case 
		when datepart(WEEKDAY,@EndateDu) = 1 then
			DATEADD(wk, DATEDIFF(wk,0, --LundiSemaineEnCours
			dateadd(dd,-1, @EndateDu) --GETDATE()
			), 0)
		else
			DATEADD(wk, DATEDIFF(wk,0, --LundiSemaineEnCours
			@EndateDu --GETDATE()
			), 0)
		end

--select @LundiSemaineEnCour
select @DimancheSemaineEnCour = dateadd(DAY,6,@LundiSemaineEnCour)


--select @DimancheSemaineEnCour

select 
	r.RepID
	,r.RepCode
	,RepNom = hr.FirstName + ' ' + hr.LastName
	,DirNom = HB.FirstName + ' ' + HB.LastName
	,BusinessStart
	,LundiSemaine1DuRep = 
					DATEADD(wk, DATEDIFF(wk,0, --LundiSuivantSemaine1
					dateadd(DAY,7,r.BusinessStart) -- La date
					), 0)
	,LundiSemaineEnCours = @LundiSemaineEnCour
	,QteSemainePourCeRep = 
				(
						(
								DATEDIFF(
								dd,

								/*startDate*/
								DATEADD(wk, DATEDIFF(wk,0, --LundiSuivantSemaine1
								dateadd(DAY,7,r.BusinessStart) -- La date
								), 0)					

								,

								/*EndDate*/
								@LundiSemaineEnCour

								)
						)
						/7
					)

					+1

	,DimancheSemaineEnCours = @DimancheSemaineEnCour

into #Rep
from 
	Un_Rep r
	JOIN Mo_Human hr on r.RepID = hr.HumanID
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
		) BR on br.RepID = r.RepID
	JOIN Mo_Human HB  ON BR.BossID = HB.HumanID
	LEFT JOIN tblREPR_Lien_Rep_RepCorpo LRC on lrc.RepID_Corpo = r.RepID
where 1=1 
	--DATEPART(weekday,r.BusinessStart) = 6
	--and r.BusinessStart >= '2015-01-01'
	and r.BusinessEnd is null
	and br.BossID <> 149876
	and lrc.RepID_Corpo is null -- exclure les rep corpo
	--and r.RepCode in ( 70130,70139)

--select * from #Rep where RepNom like '%provo%'

--RETURN	

SET @sql = 
'SELECT
	EndateDu = ''' + LEFT(CONVERT(VARCHAR, @EndateDu, 120), 10) + '''
	,RepID
	,RepCode
	,RepNom
	,DirNom
	,BusinessStart
	,LundiSemaine1DuRep
	,LundiSemaineEnCours
	,QteSemainePourCeRep
	,DimancheSemaineEnCours
	,VentePeriode = count(DISTINCT VentePeriode)
	,VenteCumulatif = count(DISTINCT VenteCumulatif)
from 
	(
	select --r.RepresentativeNumber,t.Approval, b.* ,t.*,
		rr.RepID
		,rr.RepCode
		,rr.RepNom
		,rr.Dirnom
		,rr.BusinessStart
		,rr.LundiSemaine1DuRep
		,rr.LundiSemaineEnCours
		,rr.QteSemainePourCeRep
		,rr.DimancheSemaineEnCours
		,VentePeriode =		case when t.[SignedDate] BETWEEN rr.LundiSemaineEnCours		and rr.DimancheSemaineEnCours then pp.[PersonalizedPlanID] else NULL END
		,VenteCumulatif =	case WHEN t.[SignedDate] BETWEEN rr.LundiSemaine1DuRep		and rr.DimancheSemaineEnCours then pp.[PersonalizedPlanID] else NULL END
		,u.UnitID
	from 
		' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[View_Transaction] t
		JOIN ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[Representative] r on t.RepresentativeID = r.RepresentativeID
		JOIN ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[Application] a on t.ApplicationID = a.ApplicationID -- 1 pour 1
		JOIN ' + @vcServeurPropo + '.'  + @vcBDPropo+ '.dbo.[PersonalizedPlan] pp on pp.ApplicationID = a.ApplicationID -- 1 pour 1
		JOIN #Rep rr on rr.RepCode = r.RepresentativeNumber
		LEFT JOIN Un_Unit u on u.PETransactionId = PP.PersonalizedPlanID --t.[TransactionID]
	where 
		t.Approval <> 3 -- non rejeté
		AND isnull(u.TerminatedDate, ''9999-12-31'') > ''' + LEFT(CONVERT(VARCHAR, @EndateDu, 120), 10) + '''
		--and QteSemainePourCeRep BETWEEN 0 and 10
		AND (QteSemainePourCeRep BETWEEN 0 and 16 or (rr.repid = 768108 and QteSemainePourCeRep BETWEEN 0 and 18))

	union all

	--Vente qui ne provienent pas de la propo
	select 
		rr.RepID
		,rr.RepCode
		,rr.RepNom
		,rr.Dirnom
		,rr.BusinessStart
		,rr.LundiSemaine1DuRep
		,rr.LundiSemaineEnCours
		,rr.QteSemainePourCeRep
		,rr.DimancheSemaineEnCours
		,VentePeriode =		case when u.SignatureDate BETWEEN rr.LundiSemaineEnCours	and rr.DimancheSemaineEnCours then u.UnitID else NULL END
		,VenteCumulatif =	case WHEN u.SignatureDate BETWEEN rr.LundiSemaine1DuRep		and rr.DimancheSemaineEnCours then u.UnitID else NULL END
		,UnitID = NULL 
	from
		Un_Unit u
		JOIN #Rep rr on rr.RepID = u.RepID
	where 
		u.PETransactionId is NULL 
		and isnull(u.TerminatedDate, ''9999-12-31'') > ''' + LEFT(CONVERT(VARCHAR, @EndateDu, 120), 10) + '''
		--and QteSemainePourCeRep BETWEEN 0 and 10
		and (
			QteSemainePourCeRep BETWEEN 0 and 16 
			or (rr.repid = 768108 and QteSemainePourCeRep BETWEEN 0 and 18)
			or (rr.repid = 775454 and QteSemainePourCeRep BETWEEN 0 and 16)
			)

	union all

	-- Tous les REPs
	select 
		rr.RepID
		,rr.RepCode
		,rr.RepNom
		,rr.Dirnom
		,rr.BusinessStart
		,rr.LundiSemaine1DuRep
		,rr.LundiSemaineEnCours
		,rr.QteSemainePourCeRep
		,rr.DimancheSemaineEnCours
		,VentePeriode =	NULL
		,VenteCumulatif = NULL
		,UnitID = NULL 
	from 

		#Rep rr

	where 
		
		--QteSemainePourCeRep BETWEEN 0 and 10
		QteSemainePourCeRep BETWEEN 0 and 16 
		or (rr.repid = 768108 and QteSemainePourCeRep BETWEEN 0 and 18)
		or (rr.repid = 775454 and QteSemainePourCeRep BETWEEN 0 and 16)


	)v
GROUP BY
	RepID
	,RepCode
	,RepNom
	,DirNom
	,BusinessStart
	,LundiSemaine1DuRep
	,LundiSemaineEnCours
	,QteSemainePourCeRep
	,DimancheSemaineEnCours
order by RepNom'

print @sql
exec (@sql)

drop table #Rep

set arithabort off

END



/*

SELECT
	RepID
	,RepCode
	,RepNom
	,BusinessStart
	,LundiSemaine1DuRep
	,LundiSemaineEnCours
	,QteSemainePourCeRep
	,DimancheSemaineEnCours
	,VentePeriode = count(DISTINCT VentePeriode)
	,VenteCumulatif = count(DISTINCT VenteCumulatif)
from 
	(
		select 

			r.RepID
			,r.RepCode
			,RepNom
			,BusinessStart
			,LundiSemaine1DuRep
			,LundiSemaineEnCours
			,QteSemainePourCeRep
			,DimancheSemaineEnCours
			,VentePeriode =		case when u.SignatureDate BETWEEN r.LundiSemaineEnCours and r.DimancheSemaineEnCours then u.UnitID else NULL END
			,VenteCumulatif =	case WHEN u.SignatureDate BETWEEN r.LundiSemaine1DuRep		and r.DimancheSemaineEnCours then u.UnitID else NULL END
		from Un_Convention c
		join Un_Unit u on c.ConventionID = u.ConventionID
		join #Rep r on r.RepID = u.RepID
		where isnull(u.TerminatedDate,'9999-12-31') > @EndateDu
		--and QteSemainePourCeRep < 10
	)v

GROUP BY
	RepID
	,RepCode
	,RepNom
	,BusinessStart
	,LundiSemaine1DuRep
	,LundiSemaineEnCours
	,QteSemainePourCeRep
	,DimancheSemaineEnCours
order by RepNom

*/





--------------------------
/*
select r.RepresentativeNumber,t.Approval, b.* ,t.*,
	pp.*
from [SRVSQL17].[PropElect].dbo.[Transaction] t
join [SRVSQL17].[PropElect].dbo.[Representative] r on t.RepresentativeID = r.RepresentativeID
join [SRVSQL17].[PropElect].dbo.[Application] a on t.ApplicationID = a.ApplicationID -- 1 pour 1
join [SRVSQL17].[PropElect].dbo.[PersonalizedPlan] pp on pp.ApplicationID = a.ApplicationID -- 1 pour 1
join [SRVSQL17].[PropElect].dbo.[Beneficiary] b on b.BeneficiaryID = t.UnbornBeneficiaryID
where  
	b.IsUnborn = '1'
	and t.Approval <> 3

*/
--Voici le select que je te propose.
-- Les ventes qui sont actuellement en attente d'une date de naissance
/*
select t.TransactionID from dbo.Transaction t 
where t.Approval = '4' and t.UnbornBeneficiaryID is not null 

union
-- Les ventes qui étaient des bébés à naître et qui sont approuvées (2) ou bien en attente (1).
select t2.TransactionID 
from dbo.Transaction t2
where exists (select b.BeneficiaryID 
from dbo.Beneficiary b 
where IsUnborn = '1' and b.BeneficiaryID =t2.UnbornBeneficiaryID) 
and t2.Approval in (1,2) 

*/
