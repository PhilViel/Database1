/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	[psREPR_DestinationSoleilAgenceRecrue2016
Description         :	Rapport Destination Soleil pour les Agence 2016 - section Recrue
Valeurs de retours  :	Dataset 
Note                :	2015-02-25	Donald Huppé	Création (glpi 13670)
						2015-03-27	Donald Huppé	enlever recrue corpo
						2015-06-05	Donald Huppé	glpi 14752	: Josée demande de mettre 3.46 unité par semaine au lieu de 3.75

drop proc psREPR_DestinationSoleilAgence2016

exec psREPR_DestinationSoleilAgenceRecrue2016 '2015-01-02', '2015-05-31' , 22

****************************************************************************************************/
CREATE procedure [dbo].[psREPR_DestinationSoleilAgenceRecrue2016] 
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

	create table #Recrue (RepCode varchar(10))

	insert into #Recrue
	select r.RepCode
	from Un_Rep r
	where r.RepCode in (

			'70099',		'70077',		'70049',		'70054',		'70034',		'70040',		'70041',		'7936',		'70031',
			'70030',		'70010',		'70018',		'70013',		'70084',		'70080',		'70061',		'70050',		'70019',
			'70097',		'70089',		'70095',		'70072',		'70070',		'70044',		'70033',		'70016',		'70091',		'70068',
			'70093',		'70094',		'70087',		'70088',		'70086',		'70092',		'70082',		'70075',		'70074',		'70076',		'70060',
			'70064',		'70056',		'70037',		'70014',		'70096',		'70043',		'70008',		'70069',		'70009',		'70101',
			'70100',		'70067',		'70053'
					)

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

	create table #GrossANDNetUnits ( -- drop table #GrossANDNetUnits
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
	INSERT #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDu, @DateAu, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	SELECT 

		Agence =  ltrim(rtrim(replace(Agence,'Agence','')))
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
							when r.BusinessStart <@datedu THEN '135 unités'
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

			,Recrue = hr.FirstName + ' ' + hr.LastName

			,r.RepCode
			,gnu.RepID
			,QteUniteNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)

		FROM #GrossANDNetUnits gnu
		join un_rep r on gnu.RepID = r.RepID
		JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
		JOIN dbo.Mo_Human hb on gnu.BossID = hb.HumanID
		where  
			(
			r.BusinessStart >= @DateDu
			or r.RepCode in (select repcode from #Recrue)
			)
			and r.RepCode not in ('70098' /*Ghislain Thibeault*/)
		GROUP by 
			hb.FirstName + ' ' + hb.LastName
			,hr.FirstName + ' ' + hr.LastName
			,r.RepCode
			,gnu.RepID

		union ALL

		select 
			Agence = hb.FirstName + ' ' + hb.LastName
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
			r.BusinessStart >= @DateDu
			or r.RepCode in (select repcode from #Recrue)
			)
			and r.RepCode not in (
					'70098' /*Ghislain Thibeault*/
					,'70105' /*Leprohon*/
					,'70104' /*Amyot Gélinas*/)
		
		) v
	join un_rep r on v.RepID = r.RepID
	group by 
		Agence
		,Recrue
		,v.RepCode
		,v.RepID
		,r.BusinessStart
		,r.BusinessEnd
	order by 

		Agence
		,Recrue
		,v.RepCode
		,v.RepID
			
	select 
		agence
		,QteRecrueObjectifAtteint = sum(CASE when ObjectifAtteint > 0 then 1 else 0 end)
		,QteRecrueAgence = count(distinct repID)
		,TauxRecrueQualifiée = round(100 * cast(sum(CASE when ObjectifAtteint > 0 then 1 else 0 end) as float) / cast(count(distinct repID) as FLOAT),0)
		,QteRecrueAgenceAtteint = case when count(distinct repID) >= 5 then 1 ELSE 0 end
	into #TableAgregat
	from #table1
	group by agence

	select 
		t1.*
		,t2.QteRecrueObjectifAtteint
		,QteRecrueAgence
		,TauxRecrueQualifiée
		,QteRecrueAgenceAtteint
	from #table1 t1
	join #TableAgregat t2 on t1.agence = t2.agence
	order BY 
		QteRecrueAgenceAtteint DESC
		,TauxRecrueQualifiée desc
		,ObjectifAtteint desc
		,QteUniteNettes DESC
		
END

/*
exec psREPR_DestinationSoleilAgenceRecrue2016 '2015-01-02', '2015-03-01' , 8
*/


