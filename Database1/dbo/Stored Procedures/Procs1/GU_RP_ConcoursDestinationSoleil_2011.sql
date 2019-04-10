/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_ConcoursDestinationSoleil_2011
Description         :	Rapport pour le rapport SSRS "DestinationSoleil-Congrès 2011"
Valeurs de retours  :	Dataset 
Note                :	2010-01-26	Donald Huppé	Créaton
*********************************************************************************************************************/

-- exec GU_RP_ConcoursDestinationSoleil_2011 '2009-10-05', '2010-01-30' 

CREATE procedure [dbo].[GU_RP_ConcoursDestinationSoleil_2011] 
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
		--UnitID_Ori,
		--UnitID,
		GNU.RepID,
		--Recrue,
		--BossID,
		--RepTreatmentID,
		--RepTreatmentDate,
		--Brut,
		--Retraits,
		--Reinscriptions,
						-- Le Brut est mult par 1.35 si le prmier dépot est avant le 10 janvier
						-- Le retrait est mult par 1.35 si le premier dépot est avant le 10 janvier
						-- La réinscription est mult par 1.35 si le premier dépot est avant le 10 janvier
		NetMajore = SUM ( (Brut - Retraits + Reinscriptions) * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2009-10-07' and '2010-01-10') then 1.35 else 1 end) ),
		Brut24 = SUM(Brut24),
		Retraits24 = SUM(Retraits24),
		Reinscriptions24 = SUM(Reinscriptions24),
		NET24 = SUM(Brut24 - Retraits24 + Reinscriptions24)
	into #GNU2  
	from #GrossANDNetUnits GNU
	JOIN dbo.Un_Unit U on GNU.UnitID = U.UnitID
	JOIN dbo.Un_Convention c on u.conventionID = c.conventionID
	group by GNU.RepID

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
				-- patch pour ajouter 46 point à ce rep qui donne de la formation et qui est récompensé avec 46 points (pour Patricia le 4 mai 2009)
		-- On conserve le champ "Point" qui sont en fait des unités.  Afin de rester compatible avec le rapport SSRS déjà contruit en 2009
		Point = case when R.RepCode = '6417' and @EndDate = '2009-05-01' then sum(NetMajore) + 46 else sum(NetMajore) end,
		ConsPct =  	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Net24) / SUM(Brut24)) * 100, 2)
					END,
		NB = case when HDIR.lasTname like '%logelin%' then 1 else 0 end,
		Recrue = Case when R.BusinessStart between '2009-10-02' and '2010-09-30' /*>= @StartDate*/ then 1 else 0 end,
		Top10 = 0,
		PtRequisCongres = case 

			-- non recrue
			when R.BusinessStart < @StartDate then 225  

			-- Recrue pendant le concours
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 225  
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 225  
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 225  

			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 1 then 175
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 2 then 160
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 3 then 145
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 4 then 130
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 5 then 115
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 6 then 100
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 7 then 130
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 8 then 115
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 9 then 100

			-- Recrue après le concours mais avant le 31 décembre
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 10 then 100
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 11 then 100
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 12 then 100
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
		Case when R.BusinessStart between '2009-10-02' and '2010-09-30' /*>= @StartDate*/ then 1 else 0 end,

		case 

			-- non recrue
			when R.BusinessStart < @StartDate then 225  

			-- Recrue pendant le concours
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 225
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 225
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 225

			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 1 then 175
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 2 then 160
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 3 then 145
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 4 then 130
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 5 then 115
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 6 then 100
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 7 then 130
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 8 then 115
			when R.BusinessStart >= @StartDate and month(R.BusinessStart) = 9 then 100

			-- Recrue après le concours mais avant le 31 décembre
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 10 then 100
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 11 then 100
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) > year(@StartDate) and month(R.BusinessStart) = 12 then 100
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


