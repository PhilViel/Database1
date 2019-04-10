
/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Vente_NiveauEtBoni
Description         :	Rapport des Niveau et boni des représentants 2013
Valeurs de retours  :	Dataset 
Note                :	2014-01-10	Donald Huppé	Création à partir de GU_RP_Vente_NiveauEtBoni_2013 (il avait été utilisé pouyr 2014 aussi)
						2014-03-05	Donald Huppé	glpi 11136 : Changer les critère de niveau (qté d'untié requise) . donc changer la table RepLevel2012 pour RepLevel2014
						2015-01-30	Donald Huppé	glpi 13396 : exlure les recrues 'REC'
						2015-02-13	Donald Huppé	changer RepLevel2014 pour RepLevel2015
						2015-03-10	Donald Huppé	glpi 13803	: afficher les RECrues dans le tableau des bonis
						2015-06-05	Donald Huppé	glpi 14761 : gestion de l'agence NB
						2016-06-07	Donald Huppé	jira ti-3517 : enlever les arrondi pour le calcul du niveau et boni
*********************************************************************************************************************/

-- exec GU_RP_Vente_NiveauEtBoni_2015 '2015-01-01', '2015-05-31' 

CREATE procedure [dbo].[GU_RP_Vente_NiveauEtBoni_2015] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	) 

as
BEGIN

	declare @DateforRepLevel datetime

	set @DateforRepLevel = cast(year(@EndDate) + 1 as varchar(4)) + '-01-01'

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

	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	update RD set RD.BossID = LA.BossID
	from #RepDir RD
	join tblREPR_LienAgenceRepresentantConcours LA ON RD.RepID = LA.RepID
	where LA.BossID = 671417

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick

	select -- Les Rep
		V.repID, 
		R.RepCode, 
		Rep = H.firstname + ' ' + H.lasTname, 
		BusinessStart = convert(varchar(10),R.BusinessStart,127), 
		Agence = HDIR.firstname + ' ' + HDIR.lasTname, 
		Point = SUM ( (Brut - Retraits + Reinscriptions) ),
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100, 2)
					END

	into #TmpNiveauEtBoni
	from 
		#GrossANDNetUnits V
		JOIN dbo.Un_Unit U on V.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		JOIN dbo.Mo_Human hb on C.beneficiaryID = hb.HumanID
		join un_rep r on V.repID = R.RepID
		JOIN dbo.Mo_Human h on r.repid = h.humanid
		join #RepDir RepDIR on V.repID = RepDIR.RepID
		JOIN dbo.Mo_Human HDIR on RepDIR.BossID = HDIR.humanid
	where 
		isnull(R.BusinessEnd,'3000-01-01') > @EndDate -- seulement les actifs
		and RepDIR.BossID <> RepDIR.RepID -- Exclure les directeurs
	GROUP BY
		V.repID, 
		R.RepCode, 
		H.firstname + ' ' + H.lasTname, 
		R.BusinessStart, 
		HDIR.firstname + ' ' + HDIR.lasTname
	having SUM ( (Brut - Retraits + Reinscriptions)  ) > 0

	alter table #TmpNiveauEtBoni add RepLevel varchar(5), Levelid int, Boni float

	update #TmpNiveauEtBoni
	set RepLevel =  case 
					-- On détermine d'abord s'il est recru en date de la demande
					--when datediff(m,   BusinessStart ,@EndDate) <= 12 then 'REC'
					-- Sinon, on le met dans 24P ou 24 M selon le 1er janvier de l'année suivante
					when datediff(m,   BusinessStart ,@DateforRepLevel) between 13 and 24 then '24M'
					when datediff(m,   BusinessStart ,@DateforRepLevel) > 24 then '24P'
					else 'REC' -- else '???'
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
	left join GUI.dbo.RepLevel2015 RL24P on (floor(NB.Point) >= RL24P.pointFrom and floor(NB.Point) < RL24P.PointTo) and (floor(NB.ConsPct) between RL24P.ConsFrom and RL24P.ConsTo) and RL24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepLevel2015 RL24M on (floor(NB.Point) >= RL24M.pointFrom and floor(NB.Point) < RL24M.PointTo) and (floor(NB.ConsPct) between RL24M.ConsFrom and RL24M.ConsTo) and RL24M.RepLevel = '24MoisMoins'
	left join GUI.dbo.RepLevel2015 RLREC on (floor(NB.Point) >= RLREC.pointFrom and floor(NB.Point) < RLREC.PointTo) and (floor(NB.ConsPct) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'

	-- Boni
	left join GUI.dbo.RepBoni2015 B24P on (floor(NB.Point) >= B24P.pointFrom and floor(NB.Point) < B24P.PointTo) and (floor(NB.ConsPct) = B24P.Cons) and B24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepBoni2015 B24M on (floor(NB.Point) >= B24M.pointFrom and floor(NB.Point) < B24M.PointTo) and (floor(NB.ConsPct) = B24M.Cons) and B24M.RepLevel = '24MoisMoins'

	select 
		repID, 
		RepCode, 
		Rep = ltrim(rtrim(REPLACE(REP,'Agence',''))), 
		BusinessStart, 
		Agence = ltrim(rtrim(REPLACE(Agence,'Agence',''))), 
		Point,
		ConsPct,
		RepLevel,
		Levelid, 
		Boni,
		SortBoni = case when Boni > 0 then 0 else 1 end, -- Patch SSRS pour faire un sort sur 2 champs
		SortAmount = case when Boni > 0 then Boni else Point end -- Patch SSRS pour faire un sort sur 2 champs
	from #TmpNiveauEtBoni NB
	--where RepLevel <> 'REC' -- exclure les recrue glpi 13396
							  -- enlevé dans glpi 13803
	order BY Rep

END


