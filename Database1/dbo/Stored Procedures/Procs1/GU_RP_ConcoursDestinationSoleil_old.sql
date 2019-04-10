/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepConcoursPresident (GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Club du Président"
Valeurs de retours  :	Dataset 
Note                :	2009-03-04	Donald Huppé	Créaton (à partir de GU_RP_VentesExcelRepConcoursUnitBenef)
						2009-09-03	Donald Huppé	Exclute l'agence CGL (GLPI 2228)
						2009-09-21	donald Huppé	remplacé cet SP par la nouvelle SP avec les nouveaux calculs de rétention
*********************************************************************************************************************/


-- exec GU_RP_ConcoursDestinationSoleil '2008-10-01', '2009-09-01' 


CREATE procedure [dbo].[GU_RP_ConcoursDestinationSoleil_old] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN


	select -- Les Rep
		Groupe = 'REP',
		V.repID, 
		V.RepCode, 
		Rep, 
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		V.BusinessStart, 
		Agence, 
				-- patch pour ajouter 46 point à ce rep qui donne de la formation et qui est récompensé avec 46 points (pour Patricia le 4 mai 2009)
		Point = case when V.RepCode = '6417' and @EndDate = '2009-05-01' then Point + 46 else point end,
		ConsPct,
		NB = case when agence like '%logelin%' then 1 else 0 end,
		Recrue = Case when V.BusinessStart >= @StartDate then 1 else 0 end,
		PtRequisCongres = case 

			-- non recrue
			when V.BusinessStart < @StartDate then 200  

			-- Recrue pendant le concours
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) = year(@StartDate) and month(V.BusinessStart) = 10 then 200
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) = year(@StartDate) and month(V.BusinessStart) = 11 then 200
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) = year(@StartDate) and month(V.BusinessStart) = 12 then 200

			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 1 then 175
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 2 then 160
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 3 then 145
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 4 then 130
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 5 then 115
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 6 then 100
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 7 then 130
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 8 then 115
			when V.BusinessStart >= @StartDate and month(V.BusinessStart) = 9 then 100

			-- Recrue après le concours mais avant le 31 décembre
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) > year(@StartDate) and month(V.BusinessStart) = 10 then 100
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) > year(@StartDate) and month(V.BusinessStart) = 11 then 100
			when V.BusinessStart >= @StartDate and year(V.BusinessStart) > year(@StartDate) and month(V.BusinessStart) = 12 then 100
							end

	from 
		FN_VentesRep (@StartDate, @EndDate , 0,  'REP') V
		join un_rep r on V.repID = R.RepID
	where Agence not like '%CGL%' -- exclure CGL (GLPI 2228)


END



