/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DestinationSoleilAgenceRecrue2018
Description         :	Rapport Destination Soleil pour les Agence 2016 - section Recrue
Valeurs de retours  :	Dataset 
Note                :	2017-04-27	Donald Huppé	Création à partie de psREPR_DestinationSoleilAgenceRecrue2017
						2017-05-01	Donald Huppé	Modification de la recherche des recrue. c'est embauché 36 mois avant 31 déc de l'année du concours
													Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
						2017-05-02	Donald Huppé	Sortir les recrues 36 mois inactives
						2017-05-17	Donald Huppé	changer calcul de TauxRecrueQualifiee
						2017-07-12	Donald Huppé	TauxRecrueQualifiee à 2 décimales (au lieu de 0)

drop proc psREPR_DestinationSoleilAgenceRecrue2018

exec psREPR_DestinationSoleilAgenceRecrue2018 '2017-01-01', '2017-04-30' , 17

****************************************************************************************************/
CREATE procedure [dbo].[psREPR_DestinationSoleilAgenceRecrue2018] 
	(
	@DateDu DATETIME, -- Date de début
	@DateAu DATETIME, -- Date de fin
	@NbSemaine int
	) 

as
BEGIN

	--set @DateDu ='2015-01-02'
	--set @DateAu =   '2015-03-01'-- Date de fin
	--set @NbSemaine = 8



 	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	into #BossRepActuel
	FROM Un_RepBossHist RB
	JOIN (
		SELECT
			RepID,
			RepBossPct = MAX(RepBossPct)
		FROM Un_RepBossHist RB
		WHERE RepRoleID = 'DIR'
			AND StartDate IS NOT NULL
			AND (StartDate <= @DateAu)
			AND (EndDate IS NULL OR EndDate >= @DateAu)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @DateAu)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @DateAu)
	GROUP BY
		RB.RepID	
 	
	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	update BR set BR.BossID = LA.BossID
	from #BossRepActuel BR
	join tblREPR_LienAgenceRepresentantConcours LA ON BR.RepID = LA.RepID
	where LA.BossID = 671417

	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #BossRepActuel set BossID = 671417 where BossID = 655109 

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #BossRepActuel set BossID = 436381 where BossID = 436873 

	create table #GrossANDNetUnits_REC ( -- drop table #GrossANDNetUnits_REC
		UnitID_Ori INTEGER,
		UnitID INTEGER,
		RepID INTEGER,
		Recrue INTEGER,
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT) 

	-- Les données des Rep
	INSERT #GrossANDNetUnits_REC -- drop table #GrossANDNetUnits_REC
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDu, @DateAu, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits_REC g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #GrossANDNetUnits_REC set BossID = 671417 where BossID = 655109 

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #GrossANDNetUnits_REC set BossID = 436381 where BossID = 436873 

	-- Agence Maryse Breton est fusionnée à Clément Blais
	update #GrossANDNetUnits_REC set BossID = 149489 where BossID = 440176 

	-- Exclure siege social
	DELETE FROM #GrossANDNetUnits_REC WHERE BossID = 149876


	SELECT 

		Agence =  ltrim(rtrim(replace(Agence,'Agence','')))
		,BossID
		,v.RepCode
		,v.RepID
		,Recrue
		,inscription =LEFT(CONVERT(VARCHAR,  r.BusinessStart, 120), 10)
		,FinContrat = LEFT(CONVERT(VARCHAR,  r.BusinessEnd, 120), 10)
		,QteUniteNettes = sum(QteUniteNettes)
		,NbSemaineRecrue = case 
							-- rep embauché avant le début du concours
							when r.BusinessStart >= @datedu THEN datediff(DAY,r.BusinessStart,@dateAu) / 7
							ELSE @NbSemaine
							end
		,ObjectifQteUnite = case 
							-- rep embauché avant le début du concours
							when r.BusinessStart >= @datedu THEN 3.46  *	cast( datediff(DAY,r.BusinessStart,@dateAu) / 7 as FLOAT) -- nb de semaine complete * 3.46
							ELSE @NbSemaine * 3.46
							end
		,ObjectifLabel = 	case 
							-- rep embauché avant le début du concours
							when r.BusinessStart <@datedu THEN '180 unités'
							ELSE '15 unités par mois'
							end

		,ObjectifAtteint =	FLOOR (
								case when 

									case 
									-- rep embauché avant le début du concours
									when r.BusinessStart >= @datedu THEN 3.46  *	cast( datediff(DAY,r.BusinessStart,@dateAu) / 7 as FLOAT) -- nb de semaine complete * 3.46
									ELSE @NbSemaine * 3.46
									end = 0		

								then 0

								else 
									sum(QteUniteNettes)
									/
									case 
									-- rep embauché avant le début du concours
									when r.BusinessStart >= @datedu THEN 3.46  *	cast( datediff(DAY,r.BusinessStart,@dateAu) / 7 as FLOAT) -- nb de semaine complete * 3.46
									ELSE @NbSemaine * 3.46
									end
								end
							)
	into #table1

	from (

		SELECT 
			Agence = hb.FirstName + ' ' + hb.LastName
			,gnu.BossID
			,Recrue = hr.FirstName + ' ' + hr.LastName

			,r.RepCode
			,gnu.RepID
			,QteUniteNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)

		FROM #GrossANDNetUnits_REC gnu
		join un_rep r on gnu.RepID = r.RepID
		JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
		JOIN dbo.Mo_Human hb on gnu.BossID = hb.HumanID
		where  
			(
			r.BusinessStart >= DATEADD(YEAR,-2,@DateDu) -- 36 mois avant le 31 décembre de la fin du courcours, donc 24 mois avant le début du concours
			AND isnull(r.BusinessEnd,'9999-12-31') > @DateDu -- il a été actif au moins un jour dans la période
			)
			and r.RepCode not in (

				/*Siège	Social*/ '6141'
				/*André Larocque*/ ,'70135'
				 /*Ghislain Thibeault*/ ,'70098'
				 /*Manon Derome*/ ,'70174'
				 /*Chantale Ouellet*/ ,'70190'
				 /*Vincent Matte*/ ,'70207'

				)
			and r.RepID not in (select RepID_Corpo from tblREPR_Lien_Rep_RepCorpo) -- rep corpo
		GROUP by 
			hb.FirstName + ' ' + hb.LastName
			,hr.FirstName + ' ' + hr.LastName
			,r.RepCode
			,gnu.RepID
			,gnu.BossID

		union ALL

		select 
			Agence = hb.FirstName + ' ' + hb.LastName
			, br.BossID
			,Recrue = hr.FirstName + ' ' + hr.LastName
			,r.RepCode
			,r.RepID
			,QteUniteNettes = 0
		from un_rep r
		join #BossRepActuel br on r.RepID = br.RepID
		JOIN dbo.Mo_Human hb on br.BossID = hb.HumanID
		JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
		where  
			(
			r.BusinessStart >= DATEADD(YEAR,-2,@DateDu) -- 36 mois avant le 31 décembre de la fin du courcours, donc 24 mois avant le début du concours
			AND isnull(r.BusinessEnd,'9999-12-31') > @DateDu -- il a été actif au moins un jour dans la période
			)
			and r.RepCode not in (

				/*Siège	Social*/ '6141'
				/*André Larocque*/ ,'70135'
				 /*Ghislain Thibeault*/ ,'70098'
				 /*Manon Derome*/ ,'70174'
				 /*Chantale Ouellet*/ ,'70190'
				 /*Vincent Matte*/ ,'70207'

				)
			and r.RepID not in (select RepID_Corpo from tblREPR_Lien_Rep_RepCorpo) -- rep corpo
			and br.bossId not in (149876) -- siege social
		) v
	join un_rep r on v.RepID = r.RepID
	group by 
		Agence
		,Recrue
		,v.RepCode
		,v.RepID
		,r.BusinessStart
		,r.BusinessEnd
		,v.BossID

	order by 

		Agence
		,Recrue
		,v.RepCode
		,v.RepID
			
	select 
		agence
		,BossID	
		,QteRecrueObjectifAtteint = sum(CASE when ObjectifAtteint > 0 then 1 else 0 end)
		,QteRecrueAgence = count(distinct repID)
		,TauxRecrueQualifiee = CASE 
									WHEN count(distinct repID) >= 5 then
												-- IL FAUT 5 RECRUES ET PLUS POUR AFFICHER UN TAUX, SINON C'EST 0
												round(100 * cast(sum(CASE when ObjectifAtteint > 0 then 1 else 0 end) as float) / cast(count(distinct repID) as FLOAT),2)
									ELSE 0
								END
		,QteRecrueAgenceAtteint = case when count(distinct repID) >= 5 then 1 ELSE 0 end
	into #TableAgregat
	from #table1
	group by agence,BossID	


	select 
		t1.*
		,t2.QteRecrueObjectifAtteint
		,QteRecrueAgence
		,TauxRecrueQualifiee
		,QteRecrueAgenceAtteint
	from #table1 t1
	join #TableAgregat t2 on t1.BossID = t2.BossID
	order BY 
		QteRecrueAgenceAtteint DESC
		,TauxRecrueQualifiee desc
		,ObjectifAtteint desc
		,QteUniteNettes DESC
		
END

/*
exec psREPR_DestinationSoleilAgenceRecrue2016 '2015-01-02', '2015-03-01' , 8
*/

