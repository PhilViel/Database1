/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Vente_NiveauEtBoni
Description         :	Rapport des Niveau et boni des représentants
Valeurs de retours  :	Dataset 
Note                :	2009-09-09	Donald Huppé	Création
						2009-10-20	Donald Huppé	Correction des bonis pour les recrues (GLPI 2441)

*********************************************************************************************************************/

-- exec GU_RP_Vente_NiveauEtBoni '2009-01-01', '2009-09-30' 

CREATE procedure [dbo].[GU_RP_Vente_NiveauEtBoni] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

	declare @DateforRepLevel datetime

	set @DateforRepLevel = cast(year(@EndDate) + 1 as varchar(4)) + '-01-01'

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
		V.repID, 
		R.RepCode, 
		Rep = H.firstname + ' ' + H.lasTname, 
		BusinessStart = convert(varchar(10),R.BusinessStart,127), 
		Agence = HDIR.firstname + ' ' + HDIR.lasTname, 
		Point = sum(Net_4 + Net_8 + Net_10 * 1.25),
		ConsPct =  	CASE
						WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
						ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END
		into #TmpNiveauEtBoni
	from 
		#GrossANDNetUnits V
		join un_rep r on V.repID = R.RepID
		JOIN dbo.mo_human h on r.repid = h.humanid
		join #RepDir RepDIR on V.repID = RepDIR.RepID
		JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid

	where 
		isnull(R.BusinessEnd,'3000-01-01') > @EndDate -- seulement les actifs
		and RepDIR.BossID <> RepDIR.RepID -- Exclure les directeurs

	GROUP BY
		V.repID, 
		R.RepCode, 
		H.firstname + ' ' + H.lasTname, 
		R.BusinessStart, 
		HDIR.firstname + ' ' + HDIR.lasTname

	having sum(Net_4 + Net_8 + Net_10 * 1.25) > 0

	alter table #TmpNiveauEtBoni add RepLevel varchar(5), Levelid int, Boni float

	update #TmpNiveauEtBoni
	set RepLevel =  case 
					-- On détermine d'abord s'il est recru en date de la demande
					when datediff(m,   BusinessStart ,@EndDate) <= 12 then 'REC'
					-- Sinon, on le met dans 24P ou 24 M selon le 1er janvier de l'année suivante
					when datediff(m,   BusinessStart ,@DateforRepLevel) between 13 and 24 then '24M'
					when datediff(m,   BusinessStart ,@DateforRepLevel) > 24 then '24P'
					else '?'
					end

	update NB 
	set LevelId = case 
			when NB.RepLevel = '24P' then isnull(RL24P.LevelId,0)
			when NB.RepLevel = '24M' then isnull(RL24M.LevelId,0)
			when NB.RepLevel = 'REC' then isnull(RLREC.LevelId,0)
			else 99
			end,
		Boni = case
			when NB.RepLevel = '24P' then isnull(B24P.Boni,0)
			when NB.RepLevel in ('24M','REC') then isnull(B24M.Boni,0) -- GLPI 2441 -- Recrue est inclu dans le 24M
			else 0
			end
	from #TmpNiveauEtBoni NB
	-- Niveau
	left join GUI.dbo.RepLevel RL24P on (round(NB.Point,0) >= RL24P.pointFrom and round(NB.Point,0) < RL24P.PointTo) and (round(NB.ConsPct,0) between RL24P.ConsFrom and RL24P.ConsTo) and RL24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepLevel RL24M on (round(NB.Point,0) >= RL24M.pointFrom and round(NB.Point,0) < RL24M.PointTo) and (round(NB.ConsPct,0) between RL24M.ConsFrom and RL24M.ConsTo) and RL24M.RepLevel = '24MoisMoins'
	left join GUI.dbo.RepLevel RLREC on (round(NB.Point,0) >= RLREC.pointFrom and round(NB.Point,0) < RLREC.PointTo) and (round(NB.ConsPct,0) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'
	-- Boni
	left join GUI.dbo.RepBoni B24P on (round(NB.Point,0) >= B24P.pointFrom and round(NB.Point,0) < B24P.PointTo) and (round(NB.ConsPct,0) = B24P.Cons) and B24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepBoni B24M on (round(NB.Point,0) >= B24M.pointFrom and round(NB.Point,0) < B24M.PointTo) and (round(NB.ConsPct,0) = B24M.Cons) and B24M.RepLevel = '24MoisMoins'

	select 
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence, 
		Point,
		ConsPct,
		RepLevel,
		Levelid, 
		Boni,
		SortBoni = case when Boni > 0 then 0 else 1 end, -- Patch SSRS pour faire un sort sur 2 champs
		SortAmount = case when Boni > 0 then Point * Boni else Point end -- Patch SSRS pour faire un sort sur 2 champs
	from #TmpNiveauEtBoni NB

END


