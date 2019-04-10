/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	GU_RP_VentesRepConcoursPresident (GU_RP_VentesExcelRepConcoursUnitBenef)
Description         :	Rapport des unités brutes et nettes vendus dans une période par représentants pour le rapport SSRS "Club du Président"
Valeurs de retours  :	Dataset 
Note                :	2009-03-04	Donald Huppé	Créaton (à partir de GU_RP_VentesExcelRepConcoursUnitBenef)
						2009-05-20	Donald Huppé	Modification pour utiliser les données de la SP SL_UN_RepGrossANDNetUnits
*********************************************************************************************************************/

--  exec GU_RP_VentesRepConcoursPresident '2008-10-01', '2009-09-01' , '2007-10-01',  '2008-09-01'

CREATE procedure [dbo].[GU_RP_VentesRepConcoursPresident] 
	(
	@StartDate DATETIME, -- Date de début
	@EndDate DATETIME, -- Date de fin
	@StartDatePrec DATETIME, -- Date de début
	@EndDatePrec DATETIME -- Date de fin
	) 

as
BEGIN

	DECLARE @dtBegin DATETIME
	SET @dtBegin = GETDATE()

create table #Final (
		Groupe varchar(10),
		RepID int,
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

create table #VenteRep (
		Groupe varchar(10),
		RepID int,
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
		RepID int,
		RepCode varchar(30),
		Rep varchar(255),
		BusinessStart DATETIME,
		Agence varchar(255),
		AgenceStart DATETIME,
		Point float,
		ConsPct float,
		PointPrec float)

create table #VenteDirPrec (
		Groupe varchar(10),
		RepID int,
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
			--and (rb.repid = @RepID or @RepID = 0)
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
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 0

	INSERT INTO #VenteRep
	SELECT 
		Groupe = 'REP',
		G.RepID,
		Rep.RepCode,
		REP = HRep.firstName + ' ' + HRep.LastName,
		BusinessStart = Rep.BusinessStart,
		Agence = HDir.FirstName + ' ' + HDir.LastName,
		AgenceStart = RepDIR.AgenceStart,
		Point = sum(Net_4 + Net_8 + Net_10 * 1.25),
		ConsPct =	CASE
						WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
						ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END,
		PointPrec = 0
	from
		#GrossANDNetUnits G
		join UN_REP Rep on G.RepID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		join #RepDir RepDIR on G.repID = RepDIR.RepID
		JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
	group by
		G.RepID,
		Rep.RepCode,
		HRep.firstName + ' ' + HRep.LastName,
		Rep.BusinessStart,
		HDir.FirstName + ' ' + HDir.LastName,
		RepDIR.AgenceStart
	
	-- Les données des Directeurs pour la plage actuelle
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
					else AG.AgenceStart
					end ,
		Point = sum(Net_4 + Net_8 + Net_10 * 1.25),
		ConsPct =	CASE
						WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
						ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
					END,
		PointPrec = 0
	from
		#GrossANDNetUnits G
		join UN_REP Rep on G.BossID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		--join (select bossid, Agencestart from #RepDir group by bossid, Agencestart) RepDIR on G.BossID = RepDIR.BossID
		join (
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
					else AG.AgenceStart
					end

	-- Les données des Directeurs pour la plage précédente
	Delete from #GrossANDNetUnits
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec, @EndDatePrec, 0, 0

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
					else AG.AgenceStart
					end ,
		Point = 0,
		ConsPct = 0,
		PointPrec = sum(Net_4 + Net_8 + Net_10 * 1.25)
	from
		#GrossANDNetUnits G
		join UN_REP Rep on G.BossID = Rep.RepID
		JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
		--join (select bossid, Agencestart from #RepDir group by bossid, Agencestart) RepDIR on G.BossID = RepDIR.BossID
		join (
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
					else AG.AgenceStart
					end

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

	declare @RepID integer
	declare @businessStart datetime
	declare @EndDateREC datetime

	-- Pour le tableau "Recrue de l'année"
	DECLARE MyCursor CURSOR FOR

		select --top 2 -- pour tester
			repid , businessStart
		from 
			un_rep 
		where 
			businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
			and repid in (select repid FROM dbo.Un_Unit where dtfirstDeposit between dateADD(month,-24,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) )
		order by businessStart

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @RepID, @businessStart

	WHILE @@FETCH_STATUS = 0
	BEGIN

		if dateADD(month,12,@businessStart) >= @EndDate
		begin
			set @EndDateREC = @EndDate		
		end
		else
		begin
			set @EndDateREC = dateADD(month,12,@businessStart)		
		end

		print '-1-'
	
		delete from #GrossANDNetUnits
		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @businessStart, @EndDateREC, @RepID, 0

		INSERT INTO #Final
		SELECT 
			Groupe = 'REC',
			G.RepID,
			Rep.RepCode,
			REP = HRep.firstName + ' ' + HRep.LastName,
			BusinessStart = Rep.BusinessStart,
			Agence = HDir.FirstName + ' ' + HDir.LastName,
			AgenceStart = RepDIR.AgenceStart,
			Point = sum(Net_4 + Net_8 + Net_10 * 1.25),
			ConsPct =	CASE
							WHEN SUM(Brut24_4 + Brut24_8 + Brut24_10) <= 0 THEN 0
							ELSE ROUND((sum(Net24_4 + Net24_8 + Net24_10) / SUM(Brut24_4 + Brut24_8 + Brut24_10)) * 100, 2)
						END,
			PointPrec = 0
		from
			#GrossANDNetUnits G
			join UN_REP Rep on G.RepID = Rep.RepID
			JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
			join #RepDir RepDIR on G.repID = RepDIR.RepID
			JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
		group by
			G.RepID,
			Rep.RepCode,
			HRep.firstName + ' ' + HRep.LastName,
			Rep.BusinessStart,
			HDir.FirstName + ' ' + HDir.LastName,
			RepDIR.AgenceStart

		FETCH NEXT FROM MyCursor INTO @RepID, @businessStart
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	-- Pour le tableau "Mortier bâtisseur" (tableau d'agence)
	-- On prend les ventes de la recrue à partir du début du concours jusqu'à la fin de sa période recrue (BusinessStart + 12 mois)

	-- Mettre les taux de conservation des agence dans une table temporaire afin de les associer dans le tableau suivant
	-- ps : Le REP est égal à l'agence car groupe = 'DIR'
	insert into #ConsAg select Rep, ConsPct from #Final where groupe = 'DIR'

	DECLARE MyCursor CURSOR FOR

		select --top 2 -- pour tester
			repid , businessStart
		from 
			un_rep 
		where 
			businessStart between dateADD(month,-12,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) 
			and isnull(businessEnd,'3000-01-01') > @EndDate 
			and repid in (select repid FROM dbo.Un_Unit where dtfirstDeposit between dateADD(month,-24,@StartDate) and cast(cast(year(@StartDate)+1 as varchar(4)) + '-09-30' as datetime) )
		order by businessStart

	OPEN MyCursor
	FETCH NEXT FROM MyCursor INTO @RepID, @businessStart

	WHILE @@FETCH_STATUS = 0
	BEGIN

		if dateADD(month,12,@businessStart) >= @EndDate
		begin
			set @EndDateREC = @EndDate		
		end
		else
		begin
			set @EndDateREC = dateADD(month,12,@businessStart)		
		end

		print '-2-'

		delete from #GrossANDNetUnits
		INSERT #GrossANDNetUnits
		EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDateREC, @RepID, 0

		INSERT INTO #Final
		SELECT 
			Groupe = 'AG_REC',
			G.RepID,
			Rep.RepCode,
			REP = HRep.firstName + ' ' + HRep.LastName,
			BusinessStart = Rep.BusinessStart,
			Agence = HDir.FirstName + ' ' + HDir.LastName,
			AgenceStart = RepDIR.AgenceStart,
			Point = sum(Net_4 + Net_8 + Net_10 * 1.25),
			ConsPct = CA.ConsPct,
			PointPrec = 0
		from
			#GrossANDNetUnits G
			join UN_REP Rep on G.RepID = Rep.RepID
			JOIN dbo.MO_HUMAN HRep on Rep.repID = HRep.HumanID
			join #RepDir RepDIR on G.repID = RepDIR.RepID
			JOIN dbo.Mo_human HDIR on RepDIR.BossID = HDIR.humanid
			left join #ConsAg CA on CA.Agence = HDir.FirstName + ' ' + HDir.LastName
		group by
			G.RepID,
			Rep.RepCode,
			HRep.firstName + ' ' + HRep.LastName,
			Rep.BusinessStart,
			HDir.FirstName + ' ' + HDir.LastName,
			RepDIR.AgenceStart,
			CA.ConsPct

		FETCH NEXT FROM MyCursor INTO @RepID, @businessStart
	END
	CLOSE MyCursor
	DEALLOCATE MyCursor

	select 
		Groupe,
		RepID,
		RepCode,
		REP,
		BusinessStart,
		Agence,
		AgenceStart = case 
					when repID = 149521 then '2000-04-01'
					when repID = 149602 then '2000-04-01'
					when repID = 298925 then '2003-12-01'
					when repID = 149593 then '1996-04-01'
					when repID = 415878 then '2007-05-13'
					else AgenceStart
					end,
		Point,
		ConsPct = round(ConsPct,1), -- On fait le round dans la SP pour faire le tri par ce champ arrondi à une décimale.  Sinon, le rapport fait le tri sur plusieurs décimale mais affiche juste une décimale.
		PointPrec
	from 
		#Final 
	where 
		(agence not like '%Alliance%' and agence not like '%CGL%')
	order by Groupe, RepID

END


