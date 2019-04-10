/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepConcoursPresident (GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Club du Président"
Valeurs de retours  :	Dataset 
Note                :	2009-03-04	Donald Huppé	Créaton (à partir de GU_RP_VentesExcelRepConcoursUnitBenef)
						2009-09-21	Donald Huppé	Mise en production
*********************************************************************************************************************/

-- exec GU_RP_ConcoursDestinationSoleil '2008-10-01', '2009-09-13' 

CREATE procedure [dbo].[GU_RP_ConcoursDestinationSoleil] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

	create table #GrossANDNetUnits (
			RepID INTEGER,
			BossID INTEGER,
			RepTreatmentID INTEGER,
			RepTreatmentDate DATETIME,
			Brut_4 FLOAT,
			Brut_8 FLOAT,
			Brut_10 FLOAT,
			Retraits_4 FLOAT,
			Retraits_8 FLOAT,
			Retraits_10 FLOAT,
			Reinscriptions_4 FLOAT,
			Reinscriptions_8 FLOAT,
			Reinscriptions_10 FLOAT,
			Net_4 FLOAT,
			Net_8 FLOAT,
			Net_10 FLOAT,
			Brut24_4 FLOAT,
			Brut24_8 FLOAT,
			Brut24_10 FLOAT,
			Retraits24_4 FLOAT,
			Retraits24_8 FLOAT,
			Retraits24_10 FLOAT,
			Reinscriptions24_4 FLOAT,
			Reinscriptions24_8 FLOAT,
			Reinscriptions24_10 FLOAT,
			Net24_4 FLOAT,
			Net24_8 FLOAT,
			Net24_10 FLOAT)

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

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 0

	select -- Les Rep
		Groupe = 'REP',
		V.repID, 
		R.RepCode, 
		Rep = H.firstname + ' ' + H.lasTname, 
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		R.BusinessStart, 
		Agence = HDIR.firstname + ' ' + HDIR.lasTname, 
				-- patch pour ajouter 46 point à ce rep qui donne de la formation et qui est récompensé avec 46 points (pour Patricia le 4 mai 2009)
		Point = case when R.RepCode = '6417' and @EndDate = '2009-05-01' then sum(Net_4 + Net_8 + Net_10 * 1.25) + 46 else sum(Net_4 + Net_8 + Net_10 * 1.25) end,
		ConsPct =  	CASE
						WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
						ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END,
		NB = case when HDIR.lasTname like '%logelin%' then 1 else 0 end,
		Recrue = Case when R.BusinessStart >= @StartDate then 1 else 0 end,
		PtRequisCongres = case 

			-- non recrue
			when R.BusinessStart < @StartDate then 200  

			-- Recrue pendant le concours
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 200
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 200
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 200

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

	from 
		#GrossANDNetUnits V
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
				-- patch pour ajouter 46 point à ce rep qui donne de la formation et qui est récompensé avec 46 points (pour Patricia le 4 mai 2009)
		case when HDIR.lasTname like '%logelin%' then 1 else 0 end,
		Case when R.BusinessStart >= @StartDate then 1 else 0 end,
		case 

			-- non recrue
			when R.BusinessStart < @StartDate then 200  

			-- Recrue pendant le concours
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 10 then 200
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 11 then 200
			when R.BusinessStart >= @StartDate and year(R.BusinessStart) = year(@StartDate) and month(R.BusinessStart) = 12 then 200

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

END


