/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas Inc.
Nom                 :	RP_UN_BulletinHebdo_2018
Description         :	Procédure stockée du rapport du Bulletin Hebdomadaire 2018
Valeurs de retours  :	Dataset 
Note                :	2017-12-13			Donald Huppé	Création
						2018-01-23			Donald Huppé	Remettre les ventes de l'annéé précédente
						2018-01-24			Donald Huppé	Remettre les ventes de la semaine précédente
						2018-02-05			Donald Huppé	jira ti-11315
						2018-02-06#			Donald Huppé	Correction de jira ti-11315
						2018-04-30			Donald Huppé	Ajout de Anne LeBlanc-Levesque comme dir. adjointe
exec RP_UN_BulletinHebdo_2018 '2018-01-15','2018-01-21','2017-01-16','2017-01-22'

drop proc RP_UN_BulletinHebdo_2017_test_jiraTI10165

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo_2018] (
	@StartDate DATETIME,
	@EndDate DATETIME 
	,@StartDatePrec DATETIME
	,@EndDatePrec DATETIME
	) 
AS
BEGIN

set arithabort on

	DECLARE 
		@JanuaryFirst AS DATETIME,
		@JanuaryFirstPrec AS DATETIME,
		@DateDebutMois as datetime,
		@DateFinMois as datetime,
		@DateDebutMoisPrec as datetime,
		@DateFinMoisPrec as datetime,
		
		@NetSemaine float,
		@NetSemainePrec float,
		@ObjectifSemaine float,
		
		@NetMoisPrec float,
		@ObjectifMoisActuel float,
		@NetMois float,

		@ObjCumul float
		
	if @StartDate = '9999-12-31'
		begin
		set @StartDate = DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0)
		set @EndDate = dateadd(dd,6, DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0))
		--set @StartDatePrec = DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())), 0)
		--set @EndDatePrec = dateadd(dd,6, DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())   ), 0))
		end
	
	--SELECT @DateDebutMois = DATEADD(mm, DATEDIFF(mm,0,@StartDate), 0)  
	--SELECT @DateFinMois = DATEADD(d,-1, DATEADD(mm,1,DATEADD(mm, DATEDIFF(mm,0,@StartDate), 0)))

	--SELECT @DateDebutMoisPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-' + CAST(month(@DateDebutMois)as varchar(4)) + '-' + CAST(DAY(@DateDebutMois)as varchar(4))
	--SELECT @DateFinMoisPrec =  CAST(YEAR(@EndDatePrec) as varchar(4)) + '-' + CAST(month(@DateFinMois)as varchar(4)) + '-' + CAST(DAY(@DateFinMois)as varchar(4))

	-- si le debut et la fin de la semaine sont dans le même mois alors les vente du mois courant terminent avec la fin de la semaine
	-- si on change de mois pendant la semaine, alors affiche les vene du mois qui se termine, donc @DateFinMois reste tel calculé avant ce if. il ne change pas
	if month(@StartDate) = month(@EndDate)
		begin
		select @DateFinMois = @EndDate
		end

	/*
	print @DateDebutMois
	print @DateFinMois

	print @DateDebutMoisPrec
	print @DateFinMoisPrec	
	*/

	SET @JanuaryFirst = CAST(YEAR(@EndDate) as varchar(4)) + '-01-01'
	SET @JanuaryFirstPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-01-01'

	create table #TMPObjectifBulletin (
									DateFinPeriode varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)


	
	DECLARE @startDateSunDay DATETIME
	DECLARE @endDateSunDay DATETIME

	SET @startDateSunDay = '2018-01-07' -- 1er dimanche
	SET @endDateSunDay = '2018-12-30'; -- dernier dimanche

	WITH dates(Date) AS 
	(
		SELECT @startDateSunDay as Date
		UNION ALL
		SELECT DATEADD(d,7,[Date])
		FROM dates 
		WHERE DATE < @endDateSunDay
	)

	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul)
	SELECT 
		RangDate = DENSE_RANK() OVER (
									partition by null -- #2 : basé sur rien
									ORDER BY Date -- #1 : on numérote les Date
									)
		,Dimanche = cast(Date  as date)
		,ObjSemaine = 0
		,ObjCumul = 0
	FROM dates
	OPTION (MAXRECURSION 0)
		


	--select * from #TMPObjectifBulletin
		
	--RETURN


 	SELECT
		RB.RepID,
		BossID = MAX(BossID)
	into #BossRepActuel
	FROM Un_RepBossHist RB
	JOIN (
		SELECT
			RepID,
			RepBossPct = MAX(RepBossPct)
		FROM Un_RepBossHist RB
		WHERE RepRoleID = 'DIR'
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
 	



	create table #GNUSemaine (
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

	create table #GNUSemainePrec (
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

	create table #GNUCumul (
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
			
	create table #GNUCumulPrec (
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




	insert into #GNUSemaine
	exec SL_UN_RepGrossANDNetUnits --NULL, @StartDate,@EndDate, 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		,@QteMoisRecrue = 12


 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUSemaine g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID



	
	insert into #GNUSemainePrec
	exec SL_UN_RepGrossANDNetUnits --NULL, @StartDatePrec,@EndDatePrec, 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDatePrec, -- Date de début
		@EndDate = @EndDatePrec, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		,@QteMoisRecrue = 12
 	

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUSemainePrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	
 	
	select @ObjectifSemaine = SUM((Brut - Retraits + reinscriptions))* 1.05 from #GNUSemainePrec 



	insert into #GNUCumul
	exec SL_UN_RepGrossANDNetUnits --NULL, @JanuaryFirst , @EndDate , 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @JanuaryFirst, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		,@QteMoisRecrue = 12


 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUCumul g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID

 	



	insert into #GNUCumulPrec
	exec SL_UN_RepGrossANDNetUnits --NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @JanuaryFirstPrec, -- Date de début
		@EndDate = @EndDatePrec, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 
		,@QteMoisRecrue = 12


 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUCumulPrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID


	select @ObjCumul = SUM((Brut - Retraits + reinscriptions)) * 1.05 from #GNUCumulPrec



	select 
		V.RepID,
		Recruit = case when V.RepID in (
				149632	, --Carole Delorme
				446583	, --Thérèse Lafrance
				469387	, --Marie-Louise Mujinga Muya
				527770	, --Aline Therrien
				562918	, --Richard Pelletier
				594232	, --Lise Fournier
				625284	, --Vénus Fréchette
				647603	, --Ronald Petroff
				711180	, --Marie-Eve Saulnier
				719791	, --Ghislain Thibeault
				727150	, --Claire Arseneau
				768019	, --Chantale Ouellet
				736892	 --André Larocque	
				,795683  --Sophie Asselin
									)  then 0 else V.Recruit end, 
		V.RepCode,

		AgencyRepCode = case when V.AgencyRepCode = 'ND' then RB.RepCode else V.AgencyRepCode end, 

		V.LastName,
		V.FirstName,
		BusinessStart = case when V.RepID = 594232 then '1950-01-01' else V.BusinessStart end, -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		ActualAgency = B.FirstName + ' ' + B.LastName,
		ActuelAgencyRepID = RB.RepID,
		-- Si l'agence lors de la vente est Nd (non déterminé en date de InforceDate), alors on met l'agence actuelle,
		Agency = case when V.Agency = 'ND' then B.FirstName + ' ' + B.LastName else Agency end,
		--Province,
		--Region,

		Net = SUM(Net),


		NetPrec = SUM(NetPrec),


		Cumul = SUM(Cumul),


		CumulPrec = SUM(CumulPrec),


		ObjSemaine = isnull(ObjSemaine,0),
		ObjCumul = isnull(ObjCumul,0),
		Weekno = isnull(Weekno,0)
		
	into #table1

	FROM (

		select 
			U.UnitID,
			Semaine.RepID,
			Recruit = Recrue,
			RREP.RepCode,
			AgencyRepCode = ISNULL(BREP.RepCode,'nd'),
			HREP.LastName,
			HREP.FirstName,
			RREP.BusinessStart,
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			--Province = '',--case when HBoss.LastName like '%Brunswick%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			--AdrS.Region,
			Net = (Brut - Retraits + reinscriptions),
			NetPrec = 0,
			Cumul = 0,
			CumulPrec = 0
		from 
			#GNUSemaine Semaine
			JOIN dbo.Un_Unit U on U.UnitID = Semaine.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Semaine.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Semaine.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL -- très important le ALL
		
		select 
			U.UnitID,
			SemainePrec.RepID,
			Recruit = Recrue,
			RREP.RepCode,
			AgencyRepCode = ISNULL(BREP.RepCode,'nd'),
			HREP.LastName,
			HREP.FirstName,
			RREP.BusinessStart,
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			--Province = '',--case when HBoss.LastName like '%Brunswick%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			--AdrS.Region,

			Net = 0,
			NetPrec = (Brut - Retraits + reinscriptions),
			Cumul = 0,
			CumulPrec = 0

		from 
			#GNUSemainePrec SemainePrec
			JOIN dbo.Un_Unit U on U.UnitID = SemainePrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = SemainePrec.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = SemainePrec.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL -- très important le ALL
		
		select 
			U.UnitID,
			Cumul.RepID,
			Recruit = Recrue,
			RREP.RepCode,
			AgencyRepCode = ISNULL(BREP.RepCode,'nd'),
			HREP.LastName,
			HREP.FirstName,
			RREP.BusinessStart,
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			--Province = '',--case when HBoss.LastName like '%Brunswick%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			--AdrS.Region,

			Net = 0,
			NetPrec = 0,
			Cumul = (Brut - Retraits + reinscriptions),
			CumulPrec = 0

		from 
			#GNUCumul Cumul
			JOIN dbo.Un_Unit U on U.UnitID = Cumul.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Cumul.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Cumul.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL -- très important le ALL
		
		select 
			U.UnitID,
			CumulPrec.RepID,
			Recruit = Recrue,
			RREP.RepCode,
			AgencyRepCode = ISNULL(BREP.RepCode,'nd'),
			HREP.LastName,
			HREP.FirstName,
			RREP.BusinessStart,
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			--Province = '',--case when HBoss.LastName like '%Brunswick%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			--AdrS.Region,

			Net = 0,

			NetPrec = 0,

			Cumul = 0,

			CumulPrec = (Brut - Retraits + reinscriptions)

		from 
			#GNUCumulPrec CumulPrec
			JOIN dbo.Un_Unit U on U.UnitID = CumulPrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = CumulPrec.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = CumulPrec.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		) V
	
	JOIN #BossRepActuel M ON V.RepID = M.RepID
	JOIN dbo.Mo_Human B ON B.HumanID = M.BossID
	JOIN Un_Rep RB ON RB.RepID = M.BossID
	JOIN Un_Rep R on R.RepID = V.repID
	LEFT JOIN (
		select 
			V.DateFinPeriode,
			V.Weekno,
			OB.ObjSemaine,
			V.ObjCumul
		from (
			select 
				DateFinPeriode = max(DateFinPeriode),
				Weekno = max(Weekno),
				--ObjSemaine,
				ObjCumul = sum(ObjSemaine)
			from #TMPObjectifBulletin
			where DateFinPeriode <= @EndDate
			) V
		join #TMPObjectifBulletin OB ON V.DateFinPeriode = OB.DateFinPeriode
		) TMPObjectifBulletin ON TMPObjectifBulletin.DateFinPeriode = @EndDate

	group by
	
		V.RepID,
		Recruit,
		V.RepCode,
		V.AgencyRepCode,RB.RepCode, 
		V.LastName,
		V.FirstName,
		V.BusinessStart,
		case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		B.FirstName,B.LastName,
		RB.RepID,
		V.Agency,
		--Province,
		--Region,
		isnull(ObjSemaine,0),
		isnull(ObjCumul,0),
		isnull(Weekno,0)

	order by
	 	V.RepID--, V.Region
	
	SELECT 
		t.RepID,
		Recruit,
		RepCode,

		AgencyRepCode, 

		LastName = CASE WHEN t.repid = 663140 then 'Bakam' ELSE LastName end, -- on coupe à "Bakam" au lieu de "Bakam Epse Fokouo", sinon c'est trop long
		FirstName,
		BusinessStart,
		RepIsActive = CASE WHEN t.repid in (
										466100, --		Chantal Jobin
										629154, --		Steve Blais

										-- DIRECTEURS ADJOINTS JIRA TI-11315
										149497	, --	6158	Carole Marchand
										422223	, --	6987	Line Durivage
										702402	, --	70067	Véronic Bénard
										500292	, --	7361	Myriam Derome
										676177	, --	7923	Amélie Rancourt-Fortin	
										655109	  --	7862	Anne LeBlanc-Levesque								
										
										) THEN 0 ELSE RepIsActive END, -- CES 2 REP NE DOIVENT PAS SORTIR DANS LE RAPPORT ALORS JE LES MET INACTIF CAR C'EST UN FILTRE SUR LA PLUPART DES TABLEAU DU RAPPORT
		ActualAgency = replace(ActualAgency,'Moreau Gignac Groupe','Groupe Moreau Gignac'),
		
		Agency = replace(Agency,'Moreau Gignac Groupe','Groupe Moreau Gignac'),

		-- Agence du Rep
		AgenceActelReconnue = CASE WHEN  ActuelAgencyRepID in (

							149593,--	Martin	Mercier
							149489,--	Clément	Blais
							149521,--	Michel	Maheu
							436381--	Sophie	Babeux

							) then 1 ELSE 0 end,

		-- Agence
		AgenceReconnue = CASE WHEN  AgencyRepCode in (
							'7036'--Sophie Babeux
							,'6070'-- Clément Blais
							,'6262' --Michel Maheu
							,'5852' --Martin Mercier
							) then 1 ELSE 0 end,

		Agency_Region = Agency,
		
		--Province,
		--Region = Region,

		
		Net,
		NetPrec,
		Cumul,
		CumulPrec,
		ObjSemaine = @ObjectifSemaine,
		ObjCumul = @ObjCumul,
		Weekno
		,RecrueRencontreCritere = ISNULL(RecrueRencontreCritere,0)
		,StartDate = @StartDate
		,EndDate = @EndDate
		--,StartDatePrec = @StartDatePrec
		--,EndDatePrec = @EndDatePrec
	from 
		#table1 t
		
		left join (
						select 
							v.repid
							,RecrueRencontreCritere = 1
										-- rien de défini pour 2018 alors je met 1 par défaut
										/*
														CASE when 
															v.cumul >=
															(
															--CumulNecessaire
															case 
																-- embauché avant le début de l'année car ob.Weekno est NULL, 
																-- vu que businessStart ne fait pas partie d'une période de l'année en cours
																when isnull(ob.Weekno,0) = 0 then 75.0 / 52.0 * v.Weekno
																-- embauché après le début d'année car businessStart fait partie d'une période
																when isnull(ob.Weekno,0) > 0 then 75.0 / 52.0 * (v.Weekno - isnull(ob.Weekno,0))
															end
															)  then 1 ELSE 0
														end
										*/
						from (
							select DISTINCT
								t.repid
								,t.BusinessStart
								,Weekno -- Le week no de ce bulletin
								,cumul = sum(t.cumul) -- on totalise le cumul de toute les région de vente du rep
							from #table1 t
							where Recruit = 1
							group by 
								t.repid
								,t.BusinessStart,Weekno
							) v
						left join #TMPObjectifBulletin ob on v.BusinessStart between dateadd(d,-6,ob.DateFinPeriode) and ob.DateFinPeriode
				)RRC on RRC.repid = t.repid AND t.Recruit = 1

	where t.repid not in (
			149876	,--siege social
			764401	,--Nadine Babin
			584143	,--Véronique Guimond
			764400	,--Martine Larrivée
			769040	,--Annie Poirier
			770362	,--Caroline Samson
			752607	-- Hélène Roy
			)


set arithabort off	
		
END


