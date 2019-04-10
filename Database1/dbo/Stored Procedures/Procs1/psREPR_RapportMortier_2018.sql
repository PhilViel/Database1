/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_RapportMortier_2018
Description         :	pour le rapport SSRS "Mortier 2018"
Valeurs de retours  :	Dataset 
Note                :	2016-10-13	Donald Huppé	Créaton à partir de psREPR_RapportMortier_2016
						2016-11-03	Donald Huppé	Correction du calul du taux de conservation des recrues
						2016-11-15	Donald Huppé	jira ti-5639 : Ajouter 70207 dans les rep parti revenu
						2016-11-30	Donald Huppé	Clarifier paramètre d'appel de SL_UN_RepGrossANDNetUnits
						2017-05-17	Donald Huppé	Ajout des objectifs
						2017-05-19	Donald Huppé	Correction Objectifs
						2017-07-04	Donald Huppé	Monimum d'untié pour les recrue passe de 400 à 300
						2017-09-06	Donald Huppé	jira ti-9148 : (retirer les directeur adjoints Steve Blais #7805 et Chantal Jobin #7186
													Gestion des I-BEC avec tblREPR_LienAgenceRepresentantConcours
						2017-09-22	Donald Huppé	jira ti-9247 ajout du parti revenu : (70233)Sophie Asselin
*********************************************************************************************************************/

--  exec psREPR_RapportMortier_2018 '2017-01-01', '2017-09-03' , '2016-01-01', '2016-09-04'

CREATE procedure [dbo].[psREPR_RapportMortier_2018] -- drop proc psREPR_RapportMortier_2017_test

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

	create table #ObjectifUniteNette (RepID int, Objectif float) -- drop table #VentePrec
/*
Une colonne pour les objectifs 2017. 
 NB = 12%
 R. perron = 12%
 C. Blais = 9 %
 M. Mercier = 10 %
 D. Turpin = 9 %
 S. Babeux = 9 %
 M. Maheu = 9 %
*/
	insert into #ObjectifUniteNette values (436381,/*Sophie Babeux*/	1.09)
	insert into #ObjectifUniteNette values (149489,/*Clément Blais*/	1.09)
	insert into #ObjectifUniteNette values (671417,/*NB*/				1.12)
	insert into #ObjectifUniteNette values (149521,/*Michel Maheu*/  	1.09 )
	insert into #ObjectifUniteNette values (149593,/*Martin Mercier*/  	1.10 )
	insert into #ObjectifUniteNette values (149469,/*Roberto Perron*/ 	1.12 )
	insert into #ObjectifUniteNette values (149602,/*Daniel Turpin*/  	1.09 )

	--set @StartDate = '2016-01-01'
	--set @EndDate = '2016-01-01'
	--set @StartDatePrec = '2016-01-01'
	--set @EndDatePrec = '2016-01-01'

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

	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	update RD set RD.BossID = LA.BossID
	from #RepDir RD
	join tblREPR_LienAgenceRepresentantConcours LA ON RD.RepID = LA.RepID
	where LA.BossID = 671417

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


	select 
		RepCodeAncien = ROri.RepCode
		,BusinessStartAncien = ROri.BusinessStart
		,BusinessEndAncien = ROri.BusinessEnd
		,RepAncien = hOri.FirstName + ' ' + hOri.LastName
		,RepCodeRevenu = rrevenu.RepCode
		,RepRevenu = hrr.FirstName + ' ' + hrr.LastName
		,BusinessStartRevenu = rrevenu.BusinessStart
		,BusinessEndRevenu = rrevenu.BusinessEnd
		,RepIDRevenu = rrevenu.RepID
		,NbMoisAncien = datediff(MONTH,ROri.BusinessStart, ROri.BusinessEnd)
	into #RepPartiRevenu -- donc ne sont pas des recrue
	from un_rep rrevenu
	join Mo_Human hrr on rrevenu.RepID = hrr.HumanID
	join Mo_Human hOri on hOri.BirthDate = hrr.BirthDate and hOri.FirstName = hrr.FirstName and hOri.LastName = hrr.LastName
	join Un_Rep ROri on 
					ROri.RepID = hOri.HumanID 
					and ROri.BusinessStart < rrevenu.BusinessStart -- ancien rep a débuté avant nouveau rep
					and isnull(ROri.BusinessEnd,'9999-12-31') < rrevenu.BusinessStart  -- ancien rep a terminé avant début nouveau rep 
	where --rrevenu.BusinessEnd is null
		rrevenu.RepCode in (
			--'70098',
			--'70115',
			--'70135',
			--'70171',
			--'70174',
			--'70190',
			--'70192',
			--'70207'

			-- Les partis et revenus jira ti-7418
			'70135',
			'70098',
			'70174',
			'70190',
			'70207',
			'70233' --Sophie Asselin
		)



	-- Les données des Rep
	Delete from #GrossANDNetUnits
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
		or u.dtFirstDeposit IS NULL /*Les I-BEC n'ont pas de date de 1er dépôt*/

	-- Pour les totaux par agence, 
	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602) 
	update #GrossANDNetUnits SET bossid = 149489 where bossid = 440176 --Fusionner pour toute les sections de qualifications les agences de Clément Blais et de Maryse Breton;
	update #GrossANDNetUnits SET bossid = 436381 where bossid = 436873 --Fusionner pour toute les sections de qualifications les agences de Sophie Babeux et de Nataly Desormeaux;


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
		JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
	group by
		G.BossID

	DELETE FROM #VenteDirNowConsPct WHERE RepID in (149484,149520,149573,149485) -- détruire ceux qui ne sont pas vraiment directeur



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
		JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
		join #RepDir RepDIR on G.repID = RepDIR.RepID
		JOIN dbo.Mo_Human HDIR on RepDIR.BossID = HDIR.humanid
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
					WHEN G.BossID = 671417 then '1964-01-01' 
					WHEN G.BossID = 436381 then '2004-09-29' 
					WHEN G.BossID = 149469 then '1990-04-01' 
					WHEN G.BossID = 149489 then '2000-09-01'
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
		JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
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
					WHEN G.BossID = 671417 then '1964-01-01'
					WHEN G.BossID = 436381 then '2004-09-29' 
					WHEN G.BossID = 149469 then '1990-04-01' 
					WHEN G.BossID = 149489 then '2000-09-01'
					else AG.AgenceStart
					end
	HAVING SUM ( (Brut - Retraits + Reinscriptions) ) > 0 --glpi 14819 : Enlever les directeurs sans vente (Marcelle Payette)

	DELETE FROM #VenteDirNow WHERE RepID in (149484,149520,149573,149485) -- détruire ceux qui ne sont pas vraiment directeur

	update VN set VN.ConsPct = VC.ConsPct
		from #VenteDirNow VN
		join #VenteDirNowConsPct VC on VN.RepID = VC.RepID

	--SELECT * from #VenteDirNowConsPct
	--SELECT * from #VenteDirNow

	-- Les données des Directeurs pour la plage précédente
	Delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits --NULL, @StartDatePrec, @EndDatePrec, 0, 1
		@ReptreatmentID = NULL, -- ID du traitement de commissions
		@StartDate = @StartDatePrec, -- Date de début
		@EndDate = @EndDatePrec, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01' 
		or u.dtFirstDeposit IS NULL /*Les I-BEC n'ont pas de date de 1er dépôt*/

	-- Pour les totaux par agence, 

	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)
	--update #GrossANDNetUnits set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
	update #GrossANDNetUnits SET bossid = 149489 where bossid = 440176 --Fusionner pour toute les sections de qualifications les agences de Clément Blais et de Maryse Breton;
	update #GrossANDNetUnits SET bossid = 436381 where bossid = 436873 --Fusionner pour toute les sections de qualifications les agences de Sophie Babeux et de Nataly Desormeaux;


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
					WHEN G.BossID = 671417 then '1964-01-01'
					WHEN G.BossID = 436381 then '2004-09-29' 
					WHEN G.BossID = 149469 then '1990-04-01' 
					WHEN G.BossID = 149489 then '2000-09-01'
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
		JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
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
					WHEN G.BossID = 671417 then '1964-01-01'
					WHEN G.BossID = 436381 then '2004-09-29' 
					WHEN G.BossID = 149469 then '1990-04-01' 
					WHEN G.BossID = 149489 then '2000-09-01' 
					else AG.AgenceStart
					end

	DELETE FROM #VenteDirPrec where RepID in (149484,149520,149573,149485) -- détruire ceux qui ne sont pas vraiment directeur

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

		EXEC SL_UN_RepGrossANDNetUnits --NULL, @StartDate2 , @EndDate, 0, 1
			@ReptreatmentID = NULL,-- ID du traitement de commissions
			@StartDate = @StartDate2, -- Date de début
			@EndDate = @EndDate, -- Date de fin
			@RepID = 0, --@RepID, -- ID du représentant
			@ByUnit = 1 




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
			ConsPct = 
						CASE
							WHEN SUM(Brut24) <= 0 THEN 0
							ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
						END,
						
			PointPrec = 0
		from
			#GrossANDNetUnits G
			JOIN dbo.Un_Unit U on G.unitid = u.unitid
			JOIN dbo.Un_Convention C on u.conventionid = C.conventionid
			join UN_REP Rep on G.RepID = Rep.RepID
			JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
			join #RepDir RepDIR on G.repID = RepDIR.RepID
			JOIN dbo.Mo_Human HDIR on RepDIR.BossID = HDIR.humanid
			LEFT JOIN #RepPartiRevenu PR ON Rep.RepID = PR.RepIDRevenu

		WHERE 
			G.Recrue = 1 
			AND Rep.RepCode NOT IN ('7794','7823','7782','7715','7916'/*Liette Pelletier*/,'7909'/*Alain Bossé*/) --Nicole Laflamme, Vénus Fréchette, Kathleen Fauteux et Isabelle Danis-Marineau
			and businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate) as varchar(4)) + '-12-31' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
			AND (
					(pR.NbMoisAncien IS NOT NULL AND DATEDIFF( MONTH, Rep.BusinessStart,@EndDate) + ISNULL(pR.NbMoisAncien,0) <= 12) -- Les parti revenu doivent avoir 12 mois et moins cumnulatif en date de fin du concours (P Girard)
					OR 
					pR.NbMoisAncien IS NULL
				)

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
	AND Point < 300

	--select dateadd(yy,1,'2011-05-01')

	-- Pour le tableau "Mortier bâtisseur" (tableau d'agence)
	-- On prend les ventes de la recrue à partir du début du concours jusqu'à la fin de sa période recrue (BusinessStart + 12 mois)

	-- Mettre les taux de conservation des agence dans une table temporaire afin de les associer dans le tableau suivant
	-- ps : Le REP est égal à l'agence car groupe = 'DIR'
	insert into #ConsAg select Rep, ConsPct from #Final where groupe = 'DIR'

	--select t = '#Final',* from #Final

	--select * from #ConsAg

	delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits --NULL, @StartDate, @EndDate, 0, 1
			@ReptreatmentID = NULL,-- ID du traitement de commissions
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
		JOIN dbo.Mo_Human HRep on Rep.repID = HRep.HumanID
		join #RepDir RepDIR on G.repID = RepDIR.RepID
		JOIN dbo.Mo_Human HDIR on RepDIR.BossID = HDIR.humanid
		left join #ConsAg CA on CA.Agence = HDir.FirstName + ' ' + HDir.LastName
		LEFT JOIN #RepPartiRevenu PR ON Rep.RepID = PR.RepIDRevenu

	WHERE 
		G.Recrue = 1 
		AND Rep.RepCode NOT IN ('7794','7823','7782','7916','7909')
		and businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate) as varchar(4)) + '-12-31' as datetime) 
		AND (
				(pR.NbMoisAncien IS NOT NULL AND DATEDIFF( MONTH, Rep.BusinessStart,@EndDate) + ISNULL(pR.NbMoisAncien,0) <= 12) -- Les parti revenu doivent avoir 12 mois et moins cumnulatif en date de fin du concours (P Girard)
				OR 
				pR.NbMoisAncien IS NULL
			)

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

	-- jira ti-9148 : (retirer les directeur adjoints Steve Blais #7805 et Chantal Jobin #7186
	DELETE from #Final where RepCode in ('7805','7186')


	select 
		F.Groupe,
		F.RepID,
		F.RepCode,
		REP = ltrim(rtrim(REPLACE(REP,'Agence',''))),
		BusinessStart,
		Agence = ltrim(rtrim(REPLACE(Agence,'Agence',''))),
		AgenceStart = case 
					when F.repID = 149521 then '2000-04-01'
					when F.repID = 149602 then '2000-04-01'
					when F.repID = 298925 then '2003-12-01'
					when F.repID = 149593 then '1996-04-01'
					when F.repID = 415878 then '2007-05-13'
					when F.repID = 440176 then '2008-08-25'
					when F.repID = 391561 then '2008-09-08'
					WHEN F.repID = 436381 then '2004-09-29' 
					WHEN F.repID = 149469 then '1990-04-01' 
					WHEN F.repID = 149489 then '2000-09-01' 
					else AgenceStart
					end,
		Point,
		ConsPct,
		PointPrec
		,NbMoisAncien = isnull(PR.NbMoisAncien,0)
		,Objectif = PointPrec * OUN.Objectif
		,PctObjectifAtteint = case when (OUN.Objectif * PointPrec) <> 0 then Point / (OUN.Objectif * PointPrec) ELSE 0 END
	-- into #Final2
	from 
		#Final F
		left join #RepPartiRevenu PR on PR.RepIDRevenu = F.RepID
		left join #ObjectifUniteNette OUN on OUN.RepID = f.RepID AND F.Groupe = 'DIR'
	where (F.Rep not like '%social%' and F.Agence not like '%social%')
	order by ltrim(rtrim(REPLACE(Agence,'Agence','')))

/*
	-- Ajouter les unité T et I aux REP et REC

	--select r  = 'REP', *
	--from #Final2 F2
	--join TblTEMP_VenteTetI v on v.RepCode = F2.RepCode AND F2.Groupe in ('REP','REC','AG_REC')

	UPDATE F2
		SET F2.Point = F2.Point + V.UnitQty
	from #Final2 F2
	join TblTEMP_VenteTetI v on v.RepCode = F2.RepCode AND F2.Groupe in ('REP','REC','AG_REC')

	-- Ajouter les unité T et I aux agence

	--select r = 'AG', *
	--from #Final2 F2
	--join (
	--	select Agence, UnitQty = sum(UnitQty)
	--	from TblTEMP_VenteTetI
	--	GROUP BY Agence
	--		) v on v.Agence = F2.Agence AND F2.Groupe in ('DIR')

	UPDATE F2
		SET F2.Point = F2.Point + V.UnitQty
	from #Final2 F2
	join (
		select Agence, UnitQty = sum(UnitQty)
		from TblTEMP_VenteTetI
		GROUP BY Agence
			) v on v.Agence = F2.Agence AND F2.Groupe in ('DIR')



	select 
		Groupe,
		RepID,
		RepCode,
		REP,
		BusinessStart,
		Agence,
		AgenceStart,
		Point,
		ConsPct,
		PointPrec,
		NbMoisAncien	

	from #Final2
	*/
/*
create table TblTEMP_VenteTetI ( -- drop table TblTEMP_VenteTetI
RepCode varchar(15)
,Agence  varchar(50)
,UnitQty float
)
*/

END


