/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_ConcoursDestinationSoleil_2011_DoublezVotreEte
Description         :	Rapport pour le rapport SSRS "DestinationSoleil-Congrès 2013"
Valeurs de retours  :	Dataset 
Note                :	2010-11-23	Donald Huppé	Créaton à partir de GU_RP_ConcoursDestinationSoleil_2012
						2010-12-01	Donald Huppé	Exclure Lise Fournier des recrue

*********************************************************************************************************************/

-- exec GU_RP_ConcoursDestinationSoleil_2013_glpi7556 '2011-10-10', '2012-05-09' 

CREATE procedure [dbo].[GU_RP_ConcoursDestinationSoleil_2013_glpi7556] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

	create table #GrossANDNetUnits (
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
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	select 

		Repid = 
			case 
			when GNU.repid in (580886,584960) then 580886 -- Jean-François Gemme
 			when GNU.repid in (580841,584150) then 580841 -- Paule Ducharme
 			when GNU.repid in (557514,578803) then 557514 -- Marcelle Poulin
 			when GNU.repid in (500292,584963) then 500292 -- Myriam Derome
 			when GNU.repid in (488309,590338) then 488309 -- Sébastien Sévigny
			else GNU.RepID
			end,

		NetCongres = SUM ( Brut - Retraits + Reinscriptions ),

		Net = SUM ( Brut - Retraits + Reinscriptions ),

		Brut24 = SUM(Brut24),
		Retraits24 = SUM(Retraits24),
		Reinscriptions24 = SUM(Reinscriptions24),
		NET24 = SUM(Brut24 - Retraits24 + Reinscriptions24),
		
		Recrue = CASE WHEN r.BusinessStart >= @StartDate AND r.RepCode NOT IN ('7794','7817','7823','7782','7780') THEN 1 ELSE 0 end
	into #GNU2  
	from #GrossANDNetUnits GNU
	join Un_Rep r ON GNU.RepID = r.RepID

	group by 
		case 
			when GNU.repid in (580886,584960) then 580886 -- Jean-François Gemme
 			when GNU.repid in (580841,584150) then 580841 -- Paule Ducharme
 			when GNU.repid in (557514,578803) then 557514 -- Marcelle Poulin
 			when GNU.repid in (500292,584963) then 500292 -- Myriam Derome
 			when GNU.repid in (488309,590338) then 488309 -- Sébastien Sévigny
			else GNU.RepID
			end,
		CASE WHEN r.BusinessStart >= @StartDate AND r.RepCode NOT IN ('7794','7817','7823','7782','7780') THEN 1 ELSE 0 end

	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	INTO #RepDir -- Table des Directeurs des rep à la date demandée
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
				AND (StartDate <= @EndDate)
				AND (EndDate IS NULL OR EndDate >= @EndDate)
			GROUP BY
				  RepID
			) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	  WHERE RB.RepRoleID = 'DIR'
			--and (rb.repid = @RepID or @RepID = 0)
			AND RB.StartDate IS NOT NULL
			AND (RB.StartDate <= @EndDate)
			AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDate)
	  GROUP BY
			RB.RepID

	select -- Les Rep
		Groupe = 'REP',
		V.repID, 
		R.RepCode, 
		Rep = H.firstname + ' ' + H.lasTname, 
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		R.BusinessStart, 
		Agence = HDIR.firstname + ' ' + HDIR.lasTname, 

		-- On conserve le champ "Point" qui sont en fait des unités.  Afin de rester compatible avec le rapport SSRS déjà contruit en 2009
		PointCongrès = sum(NetCongres),
		Point = sum(Net),
		ConsPct =  	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Net24) / SUM(Brut24)) * 100, 2)
					END,
		NB = case when HDIR.lasTname like '%logelin%' then 1 else 0 end,
		Recrue,
		Top10 = 0,
		PtRequisCongres = case 

			-- non recrue
			when Recrue = 0 then 225  

			-- Recrue pendant le concours
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 225  
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 225  
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 225  

			when Recrue = 1 and month(R.BusinessStart) = 1 then 175
			when Recrue = 1 and month(R.BusinessStart) = 2 then 160
			when Recrue = 1 and month(R.BusinessStart) = 3 then 145
			when Recrue = 1 and month(R.BusinessStart) = 4 then 130
			when Recrue = 1 and month(R.BusinessStart) = 5 then 115
			when Recrue = 1 and month(R.BusinessStart) = 6 then 100
			when Recrue = 1 and month(R.BusinessStart) = 7 then 130
			when Recrue = 1 and month(R.BusinessStart) = 8 then 115
			when Recrue = 1 and month(R.BusinessStart) = 9 then 100

			-- Recrue après le concours mais avant le 31 décembre
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 10 then 100
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 11 then 100
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 12 then 100
							end

	into #Final
	from 
		#GNU2 V
		join un_rep r on V.repID = R.RepID
		JOIN dbo.mo_human h on r.repid = h.humanid
		join #RepDir RepDIR on V.repID = RepDIR.RepID
		JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid

	where (HDIR.firstname + ' ' + HDIR.lasTname) not like '%CGL%'
	and (HDIR.firstname + ' ' + HDIR.lasTname) not like '%allianc%'

	GROUP BY
		V.repID, 
		R.RepCode, 
		H.firstname + ' ' + H.lasTname, 
		case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		R.BusinessStart, 
		HDIR.firstname + ' ' + HDIR.lasTname, 
		case when HDIR.lasTname like '%logelin%' then 1 else 0 end,
		Recrue, --Case when R.BusinessStart between '2010-10-01' and '2011-09-30' /*>= @StartDate*/ then 1 else 0 end,

		case 

			-- non recrue
			when Recrue = 0 then 225  

			-- Recrue pendant le concours
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 225  
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 225  
			when Recrue = 1 and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 225  

			when Recrue = 1 and month(R.BusinessStart) = 1 then 175
			when Recrue = 1 and month(R.BusinessStart) = 2 then 160
			when Recrue = 1 and month(R.BusinessStart) = 3 then 145
			when Recrue = 1 and month(R.BusinessStart) = 4 then 130
			when Recrue = 1 and month(R.BusinessStart) = 5 then 115
			when Recrue = 1 and month(R.BusinessStart) = 6 then 100
			when Recrue = 1 and month(R.BusinessStart) = 7 then 130
			when Recrue = 1 and month(R.BusinessStart) = 8 then 115
			when Recrue = 1 and month(R.BusinessStart) = 9 then 100

			-- Recrue après le concours mais avant le 31 décembre
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 10 then 100
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 11 then 100
			when Recrue = 1 and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 12 then 100
							end

	order by V.repID

	-- Mettre Top 10 = 1 pour les 10 meilleur Points avec consPct >= 84.5
	update t1 
	set top10 = 1
	from #Final t1
	join (select top 10 * from #Final where consPct >= 84.5 order by Point desc) t2 on t1.repid = t2.repid
	
	-- résultat final
	select * from #Final

END


