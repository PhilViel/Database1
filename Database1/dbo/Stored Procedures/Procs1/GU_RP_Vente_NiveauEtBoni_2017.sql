/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_Vente_NiveauEtBoni
Description         :	Rapport des Niveau et boni des représentants 2013
Valeurs de retours  :	Dataset 

Exemple             :   exec GU_RP_Vente_NiveauEtBoni_2017 '2017-01-01', '2017-03-19'

Note                :	
						2016-06-07	Donald Huppé	    jira ti-3517 : enlever les arrondi pour le calcul du niveau et boni (fait dans la version 2015 aussi)
						2016-06-15	Donald Huppé	    Ajout du paramètre @AvecArrondi pour permettre l'option d'arrondi ou non.
						2016-06-16	Donald Huppé	    JIRA TI-3658 : Calcul de @DateforRepLevel change. on n'additionne plus un an
						2016-06-27	Donald Huppé	    JIRA TI-3775 : Ajout d'un critère dans le calcul du niveau 24M pour les recrues
						2016-07-25	Donald Huppé	    JIRA TI-3961 : changer @DateforRepLevel au 4 juillet
						2016-07-26	Donald Huppé	    Exclure Rep en pré-retraite
						2016-08-02	Donald Huppé	    JIRA TI-4181 : André Larocque n'est pas une recrue
						2016-08-05  Donald Huppé	    JIRA TI-4219 : Ne plus Exclure Rep en pré-retraite. on les esclut seulement dans le tableau des niveaux du rapport
						2016-11-03	Donald Huppé	    jira ti-5419 : Chantale Ouellet n'est pas un recrue : mettre son BusinessStart = 2008-02-18
						2016-11-30	Donald Huppé	    Clarifier paramètre d'appel de SL_UN_RepGrossANDNetUnits
						2017-01-26	Donald Huppé	    création GU_RP_Vente_NiveauEtBoni_2017
						2017-01-31	Donald Huppé	    création de RepLevel_PourNiveau
						2017-02-09	Donald Huppé	    Forcer les qte de mois pour les rep parti et revenu
						2017-03-20	Donald Huppé	    correction du calcul de SortAmount
                        2017-05-12  Pierre-Luc Simard   Ne plus exclure Michèle Derôme JIRA TI-7910
						2017-05-29	Donald Huppé		Gestion agence NB vs Anne LeBlanc-Levesque

*********************************************************************************************************************/
CREATE procedure [dbo].[GU_RP_Vente_NiveauEtBoni_2017] 
(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME -- Date de fin
	,@AvecArrondi BIT = 0
	,@DateFinSemestreNiveau DATETIME = '2017-07-02'
) as
BEGIN

	declare @DateforRepLevel datetime

	set @DateforRepLevel = @StartDate --cast(year(@EndDate) /*+ 1*/ as varchar(4)) + '-01-01'

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

	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #RepDir set BossID = 671417 where BossID = 655109 

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

	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #GrossANDNetUnits set BossID = 671417 where BossID = 655109 

	-- JIRA TI-3961 : Exclure les rep qui sont des employés su Siège Social
	delete g
	from #GrossANDNetUnits g
	join Mo_Human h on g.RepID = h.HumanID
	join un_rep r on r.RepID = g.RepID
	WHERE 
		h.FirstName + ' ' + h.LastName in ('Véronique Guimond', 'Nadine Babin', 'Martine Larrivée', 'Caroline Samson', 'Annie Poirier')
		or r.RepCode in (70164 /*Hélène Roy*/)
		or r.RepID in (select RepID_Corpo from tblREPR_Lien_Rep_RepCorpo) --Enlever tous les corpos du rapport


	-- JIRA TI-3961 : Exclure les directeur suivant
	delete g
	from #GrossANDNetUnits g
	where g.RepID in (
		149464	, /*	Mario Béchard	*/
		149469	, /*	Roberto Perron	*/
		149489	, /*	Clément Blais	*/
		149521	, /*	Michel Maheu	*/
		--149573	, /*	Michèle Derome	*/
		149593	, /*	Martin Mercier	*/
		149602	, /*	Daniel Turpin	*/
		149614	, /*	Jeannot Turgeon	*/
		149876	, /*	Siège Social	*/
		298925	, /*	Maryse Logelin	*/
		391561	, /*	Ghislain Thibeault	*/
		415878	, /*	Dolorès Dessureault	*/
		436381	, /*	Sophie Babeux	*/
		436873	, /*	Nataly Désormeaux	*/
		440176	, /*	Maryse Breton	*/
		655109	, /*	Anne LeBlanc-Levesque	*/
		658455	, /*	Moreau inc. Groupe financier	*/
		659765	, /*	Geneviève Duguay	*/
		671417	 /*	Agence Nouveau-Brunswick	*/

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

	alter table #TmpNiveauEtBoni add RepLevel varchar(5), Levelid int, Boni float, RepLevel_PourNiveau varchar(5)

	-- JIRA TI-4181 : André Larocque n'est pas une recrue : mettre son 1er BusinessStart de 2007 pour qu'il soit 36P
	UPDATE #TmpNiveauEtBoni set BusinessStart = '2007-09-21' where repID = 736892
	-- jira ti-5419 : Chantale Ouellet n'est pas un recrue : mettre son BusinessStart = 2008-02-18
	UPDATE #TmpNiveauEtBoni set BusinessStart = '2008-02-18' where repID = 768019

	-- jira ti-6547 : Ghislain Thibeault n'est pas un moins de 36 mois
	UPDATE #TmpNiveauEtBoni set BusinessStart = '2003-01-06' where repID = 719791


	update #TmpNiveauEtBoni
	set RepLevel =  case 

					when		datediff(m,   BusinessStart ,@DateforRepLevel) <= 36 --le nombre de mois entre sa date d'entrée en fonction et le 1er janvier 2016 soit inférieur à 24 
							OR	datediff(m,   BusinessStart ,@EndDate) <= 36 --le nombre de mois entre sa date d'entrée en fonction et la date du rapport soit supérieur à 12
							then '36M'
					when datediff(m,   BusinessStart ,@DateforRepLevel) > 36 then '36P'
					else '**ND**'--'REC' -- else '???'
					end
		,RepLevel_PourNiveau = 
					CASE
					WHEN datediff(m,   BusinessStart ,@DateFinSemestreNiveau) <= 36 THEN '36M'
					ELSE '36P'

					END

	-- Forcer les qte de mois 36P pour les rep parti et revenu suivants :
	update #TmpNiveauEtBoni
		set 
			RepLevel = '36P'
			,RepLevel_PourNiveau = '36P'
	where repid in (
		719791,	--	Ghislain Thibeault
		736892,	--	André Larocque
		768019,	--	Chantale Ouellet
		775454  --	Vincent Matte
		)

	-- Forcer les qte de mois 36M pour les rep parti et revenu suivants :
	update #TmpNiveauEtBoni
		set 
			RepLevel = '36M'
			,RepLevel_PourNiveau = '36M'
	where repid in (
		757163	--	Manon Derome
		)



	IF @AvecArrondi = 1 -- On fait un Round
	BEGIN

		update NB 
		set LevelId = case 
				when NB.RepLevel_PourNiveau/*RepLevel*/ = '36P' then isnull(RL36P.LevelId,0)
				when NB.RepLevel_PourNiveau/*RepLevel*/ = '36M' then isnull(RL36M.LevelId,0)
				--when NB.RepLevel = 'REC' then isnull(RLREC.LevelId,0)
				else 99
				end,
			Boni = case
				when NB.RepLevel = '36P' then isnull(B36P.Boni,0)
				when NB.RepLevel in ('36M','REC') then isnull(B36M.Boni,0) -- GLPI 2441 -- Recrue est inclu dans le 24M
				else 0
				end
		from #TmpNiveauEtBoni NB
		-- Niveau
		-- Pour 2015, ce sont les même niveau que 2012
		left join GUI.dbo.RepLevel2017 RL36P on (round(NB.Point,0) >= RL36P.pointFrom and round(NB.Point,0) < RL36P.PointTo) and (round(NB.ConsPct,0) between RL36P.ConsFrom and RL36P.ConsTo) and RL36P.RepLevel = '36MoisPlus'
		left join GUI.dbo.RepLevel2017 RL36M on (round(NB.Point,0) >= RL36M.pointFrom and round(NB.Point,0) < RL36M.PointTo) and (round(NB.ConsPct,0) between RL36M.ConsFrom and RL36M.ConsTo) and RL36M.RepLevel = '36MoisMoins'
		left join GUI.dbo.RepLevel2017 RLREC on (round(NB.Point,0) >= RLREC.pointFrom and round(NB.Point,0) < RLREC.PointTo) and (round(NB.ConsPct,0) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'
		-- Boni
		left join GUI.dbo.RepBoni2017 B36P on (round(NB.Point,0) >= B36P.pointFrom and round(NB.Point,0) < B36P.PointTo) and (round(NB.ConsPct,0) = B36P.Cons) and B36P.RepLevel = '36MoisPlus'
		left join GUI.dbo.RepBoni2017 B36M on (round(NB.Point,0) >= B36M.pointFrom and round(NB.Point,0) < B36M.PointTo) and (round(NB.ConsPct,0) = B36M.Cons) and B36M.RepLevel = '36MoisMoins'

	END

	IF @AvecArrondi = 0 -- On fait un Floor
	BEGIN

		update NB 
		set LevelId = case 
				when NB.RepLevel_PourNiveau/*RepLevel*/ = '36P' then isnull(RL36P.LevelId,0)
				when NB.RepLevel_PourNiveau/*RepLevel*/ = '36M' then isnull(RL36M.LevelId,0)
				--when NB.RepLevel = 'REC' then isnull(RLREC.LevelId,0)
				else 99
				end,
			Boni = case
				when NB.RepLevel = '36P' then isnull(B36P.Boni,0)
				when NB.RepLevel in ('36M','REC') then isnull(B36M.Boni,0) -- GLPI 2441 -- Recrue est inclu dans le 24M
				else 0
				end
		from #TmpNiveauEtBoni NB
		-- Niveau
		left join GUI.dbo.RepLevel2017 RL36P on (floor(NB.Point) >= RL36P.pointFrom and floor(NB.Point) < RL36P.PointTo) and (floor(NB.ConsPct) between RL36P.ConsFrom and RL36P.ConsTo) and RL36P.RepLevel = '36MoisPlus'
		left join GUI.dbo.RepLevel2017 RL36M on (floor(NB.Point) >= RL36M.pointFrom and floor(NB.Point) < RL36M.PointTo) and (floor(NB.ConsPct) between RL36M.ConsFrom and RL36M.ConsTo) and RL36M.RepLevel = '36MoisMoins'
		left join GUI.dbo.RepLevel2017 RLREC on (floor(NB.Point) >= RLREC.pointFrom and floor(NB.Point) < RLREC.PointTo) and (floor(NB.ConsPct) between RLREC.ConsFrom and RLREC.ConsTo) and RLREC.RepLevel = 'Recrue'

		-- Boni
		left join GUI.dbo.RepBoni2017 B36P on (floor(NB.Point) >= B36P.pointFrom and floor(NB.Point) < B36P.PointTo) and (floor(NB.ConsPct) = B36P.Cons) and B36P.RepLevel = '36MoisPlus'
		left join GUI.dbo.RepBoni2017 B36M on (floor(NB.Point) >= B36M.pointFrom and floor(NB.Point) < B36M.PointTo) and (floor(NB.ConsPct) = B36M.Cons) and B36M.RepLevel = '36MoisMoins'
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
		SortAmount = case when Boni > 0 then Boni * Point else Point end -- Patch SSRS pour faire un sort sur 2 champs
		,RepLevel_PourNiveau
	from #TmpNiveauEtBoni NB
	--where RepLevel <> 'REC' -- exclure les recrue glpi 13396
							  -- enlevé dans glpi 13803
	order BY Rep
END

