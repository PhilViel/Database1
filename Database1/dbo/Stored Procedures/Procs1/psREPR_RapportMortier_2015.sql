/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepConcoursPresident (GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Mortier 2014" (anciennement appelé "Club du Président)
Valeurs de retours  :	Dataset 
Note                :	2012-11-29	Donald Huppé	Créaton à partir de psREPR_RapportMortier_2014
						2013-11-12	Donald Huppé	glpi 10514 - réattribution des rep dans certaines agences
						2014-02-07	Donald Huppé	glpi 10984
						2014-02-20	Donald Huppé	,'7916'(Liette Pelletier),'7909'(Alain Bossé) ne sont pas des recrue
						2014-08-04	Donald Huppé	glpi 11927
*********************************************************************************************************************/

--  exec psREPR_RapportMortier_2015 '2013-10-07', '2014-07-31' , '2012-10-07',  '2013-07-31'

CREATE procedure [dbo].[psREPR_RapportMortier_2015] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@StartDatePrec DATETIME, -- Date de début
	@EndDatePrec DATETIME -- Date de fin
	) 

as
BEGIN

	DECLARE 
		@dtBegin DATETIME

	SET @dtBegin = GETDATE()

create table #Final (
		Groupe varchar(10),
		RepID INTEGER,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float
		)

create table #ConsAg (
		Agence varchar(255),
		ConsPct float
		)

create TABLE #RepDir  (
	RepID INTEGER PRIMARY KEY,
	BossID INTEGER,
	AgenceStart datetime )

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
		
create table #VenteRep (
		Groupe varchar(10),
		RepID INTEGER,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float)

create table #VenteDirNow (
		Groupe varchar(10),
		RepID INTEGER,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float)

create table #VenteDirNowConsPct(
		Groupe varchar(10),
		RepID INTEGER,
		ConsPct float)
		
create table #VenteDirPrec (
		Groupe varchar(10),
		RepID INTEGER,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float)

	INSERT INTO #RepDir (Repid, bossid) -- Table des Directeurs des rep à la date demandée
	SELECT
		RB.RepID,
		BossID = MAX(BossID)
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
			AND RB.StartDate IS NOT NULL
			AND (RB.StartDate <= @EndDate)
			AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDate)
	  GROUP BY
			RB.RepID

	-- Inscrire la date de début d'Agence dans #RepDir
	update RD set AgenceStart = Ag.AgenceStart
	from #RepDir RD
	join (
		select 
			rh.repid,
			AgenceStart = MIN(startdate)
		from un_repbosshist rh
		where isnull(EndDate,'3000-01-01') > getdate()
		group by rh.repid
		)Ag on Ag.RepID = RD.BossID

	-- Les données des Rep
	Delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'
	
	--SELECT * from tblREPR_LienAgenceRepresentantConcours
	
	-- Calculer seulement les taux de conservation des DIR avant de merger les ventes de Mario Béchard et Dolores.
	INSERT INTO #VenteDirNowConsPct
	SELECT 
		Groupe = 'DIR',
		G.BossID,
		ConsPct =	CASE
					WHEN SUM(Brut24) <= 0 THEN 0
					ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
				END
	from
		#GrossANDNetUnits G
		JOIN dbo.Un_Unit U on G.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		join UN_REP Rep on G.BossID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		join (
			select 
				rh.repid,
				AgenceStart = MIN(startdate)
			from un_repbosshist rh
			where isnull(EndDate,'3000-01-01') > getdate()
			group by rh.repid
			)Ag on Ag.RepID = G.BossID
	group by
		G.BossID

	-- Pour les totaux par agence, 
	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602) 
	
	-- jugé non nécessaire par donald suite au glpi 10514
	--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick

	INSERT INTO #VenteRep
	SELECT 
		Groupe = 'REP',
		
		Repid = 
			case 
			when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
 			when G.repid in (580841,584150) then 580841 -- Paule Ducharme
 			when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
 			when G.repid in (500292,584963) then 500292 -- Myriam Derome
 			when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
			else G.RepID
			end,

		Rep.RepCode,
		REP = HRep.firstName + ' ' + HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		Agence = HDir.FirstName + ' ' + HDir.LastName,
		AgenceStart = RepDIR.AgenceStart,
		Point = SUM ( (Brut - Retraits + Reinscriptions)),
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
					END,
		PointPrec = 0
	from
		#GrossANDNetUnits G
		JOIN dbo.Un_Unit U on G.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		join UN_REP Rep on G.RepID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		join #RepDir RepDIR on G.repID = RepDIR.RepID
		JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
	where rep.BusinessEnd is null
	group by
		case 
		when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
		when G.repid in (580841,584150) then 580841 -- Paule Ducharme
		when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
		when G.repid in (500292,584963) then 500292 -- Myriam Derome
		when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
		else G.RepID
		end,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		HDir.FirstName + ' ' + HDir.LastName,
		RepDIR.AgenceStart
			
	INSERT INTO #VenteDirNow
	SELECT 
		Groupe = 'DIR',
		G.BossID,
		Rep.RepCode,
		REP = HRep.firstName + ' ' + HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		Agence = HRep.firstName + ' ' + HRep.LastName,
		AgenceStart = case
					when G.BossID = 149521 then '2000-04-01'
					when G.BossID = 149602 then '2000-04-01'
					when G.BossID = 298925 then '2003-12-01'
					when G.BossID = 149593 then '1996-04-01'
					when G.BossID = 415878 then '2007-05-13'
					when G.BossID = 440176 then '2008-08-25'
					when G.BossID = 391561 then '2008-09-08'
					WHEN G.BossID = 658455 then '2012-09-01' 
					else AG.AgenceStart
					end ,
		Point = SUM ( (Brut - Retraits + Reinscriptions) ),--* (case when (c.planid in (10,12) and u.dtfirstdeposit between '2009-10-07' and '2010-01-10') then 1.35 else 1 end) ),
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
					END,
		PointPrec = 0
	from
		#GrossANDNetUnits G
		JOIN dbo.Un_Unit U on G.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		join UN_REP Rep on G.BossID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		left join (
			select 
				rh.repid,
				AgenceStart = MIN(startdate)
			from un_repbosshist rh
			where isnull(EndDate,'3000-01-01') > getdate()
			group by rh.repid
			)Ag on Ag.RepID = G.BossID
	group by
		G.BossID,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		case
					when G.BossID = 149521 then '2000-04-01'
					when G.BossID = 149602 then '2000-04-01'
					when G.BossID = 298925 then '2003-12-01'
					when G.BossID = 149593 then '1996-04-01'
					when G.BossID = 415878 then '2007-05-13'
					when G.BossID = 440176 then '2008-08-25'
					when G.BossID = 391561 then '2008-09-08'
					WHEN G.BossID = 658455 then '2012-09-01' 
					else AG.AgenceStart
					end

	delete from #VenteDirNow where RepID in (149484,149520,149573) -- détruire ceux qui ne sont pas vraiment directeur

	update VN set VN.ConsPct = VC.ConsPct
		from #VenteDirNow VN
		join #VenteDirNowConsPct VC on VN.RepID = VC.RepID

	-- Les données des Directeurs pour la plage précédente
	Delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec, @EndDatePrec, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- Pour les totaux par agence, 
	
	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)
	--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick

	INSERT INTO #VenteDirPrec
	SELECT 
		Groupe = 'DIR',
		G.BossID,
		Rep.RepCode,
		REP = HRep.firstName + ' ' + HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		Agence = HRep.firstName + ' ' + HRep.LastName,
		AgenceStart = case
					when G.BossID = 149521 then '2000-04-01'
					when G.BossID = 149602 then '2000-04-01'
					when G.BossID = 298925 then '2003-12-01'
					when G.BossID = 149593 then '1996-04-01'
					when G.BossID = 415878 then '2007-05-13'
					when G.BossID = 440176 then '2008-08-25'
					when G.BossID = 391561 then '2008-09-08'
					when G.BossID = 658455 then '2012-10-30'
					else AG.AgenceStart
					end ,
		Point = 0,
		ConsPct = 0,
		PointPrec = SUM ( (Brut - Retraits + Reinscriptions))-- * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2009-10-07' and '2010-01-10') then 1.35 else 1 end) )

	from
		#GrossANDNetUnits G
		JOIN dbo.Un_Unit U on G.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		join UN_REP Rep on G.BossID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		left join (
			select 
				rh.repid,
				AgenceStart = MIN(startdate)
			from un_repbosshist rh
			where isnull(EndDate,'3000-01-01') > getdate()
			group by rh.repid
			)Ag on Ag.RepID = G.BossID
		where G.repID <> 496768 -- exclure l'ancien directeur Vahan Matossian
	group by
		G.BossID,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		case
					when G.BossID = 149521 then '2000-04-01'
					when G.BossID = 149602 then '2000-04-01'
					when G.BossID = 298925 then '2003-12-01'
					when G.BossID = 149593 then '1996-04-01'
					when G.BossID = 415878 then '2007-05-13'
					when G.BossID = 440176 then '2008-08-25'
					when G.BossID = 391561 then '2008-09-08'
					when G.BossID = 658455 then '2012-10-30' 
					else AG.AgenceStart
					end
					
	delete from #VenteDirPrec where RepID in (149484,149520,149573) -- détruire ceux qui ne sont pas vraiment directeur

	-- Merger les info ensemble
	insert into #Final

	select -- Les Rep
		Groupe,
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence, 
		AgenceStart,
		Point, 
		ConsPct,
		PointPrec
	from 
		#VenteRep

	UNION

	select -- Les Directeurs
		Groupe,
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence, 
		AgenceStart,
		Point = sum(Point), 
		ConsPct = sum(ConsPct),
		PointPrec = sum(PointPrec)

	from (
		select 
			Groupe,
			repID, 
			RepCode, 
			Rep, 
			BusinessStart, 
			Agence, 
			AgenceStart,
			Point, 
			ConsPct,
			PointPrec
		from 
			#VenteDirNow

		UNION

		select 
			Groupe,
			repID, 
			RepCode, 
			Rep, 
			BusinessStart, 
			Agence, 
			AgenceStart,
			Point, 
			ConsPct,
			PointPrec
		from 
			#VenteDirPrec
		where repID <> 496768 -- exclure l'ancien directeur Vahan Matossian
		
		) V
	group by 
		Groupe,
		repID, 
		RepCode, 
		Rep, 
		BusinessStart, 
		Agence,
		AgenceStart

		declare @StartDate2 datetime
		set @StartDate2 = dateadd(yyyy,-2,@StartDate)
		
		Delete from #GrossANDNetUnits --GLPI 10015
		INSERT #GrossANDNetUnits
		-- on recule un an avant le début du concours pour être certain d'avoir toutes les ventes avec recrue = 1
		-- De toute façon, seulement le vente recrue (=1) sont conservées pour les rep admissible plus loin dans clause where)

		EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate2 , @EndDate, 0, 1

		-- glpi 10514
		update g SET g.BossID = LA.BossID
		from #GrossANDNetUnits g
		JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
		join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
		where u.dtFirstDeposit >= '2011-01-01'

		-- Pour les totaux par agence, 
		update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
		update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)
		--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick

		INSERT INTO #Final
		SELECT 
			Groupe = 'REC',
			Repid = 
				case 
				when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
 				when G.repid in (580841,584150) then 580841 -- Paule Ducharme
 				when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
 				when G.repid in (500292,584963) then 500292 -- Myriam Derome
 				when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
				else G.RepID
				end,
			Rep.RepCode,
			REP = HRep.firstName + ' ' + HRep.LastName,
			BusinessStart = Rep.BusinessStart,
			Agence = HDir.FirstName + ' ' + HDir.LastName,
			AgenceStart = RepDIR.AgenceStart,
			Point = SUM ( (Brut - Retraits + Reinscriptions)),-- * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2009-10-07' and '2010-01-10') then 1.35 else 1 end) ),
			ConsPct =	CASE
							WHEN SUM(Brut24) <= 0 THEN 0
							ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
						END,
			PointPrec = 0
		from
			#GrossANDNetUnits G
			JOIN dbo.Un_Unit U on G.unitid = u.unitid
			JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
			join UN_REP Rep on G.RepID = Rep.RepID
			JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
			join #RepDir RepDIR on G.repID = RepDIR.RepID
			JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
		WHERE 
			G.Recrue = 1 
			AND Rep.RepCode NOT IN ('7794','7823','7782','7715','7916'/*Liette Pelletier*/,'7909'/*Alain Bossé*/) --Nicole Laflamme, Vénus Fréchette, Kathleen Fauteux et Isabelle Danis-Marineau
			and businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
		
		group by
				case 
				when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
 				when G.repid in (580841,584150) then 580841 -- Paule Ducharme
 				when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
 				when G.repid in (500292,584963) then 500292 -- Myriam Derome
 				when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
				else G.RepID
				end,
			Rep.RepCode,
			HRep.firstName + ' ' + HRep.LastName,
			Rep.BusinessStart,
			HDir.FirstName + ' ' + HDir.LastName,
			RepDIR.AgenceStart
		HAVING  SUM ( (Brut - Retraits + Reinscriptions)) <> 0

	-- Retirer ceux dont la période recrue est terminée et qui n'ont pas atteint les 400 unités nécessaires dans leur 12 premiers mois d’activités
	DELETE FROM #Final 
	WHERE Groupe = 'REC'
	AND dateadd(yy,1,BusinessStart) < @EndDate
	AND Point < 400

	--select dateadd(yy,1,'2011-05-01')

	-- Pour le tableau "Mortier bâtisseur" (tableau d'agence)
	-- On prend les ventes de la recrue à partir du début du concours jusqu'à la fin de sa période recrue (BusinessStart + 12 mois)

	-- Mettre les taux de conservation des agence dans une table temporaire afin de les associer dans le tableau suivant
	-- ps : Le REP est égal à l'agence car groupe = 'DIR'
	insert into #ConsAg select Rep, ConsPct from #Final where groupe = 'DIR'

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- Pour les totaux par agence, 
	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)
	--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick

	INSERT INTO #Final
	SELECT 
		Groupe = 'AG_REC',
		Repid = 
			case 
			when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
			when G.repid in (580841,584150) then 580841 -- Paule Ducharme
			when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
			when G.repid in (500292,584963) then 500292 -- Myriam Derome
			when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
			else G.RepID
			end,
		Rep.RepCode,
		REP = HRep.firstName + ' ' + HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		Agence = HDir.FirstName + ' ' + HDir.LastName,
		AgenceStart = RepDIR.AgenceStart,
		Point = SUM ( (Brut - Retraits + Reinscriptions)),-- * (case when (c.planid in (10,12) and u.dtfirstdeposit between '2009-10-07' and '2010-01-10') then 1.35 else 1 end) ),
		ConsPct = CA.ConsPct,
		PointPrec = 0
		--,0
	from
		#GrossANDNetUnits G
		JOIN dbo.Un_Unit U on G.unitid = u.unitid
		JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
		join UN_REP Rep on G.RepID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		join #RepDir RepDIR on G.repID = RepDIR.RepID
		JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
		left join #ConsAg CA on CA.Agence = HDir.FirstName + ' ' + HDir.LastName
		
	WHERE 
		G.Recrue = 1 
		AND Rep.RepCode NOT IN ('7794','7823','7782','7916'/*Liette Pelletier*/,'7909'/*Alain Bossé*/) --Vénus Fréchette (Ghislain Thibeault), Kathleen Fauteux (Sophie Babeux), Isabelle Danis-Marineau (Michel Maheu).
		and businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
		
	GROUP BY
		case 
			when G.repid in (580886,584960) then 580886 -- Jean-François Gemme
			when G.repid in (580841,584150) then 580841 -- Paule Ducharme
			when G.repid in (557514,578803) then 557514 -- Marcelle Poulin
			when G.repid in (500292,584963) then 500292 -- Myriam Derome
			when G.repid in (488309,590338) then 488309 -- Sébastien Sévigny
			else G.RepID
			end,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		HDir.FirstName + ' ' + HDir.LastName,
		RepDIR.AgenceStart,
		CA.ConsPct
	HAVING  SUM ( (Brut - Retraits + Reinscriptions)) <> 0

	delete from #Final where Groupe = 'DIR' and Agence like '%Reeves%'
	delete from #Final where Groupe = 'DIR' and Agence like '%social%'

	----glpi 11927 debut
	delete from #Final where Groupe = 'DIR' and Agence like '%Moreau%' 
	delete from #Final where Groupe = 'DIR' and Agence like '%Logelin%'
	delete from #Final where Groupe = 'DIR' and Agence like '%Thibeault%'

	delete from #Final where Groupe = 'AG_REC' and Agence like '%Social%'
	-------------- glpi 11927 fin

	delete from #Final where Agence like '%Alliance%'
	delete from #Final where Agence like '%CGL%'

	select 
		Groupe,
		RepID,
		RepCode,
		REP = REPLACE(REP,'Agence','Ag.'),
		BusinessStart,
		Agence = REPLACE(Agence,'Agence','Ag.'),
		AgenceStart = case 
					when repID = 149521 then '2000-04-01'
					when repID = 149602 then '2000-04-01'
					when repID = 298925 then '2003-12-01'
					when repID = 149593 then '1996-04-01'
					when repID = 415878 then '2007-05-13'
					when repID = 440176 then '2008-08-25'
					when repID = 391561 then '2008-09-08'
					else AgenceStart
					end,
		Point,
		ConsPct,
		PointPrec
	from 
		#Final F
	order by REPLACE(Agence,'Agence','Ag.')

END


