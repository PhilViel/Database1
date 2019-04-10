/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Vente_NiveauEtBoni
Description         :	Rapport des Niveau et boni des représentants 2011
Valeurs de retours  :	Dataset 
Note                :	2009-09-09	Donald Huppé	Création
						2009-10-20	Donald Huppé	Correction des bonis pour les recrues (GLPI 2441)
						2010-03-18	Donald Huppé	Modification pour 2011 (rapport qui roule pendant l'année 2010)
*********************************************************************************************************************/

-- exec GU_RP_Vente_NiveauEtBoni_2011 '2010-01-01', '2010-03-01' 

CREATE procedure [dbo].[GU_RP_Vente_NiveauEtBoni_2011] 
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

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	select -- Les Rep
		V.repID, 
		R.RepCode, 
		Rep = H.firstname + ' ' + H.lasTname, 
		BusinessStart = convert(varchar(10),R.BusinessStart,127), 
		Agence = HDIR.firstname + ' ' + HDIR.lasTname, 
		Point = SUM ( (Brut - Retraits + Reinscriptions) /* * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2011-01-01' and '2011-01-10') then 1.35 else 1 end)*/ ),
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE ROUND((sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100, 2)
					END

	into #TmpNiveauEtBoni
	from 
		#GrossANDNetUnits V
		JOIN dbo.Un_Unit U on V.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
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

	having SUM ( (Brut - Retraits + Reinscriptions) /* * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2011-01-01' and '2011-01-10') then 1.35 else 1 end)*/ ) > 0

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
	left join GUI.dbo.RepLevel2011 RL24P on (round(NB.Point,0) >= RL24P.pointFrom and round(NB.Point,0) < RL24P.PointTo) and (round(NB.ConsPct,0) between RL24P.ConsFrom and RL24P.ConsTo) and RL24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepLevel2011 RL24M on (round(NB.Point,0) >= RL24M.pointFrom and round(NB.Point,0) < RL24M.PointTo) and (round(NB.ConsPct,0) between RL24M.ConsFrom and RL24M.ConsTo) and RL24M.RepLevel = '24MoisMoins'
	left join GUI.dbo.RepLevel2011 RLREC on (round(NB.Point,0) >= RLREC.pointFrom and round(NB.Point,0) < RLREC.PointTo) and (round(NB.ConsPct,0) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'
	-- Boni
	left join GUI.dbo.RepBoni2011 B24P on (round(NB.Point,0) >= B24P.pointFrom and round(NB.Point,0) < B24P.PointTo) and (round(NB.ConsPct,0) = B24P.Cons) and B24P.RepLevel = '24MoisPlus'
	left join GUI.dbo.RepBoni2011 B24M on (round(NB.Point,0) >= B24M.pointFrom and round(NB.Point,0) < B24M.PointTo) and (round(NB.ConsPct,0) = B24M.Cons) and B24M.RepLevel = '24MoisMoins'

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

/*

SELECT * INTO RepLevel2010 FROM RepLevel

SELECT * FROM RepLevel2010

100 - 200 = 250 - 400
200 - 400 = 400 - 550
400 - 600 = 550 - 800
600 - 800 = 800 - 1000
800 - 10000 = 1000 - 10000

update RepLevel2010 set Pointfrom = 250, PointTo = 400 where Pointfrom = 100 and PointTo = 200
update RepLevel2010 set Pointfrom = 400, PointTo = 550 where Pointfrom = 200 and PointTo = 400
update RepLevel2010 set Pointfrom = 550, PointTo = 800 where Pointfrom = 400 and PointTo = 600
update RepLevel2010 set Pointfrom = 800, PointTo = 1000 where Pointfrom = 600 and PointTo = 800
update RepLevel2010 set Pointfrom = 1000, PointTo = 10000 where Pointfrom = 800 and PointTo = 10000

insert into RepLevel2010 values ('24MoisPlus',	0,	250,	0,	69,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	70,	74,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	75,	79,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	80,	84,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	85,	89,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	90,	94,	1)
insert into RepLevel2010 values ('24MoisPlus',	0,	250,	95,	100,1)

insert into RepLevel2010 values ('24MoisMoins',	0,	250,	0,	69,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	70,	74,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	75,	79,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	80,	84,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	85,	89,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	90,	94,	1)
insert into RepLevel2010 values ('24MoisMoins',	0,	250,	95,	100,1)

insert into RepLevel2010 values ('Recrue',	0,	250,	95,	100,1)

delete from RepLevel2010 where RepLevel = 'Recrue' and ConsFrom <> 95 and ConsTo <> 100

select * from RepBoni2010

drop table RepBoni2010
CREATE TABLE [dbo].[RepBoni2010](
	[RepLevel] [varchar](25) NULL,
	[PointFrom] [int] NOT NULL,
	[PointTo] [int] NULL,
	[Cons] [int] NULL,
	[Boni] [float] NULL
)

*/


