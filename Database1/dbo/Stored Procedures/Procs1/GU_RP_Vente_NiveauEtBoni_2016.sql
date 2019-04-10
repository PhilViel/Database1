/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Vente_NiveauEtBoni
Description         :	Rapport des Niveau et boni des représentants 2013
Valeurs de retours  :	Dataset 

Exemple             :   exec GU_RP_Vente_NiveauEtBoni_2016 '2016-07-04', '2016-08-01'

Note                :	2016-06-07	Donald Huppé	GU_RP_Vente_NiveauEtBoni_2015
						2016-06-07	Donald Huppé	jira ti-3517 : enlever les arrondi pour le calcul du niveau et boni (fait dans la version 2015 aussi)
						2016-06-15	Donald Huppé	Ajout du paramètre @AvecArrondi pour permettre l'option d'arrondi ou non.
						2016-06-16	Donald Huppé	JIRA TI-3658 : Calcul de @DateforRepLevel change. on n'additionne plus un an
						2016-06-27	Donald Huppé	JIRA TI-3775 : Ajout d'un critère dans le calcul du niveau 24M pour les recrues
						2016-07-25	Donald Huppé	JIRA TI-3961 : changer @DateforRepLevel au 4 juillet
						2016-07-26	Donald Huppé	Exclure Rep en pré-retraite
						2016-08-02	Donald Huppé	JIRA TI-4181 : André Larocque n'est pas une recrue
						2016-08-05  Donald Huppé	JIRA TI-4219 : Ne plus Exclure Rep en pré-retraite. on les esclut seulement dans le tableau des niveaux du rapport
						2016-11-03	Donald Huppé	jira ti-5419 : Chantale Ouellet n'est pas un recrue : mettre son BusinessStart = 2008-02-18
						2016-11-30	Donald Huppé	Clarifier paramètre d'appel de SL_UN_RepGrossANDNetUnits
*********************************************************************************************************************/
CREATE procedure [dbo].[GU_RP_Vente_NiveauEtBoni_2016] 
(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	,@AvecArrondi BIT = 0
) as
BEGIN

	declare @DateforRepLevel datetime

	set @DateforRepLevel = cast(year(@EndDate) /*+ 1*/ as varchar(4)) + '-07-04'

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
		Reinscriptions24 FLOAT
	) 

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
	EXEC SL_UN_RepGrossANDNetUnits --NULL, @StartDate, @EndDate, 0, 1
		@ReptreatmentID = NULL, -- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- JIRA TI-3961 : Exclure les rep qui sont des employés su Siège Social
	delete g
	from #GrossANDNetUnits g
	join Mo_Human h on g.RepID = h.HumanID
	join un_rep r on r.RepID = g.RepID
	WHERE 
		h.FirstName + ' ' + h.LastName in ('Véronique Guimond', 'Nadine Babin', 'Martine Larrivée', 'Caroline Samson', 'Annie Poirier')
		/*
		or r.RepCode in ( --programme pré-retraite (calcul différent)
				'5793',
				'6013',
				'6102',
				'6326',
				'6350',
				'6448',
				'6614',
				'6630',
				'6633',
				'6700',
				'6767',
				'7118')
	*/
	-- JIRA TI-3961 : Exclure les directeur suivant
	delete g
	from #GrossANDNetUnits g
	where g.RepID in (
		655109 --Anne LeBlanc-Levesque
		,440176 --Maryse Breton
		,436873 --Nataly Désormeaux
		)

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

	-- JIRA TI-4181 : André Larocque n'est pas une recrue : mettre son 1er BusinessStart de 2007 pour qu'il soit 24P
	UPDATE #TmpNiveauEtBoni set BusinessStart = '2007-09-21' where repID = 736892
	-- jira ti-5419 : Chantale Ouellet n'est pas un recrue : mettre son BusinessStart = 2008-02-18
	UPDATE #TmpNiveauEtBoni set BusinessStart = '2008-02-18' where repID = 768019

	update #TmpNiveauEtBoni
	set RepLevel =  case 
					-- On détermine d'abord s'il est recru en date de la demande
					-- when datediff(m,   BusinessStart ,@EndDate) <= 12 then 'REC'
					-- Sinon, on le met dans 24P ou 24 M selon le 1er janvier de l'année suivante

					-- S Robinson 2016-06-27 (TI-3775) : Pour qu'un représentant soit "24M" pour les niveaux, il faut que le nombre de mois entre sa date d'entrée en fonction et le 1er janvier 2016 soit inférieur à 24 
					-- OU que le nombre de mois entre sa date d'entrée en fonction et la date du rapport soit supérieur à 12

					when		datediff(m,   BusinessStart ,@DateforRepLevel) between 13 and 24 --le nombre de mois entre sa date d'entrée en fonction et le 1er janvier 2016 soit inférieur à 24 
							OR	datediff(m,   BusinessStart ,@EndDate) between 13 and 24 --le nombre de mois entre sa date d'entrée en fonction et la date du rapport soit supérieur à 12
							then '24M'
					when datediff(m,   BusinessStart ,@DateforRepLevel) > 24 then '24P'
					else 'REC' -- else '???'
					end

	IF @AvecArrondi = 1 -- On fait un Round
	BEGIN

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
		-- Pour 2015, ce sont les même niveau que 2012
		left join GUI.dbo.RepLevel2015 RL24P on (round(NB.Point,0) >= RL24P.pointFrom and round(NB.Point,0) < RL24P.PointTo) and (round(NB.ConsPct,0) between RL24P.ConsFrom and RL24P.ConsTo) and RL24P.RepLevel = '24MoisPlus'
		left join GUI.dbo.RepLevel2015 RL24M on (round(NB.Point,0) >= RL24M.pointFrom and round(NB.Point,0) < RL24M.PointTo) and (round(NB.ConsPct,0) between RL24M.ConsFrom and RL24M.ConsTo) and RL24M.RepLevel = '24MoisMoins'
		left join GUI.dbo.RepLevel2015 RLREC on (round(NB.Point,0) >= RLREC.pointFrom and round(NB.Point,0) < RLREC.PointTo) and (round(NB.ConsPct,0) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'
		-- Boni
		left join GUI.dbo.RepBoni2015 B24P on (round(NB.Point,0) >= B24P.pointFrom and round(NB.Point,0) < B24P.PointTo) and (round(NB.ConsPct,0) = B24P.Cons) and B24P.RepLevel = '24MoisPlus'
		left join GUI.dbo.RepBoni2015 B24M on (round(NB.Point,0) >= B24M.pointFrom and round(NB.Point,0) < B24M.PointTo) and (round(NB.ConsPct,0) = B24M.Cons) and B24M.RepLevel = '24MoisMoins'

	END

	IF @AvecArrondi = 0 -- On fait un Floor
	BEGIN

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
	END

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
