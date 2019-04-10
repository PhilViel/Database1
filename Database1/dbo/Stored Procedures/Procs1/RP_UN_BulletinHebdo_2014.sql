/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */
/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas Inc.
Nom                 :	RP_UN_BulletinHebdo_2012
Description         :	Procédure stockée du rapport du Bulletin Hebdomadaire 2012
Valeurs de retours  :	Dataset 
Note                :	2013-12-13(environ)	Donald Huppé	    Création
						2014-01-21			Donald Huppé	    GLPI 10867 : Modification des objectifs de ventes
						2014-02-12			Donald Huppé	    GLPI 11007 : Correction du calcul du champ RecrueRencontreCritere, il faut totaliser le cumul de toute les région de vente du rep
						2014-02-21			Donald Huppé	    modification des agence reconnu enlever 6429 et 7919
						2014-03-11			Donald Huppé	    glpi 11008 : ajout de l'objectif mensuel + modification de l'objectif de la semaine
						2014-08-08			dONALD hUPPÉ	    GLPI 11926
						2014-10-09			Donald Huppé	    Générer les paramètre de date automatiquement selon @StartDate = '9999-12-31'.  Alors, on génère le bulletin pour la semaine en cours de Getdate
						2014-11-17			Donald Huppé	    ajout de l'option Ratio
                        2018-10-29          Pierre-Luc Simard   N'est plus utilisée

exec RP_UN_BulletinHebdo_2014 '9999-12-31', '9999-12-31', '9999-12-31', '9999-12-31'
exec RP_UN_BulletinHebdo_2014 '2014-11-10', '2014-11-16', '2013-11-11', '2013-11-17', 1

exec RP_UN_BulletinHebdo_2014
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo_2014] (
	@StartDate DATETIME,
	@EndDate DATETIME, 
	@StartDatePrec DATETIME,
	@EndDatePrec DATETIME,
	@CalculSelonRatio  bit = 1) 
AS
BEGIN
    
    SELECT 1/0
    /*
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
		set @StartDatePrec = DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())), 0)
		set @EndDatePrec = dateadd(dd,6, DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())   ), 0))
		end
	
	SELECT @DateDebutMois = DATEADD(mm, DATEDIFF(mm,0,@StartDate), 0)  
	SELECT @DateFinMois = DATEADD(d,-1, DATEADD(mm,1,DATEADD(mm, DATEDIFF(mm,0,@StartDate), 0)))

	SELECT @DateDebutMoisPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-' + CAST(month(@DateDebutMois)as varchar(4)) + '-' + CAST(DAY(@DateDebutMois)as varchar(4))
	SELECT @DateFinMoisPrec =  CAST(YEAR(@EndDatePrec) as varchar(4)) + '-' + CAST(month(@DateFinMois)as varchar(4)) + '-' + CAST(DAY(@DateFinMois)as varchar(4))

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

	-- Objectifs pour chaque semaine de l'année
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (1,'2014-01-05',500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (2,'2014-01-12',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (3,'2014-01-19',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (4,'2014-01-26',1000,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (5,'2014-02-02',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (6,'2014-02-09',1400,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (7,'2014-02-16',1700,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (8,'2014-02-23',1700,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (9,'2014-03-02',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (10,'2014-03-09',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (11,'2014-03-16',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (12,'2014-03-23',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (13,'2014-03-30',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (14,'2014-04-06',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (15,'2014-04-13',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (16,'2014-04-20',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (17,'2014-04-27',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (18,'2014-05-04',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (19,'2014-05-11',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (20,'2014-05-18',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (21,'2014-05-25',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (22,'2014-06-01',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (23,'2014-06-08',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (24,'2014-06-15',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (25,'2014-06-22',900,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (26,'2014-06-29',1000,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (27,'2014-07-06',1000,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (28,'2014-07-13',1000,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (29,'2014-07-20',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (30,'2014-07-27',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (31,'2014-08-03',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (32,'2014-08-10',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (33,'2014-08-17',800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (34,'2014-08-24',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (35,'2014-08-31',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (36,'2014-09-07',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (37,'2014-09-14',1300,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (38,'2014-09-21',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (39,'2014-09-28',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (40,'2014-10-05',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (41,'2014-10-12',1200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (42,'2014-10-19',1300,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (43,'2014-10-26',1700,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (44,'2014-11-02',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (45,'2014-11-09',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (46,'2014-11-16',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (47,'2014-11-23',1700,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (48,'2014-11-30',1600,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (49,'2014-12-07',1700,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (50,'2014-12-14',1800,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (51,'2014-12-21',2200,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (52,'2014-12-31',700,0)

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

	create table #GNUCumulMois (
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

	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUCumulMois
		exec SL_UN_RepGrossANDNetUnits NULL, @DateDebutMois,@DateFinMois, 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUCumulMois
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @DateDebutMois,@DateFinMois, 0, 1
		END
		
	select @NetMois = SUM((Brut - Retraits + reinscriptions)) from #GNUCumulMois
	
	/*
		@NetMoisPrec float,
		@ObjectifMoisActuel float,
		@NetMois float
	*/
	
	create table #GNUCumulMoisPrec (
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

	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUCumulMoisPrec
		exec SL_UN_RepGrossANDNetUnits NULL, @DateDebutMoisPrec,@DateFinMoisPrec, 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUCumulMoisPrec
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @DateDebutMoisPrec,@DateFinMoisPrec, 0, 1
		END

	select @NetMoisPrec = SUM((Brut - Retraits + reinscriptions)) from #GNUCumulMoisPrec
	select @ObjectifMoisActuel = @NetMoisPrec * 1.08

	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUSemaine
		exec SL_UN_RepGrossANDNetUnits NULL, @StartDate,@EndDate, 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUSemaine
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @StartDate,@EndDate, 0, 1
		END

	update #GNUSemaine set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUSemaine set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUSemaine set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUSemaine set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUSemaine set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUSemaine g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

 	/*
 	--update #GNUSemaine set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
	update #GNUSemaine set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
	update #GNUSemaine set BossID = 675096 where RepID in (670591,149614)
	
	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUSemaine set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)

	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUSemaine set BossID = 149602 where bossid = 391561
	*/
	
	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUSemainePrec
		exec SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec,@EndDatePrec, 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUSemainePrec
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @StartDatePrec,@EndDatePrec, 0, 1
		END	
	
	update #GNUSemainePrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUSemainePrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUSemainePrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUSemainePrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUSemainePrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUSemainePrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'
 	
	select @ObjectifSemaine = SUM((Brut - Retraits + reinscriptions))* 1.08 from #GNUSemainePrec 

 	/*
 	--update #GNUSemainePrec set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
 	update #GNUSemainePrec set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
 	update #GNUSemainePrec set BossID = 675096 where RepID in (670591,149614)

	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUSemainePrec set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)

	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUSemainePrec set BossID = 149602 where bossid = 391561
 	*/
 	
	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUCumul
		exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirst , @EndDate , 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUCumul
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @JanuaryFirst , @EndDate , 0, 1
		END	
 	
	update #GNUCumul set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumul set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumul set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumul set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumul set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUCumul g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'
 	
 	/*
 	--update #GNUCumul set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
 	update #GNUCumul set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
 	update #GNUCumul set BossID = 675096 where RepID in (670591,149614)

	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUCumul set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)
	
	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUCumul set BossID = 149602 where bossid = 391561
	*/
	
	if @CalculSelonRatio = 1
		BEGIN
		insert into #GNUCumulPrec
		exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1
		END
	ELSE
		BEGIN
		insert into #GNUCumulPrec
		exec SL_UN_RepGrossANDNetUnits_SansRatio NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1
		END	

	update #GNUCumulPrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumulPrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumulPrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumulPrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumulPrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNUCumulPrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	select @ObjCumul = SUM((Brut - Retraits + reinscriptions)) * 1.08 from #GNUCumulPrec

 	/*
 	--update #GNUCumulPrec set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
	update #GNUCumulPrec set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
	update #GNUCumulPrec set BossID = 675096 where RepID in (670591,149614)
	
	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) glpi 10257
	update #GNUCumulPrec set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)
	
	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUCumulPrec set BossID = 149602 where bossid = 391561
	*/
	
	select 
		V.RepID,
		Recruit = case when V.RepID = 594232 then 0 else V.Recruit end, -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		V.RepCode,

		AgencyRepCode = case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 

		V.LastName,
		V.FirstName,
		BusinessStart = case when V.RepID = 594232 then '1950-01-01' else V.BusinessStart end, -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		ActualAgency = replace(B.FirstName,'Agence','Ag.') + ' ' + B.LastName,
		ActuelAgencyRepID = RB.RepID,
		-- Si l'agence lors de la vente est Nd (non déterminé en date de InforceDate), alors on met l'agence actuelle,
		Agency = case when V.Agency = 'nd' then replace(B.FirstName,'Agence','Ag.') + ' ' + B.LastName else Agency end,
		Province,
		Region,

		Net = SUM(Net),
		NetInd = SUM(NetInd),
		NetUniv = SUM(NetUniv),
		NetRflex = SUM(NetRflex),

		NetPrec = SUM(NetPrec),
		NetIndPrec = SUM(NetIndPrec),
		NetUnivPrec = SUM(NetUnivPrec),
		NetRflexPrec = SUM(NetRflexPrec),

		Cumul = SUM(Cumul),
		CumulInd = SUM(CumulInd),
		CumulUniv = SUM(CumulUniv),
		CumulRflex = SUM(CumulRflex),

		CumulPrec = SUM(CumulPrec),
		CumulPrecInd = SUM(CumulPrecInd),
		CumulPrecUniv = SUM(CumulPrecUniv),
		CumulPrecRflex = SUM(CumulPrecRflex),

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
			Agency = ISNULL(Replace(HBoss.FirstName,'Agence','Ag.') + ' ' + HBoss.LastName,'nd'),
			Province = CASE when Semaine.BossID IN (659765,149614,671417,298925,675096) THEN 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,--case when HBoss.LastName like '%Brunswick%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			AdrS.Region,

			Net = (Brut - Retraits + reinscriptions),
			NetInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			NetUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			NetRflex = case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END,

			NetPrec = 0,
			NetIndPrec = 0,		
			NetUnivPrec = 0,	
			NetRflexPrec = 0,	

			Cumul = 0,
			CumulInd = 0,		
			CumulUniv = 0,		
			CumulRflex = 0,	

			CumulPrec = 0,
			CumulPrecInd = 0,		
			CumulPrecUniv = 0,		
			CumulPrecRflex = 0	

		from 
			#GNUSemaine Semaine
			JOIN dbo.Un_Unit U on U.UnitID = Semaine.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.MO_HUMAN HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Semaine.RepID
			JOIN dbo.MO_HUMAN HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Semaine.BossID
			LEFT JOIN dbo.MO_HUMAN HBoss on HBoss.HumanID = BREP.RepID
			JOIN (
				select
					adrid, 
					a.zipcode,
					CP2.CO_POSTL,
					Region =	case 
								when CP2.CO_POSTL is not null then case when CP2.CO_REGN_ADMNS = 11 then 'Gaspésie-Îles-Madeleine' else CP2.NM_REGN_ADMNS end 
								when CP2.CO_POSTL is null and a.zipcode like 'E%' then 'N.-Brunswick' 
								when CP2.CO_POSTL is null then '**Code postal inconnu**' 
								end
				FROM dbo.Mo_Adr a 
				left join (
						select CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						from GUI.dbo.CodePostalRegionAdm  CP
						join (
							select CO_POSTL, CO_REGN_ADMNS = max(CO_REGN_ADMNS) from GUI.dbo.CodePostalRegionAdm group by CO_POSTL
							) MaxCP on CP.CO_POSTL = MaxCP.CO_POSTL and CP.CO_REGN_ADMNS = MaxCP.CO_REGN_ADMNS
						group by CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						) CP2 on CP2.CO_POSTL = replace(a.zipcode,' ','')
					) AdrS on HS.adrID = AdrS.adrID
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
			Agency = ISNULL(Replace(HBoss.FirstName,'Agence','Ag.') + ' ' + HBoss.LastName,'nd'),
			Province = CASE when SemainePrec.BossID IN (659765,149614,671417,298925,675096) THEN 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			AdrS.Region,

			Net = 0,
			NetInd = 0,
			NetUniv = 0,
			NetRflex = 0,

			NetPrec = (Brut - Retraits + reinscriptions),
			NetIndPrec = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			NetUnivPrec = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			NetRflexPrec = case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END,

			Cumul = 0,
			CumulInd = 0,		
			CumulUniv = 0,		
			CumulRflex = 0,	

			CumulPrec = 0,
			CumulPrecInd = 0,		
			CumulPrecUniv = 0,		
			CumulPrecRflex = 0	

		from 
			#GNUSemainePrec SemainePrec
			JOIN dbo.Un_Unit U on U.UnitID = SemainePrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.MO_HUMAN HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = SemainePrec.RepID
			JOIN dbo.MO_HUMAN HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = SemainePrec.BossID
			LEFT JOIN dbo.MO_HUMAN HBoss on HBoss.HumanID = BREP.RepID
			JOIN (
				select
					adrid, 
					a.zipcode,
					CP2.CO_POSTL,
					Region =	case 
								when CP2.CO_POSTL is not null then case when CP2.CO_REGN_ADMNS = 11 then 'Gaspésie-Îles-Madeleine' else CP2.NM_REGN_ADMNS end 
								when CP2.CO_POSTL is null and a.zipcode like 'E%' then 'N.-Brunswick' 
								when CP2.CO_POSTL is null then '**Code postal inconnu**' 
								end
				FROM dbo.Mo_Adr a 
				left join (
						select CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						from GUI.dbo.CodePostalRegionAdm  CP
						join (
							select CO_POSTL, CO_REGN_ADMNS = max(CO_REGN_ADMNS) from GUI.dbo.CodePostalRegionAdm group by CO_POSTL
							) MaxCP on CP.CO_POSTL = MaxCP.CO_POSTL and CP.CO_REGN_ADMNS = MaxCP.CO_REGN_ADMNS
						group by CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						) CP2 on CP2.CO_POSTL = replace(a.zipcode,' ','')
					) AdrS on HS.adrID = AdrS.adrID
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
			Agency = ISNULL(Replace(HBoss.FirstName,'Agence','Ag.') + ' ' + HBoss.LastName,'nd'),
			Province = CASE when Cumul.BossID IN (659765,149614,671417,298925,675096) THEN 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			AdrS.Region,

			Net = 0,
			NetInd = 0,
			NetUniv = 0,
			NetRflex = 0,

			NetPrec = 0,
			NetIndPrec = 0,		
			NetUnivPrec = 0,	
			NetRflexPrec = 0,	

			Cumul = (Brut - Retraits + reinscriptions),
			CumulInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulRflex = case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END,

			CumulPrec = 0,
			CumulPrecInd = 0,		
			CumulPrecUniv = 0,		
			CumulPrecRflex = 0	

		from 
			#GNUCumul Cumul
			JOIN dbo.Un_Unit U on U.UnitID = Cumul.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.MO_HUMAN HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Cumul.RepID
			JOIN dbo.MO_HUMAN HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Cumul.BossID
			LEFT JOIN dbo.MO_HUMAN HBoss on HBoss.HumanID = BREP.RepID
			JOIN (
				select
					adrid, 
					a.zipcode,
					CP2.CO_POSTL,
					Region =	case 
								when CP2.CO_POSTL is not null then case when CP2.CO_REGN_ADMNS = 11 then 'Gaspésie-Îles-Madeleine' else CP2.NM_REGN_ADMNS end 
								when CP2.CO_POSTL is null and a.zipcode like 'E%' then 'N.-Brunswick' 
								when CP2.CO_POSTL is null then '**Code postal inconnu**' 
								end
				FROM dbo.Mo_Adr a 
				left join (
						select CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						from GUI.dbo.CodePostalRegionAdm  CP
						join (
							select CO_POSTL, CO_REGN_ADMNS = max(CO_REGN_ADMNS) from GUI.dbo.CodePostalRegionAdm group by CO_POSTL
							) MaxCP on CP.CO_POSTL = MaxCP.CO_POSTL and CP.CO_REGN_ADMNS = MaxCP.CO_REGN_ADMNS
						group by CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						) CP2 on CP2.CO_POSTL = replace(a.zipcode,' ','')
					) AdrS on HS.adrID = AdrS.adrID
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
			Agency = ISNULL(Replace(HBoss.FirstName,'Agence','Ag.') + ' ' + HBoss.LastName,'nd'),
			Province = CASE when CumulPrec.BossID IN (659765,149614,671417,298925,675096) THEN 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			AdrS.Region,

			Net = 0,
			NetInd = 0,
			NetUniv = 0,
			NetRflex = 0,

			NetPrec = 0,
			NetIndPrec = 0,		
			NetUnivPrec = 0,	
			NetRflexPrec = 0,	

			Cumul = 0,
			CumulInd = 0,		
			CumulUniv = 0,		
			CumulRflex = 0,	

			CumulPrec = (Brut - Retraits + reinscriptions),
			CumulPrecInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulPrecUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulPrecRflex = case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END

		from 
			#GNUCumulPrec CumulPrec
			JOIN dbo.Un_Unit U on U.UnitID = CumulPrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.MO_HUMAN HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = CumulPrec.RepID
			JOIN dbo.MO_HUMAN HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = CumulPrec.BossID
			LEFT JOIN dbo.MO_HUMAN HBoss on HBoss.HumanID = BREP.RepID
			JOIN (
				select
					adrid, 
					a.zipcode,
					CP2.CO_POSTL,
					Region =	case 
								when CP2.CO_POSTL is not null then case when CP2.CO_REGN_ADMNS = 11 then 'Gaspésie-Îles-Madeleine' else CP2.NM_REGN_ADMNS end 
								when CP2.CO_POSTL is null and a.zipcode like 'E%' then 'N.-Brunswick' 
								when CP2.CO_POSTL is null then '**Code postal inconnu**' 
								end
				FROM dbo.Mo_Adr a 
				left join (
						select CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						from GUI.dbo.CodePostalRegionAdm  CP
						join (
							select CO_POSTL, CO_REGN_ADMNS = max(CO_REGN_ADMNS) from GUI.dbo.CodePostalRegionAdm group by CO_POSTL
							) MaxCP on CP.CO_POSTL = MaxCP.CO_POSTL and CP.CO_REGN_ADMNS = MaxCP.CO_REGN_ADMNS
						group by CP.CO_POSTL, CP.CO_REGN_ADMNS, CP.NM_REGN_ADMNS
						) CP2 on CP2.CO_POSTL = replace(a.zipcode,' ','')
					) AdrS on HS.adrID = AdrS.adrID
		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		) V
		
	JOIN ( -- #MaxPctBoss
		SELECT
			RB.RepID,
			BossID = MAX(BossID)
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
	) M ON V.RepID = M.RepID
	JOIN dbo.Mo_Human B ON B.HumanID = M.BossID
	JOIN Un_Rep RB ON RB.RepID = M.BossID
	JOIN Un_Rep R on R.RepID = V.repID
	--LEFT JOIN #TMPObjectifBulletin TMPObjectifBulletin on TMPObjectifBulletin.DateFinPeriode = @EndDate 
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
		case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 
		V.LastName,
		V.FirstName,
		V.BusinessStart,
		case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		replace(B.FirstName,'Agence','Ag.') + ' ' + B.LastName,
		RB.RepID,
		case when V.Agency = 'nd' then replace(B.FirstName,'Agence','Ag.') + ' ' + B.LastName else Agency end,
		Province,
		Region,
		isnull(ObjSemaine,0),
		isnull(ObjCumul,0),
		isnull(Weekno,0)

	order by
	 	V.RepID, V.Region
	
	SELECT 
		t.RepID,
		Recruit,
		RepCode,

		AgencyRepCode, 

		LastName = CASE WHEN t.repid = 663140 then 'Bakam' ELSE LastName end, -- on coupe à "Bakam" au lieu de "Bakam Epse Fokouo", sinon c'est trop long
		FirstName,
		BusinessStart,
		RepIsActive,
		ActualAgency = replace(ActualAgency,'Moreau Gignac Groupe','Groupe Moreau Gignac'),
		/*		
		ActualAgency = case 
						when replace(ActualAgency,'Moreau Gignac Groupe','Groupe Moreau Gignac') LIKE '%Logelin%' THEN 'Ag. N.-Brunswick'
						ELSE replace(ActualAgency,'Moreau Gignac Groupe','Groupe Moreau Gignac')
						end ,
		*/
		
		Agency = replace(Agency,'Moreau Gignac Groupe','Groupe Moreau Gignac'),
		/*
		Agency = CASE 
						when replace(Agency,'Moreau Gignac Groupe','Groupe Moreau Gignac')  LIKE '%Logelin%' THEN 'Ag. N.-Brunswick'
						ELSE replace(Agency,'Moreau Gignac Groupe','Groupe Moreau Gignac')
						end,
		*/

		-- Agence du Rep
		AgenceActelReconnue = CASE WHEN  ActuelAgencyRepID in (
							149469,--	Roberto	Perron
							149593,--	Martin	Mercier
							149489,--	Clément	Blais
							149521,--	Michel	Maheu
							149602,--	Daniel	Turpin
							--298925,--	Maryse	Logelin
							--391561,--	Ghislain	Thibeault
							436381,--	Sophie	Babeux
							440176--	Maryse	Breton
							--658455--	Moreau Gignac	Groupe
							--,671417 -- Agence Nouveau-Brunswick
							,149614 -- Jeannot Turgeon
							,675096 -- Cabinet Turgeon et Associés
							,659765 -- Geneviève Duguay
							,436873 -- Nataly Désormeaux
							) then 1 ELSE 0 end,

		-- Agence
		AgenceReconnue = CASE WHEN  AgencyRepCode in (
							'7036'--Sophie Babeux
							,'6070'-- Clément Blais
							,'7059'-- Maryse Breton
							--,'6765'-- Maryse Logelin
							,'6262' --Michel Maheu
							,'5852' --Martin Mercier
							--,'7863' --Moreau Gignac
							,'5632' --Roberto Perron
							--,'6823' --Ghislain Thibeault,
							,'6413' --Daniel Turpin
							--,'7910' --Agence Nouveau-Brunswick
							,'7873' -- Geneviève Duguay
							--,'6429' -- Jeannot Turgeon
							--,'7919' -- Cabinet Turgeon et Associés
							,'7042'--	Nataly	Désormeaux
							) then 1 ELSE 0 end,

		Agency_Region = case 
			when Agency like '%Mercier%' then Agency + ' (QC-SLS-CN)' 
			when Agency like '%Turpin%' then Agency + ' (MTL-OUT-ABT)' 
			when Agency like '%Babeux%' then Agency + ' (MTL)' 
			when Agency like '%Maheu%' then Agency + ' (MTL)' 
			when Agency like '%Blais%' then Agency + ' (MTL)' 
			when Agency like '%Perron%' then Agency + ' (QC-CHA-BSL-GIM)' 
			when Agency like '%Breton%' then Agency + ' (CDQ-EST-MAU)' 
			--when Agency like '%Brunswick%' then Agency + ' (NB)' 
			when Agency like '%Duguay%' then Agency + ' (NB)' 
			when Agency like '%Turgeon%' then Agency + ' (NB)' 
			when Agency like '%Thibeault%' then Agency + ' (MTL anglo)' 
			when Agency like '%Moreau Gignac%' then 'Groupe Moreau Gignac (MTL)' 
			when Agency like '%Désormeaux%' then Agency + ' (OUT)' 
			ELSE Agency
			end,
		
		Province,
		Region = CASE 
			when Region LIKE '%Montérégie%' THEN Region + ' (MTL)'
			when Region LIKE '%Montréal%' THEN Region + ' (MTL)'
			when Region LIKE '%Capitale%' THEN Region + ' (QC)'
			when Region LIKE '%Lanaudière%' THEN Region + ' (MTL)'
			when Region LIKE '%Laurentides%' THEN Region + ' (MTL)'
			when Region LIKE '%Chaudière%' THEN Region + ' (CHA)'
			when Region LIKE '%Outaouais%' THEN Region + ' (OUT)'
			when Region LIKE '%Centre%' THEN Region + ' (CDQ)'
			when Region LIKE '%Estrie%' THEN Region + ' (EST)'
			when Region LIKE '%Laval%' THEN Region + ' (MTL)'
			when Region LIKE '%Saguenay%' THEN Region + ' (SLS)'
			when Region LIKE '%Brunswick%' THEN Region + ' (NB)'
			when Region LIKE '%Bas-Saint-Laurent%' THEN Region + ' (BSL)'
			when Region LIKE '%Côte-Nord%' THEN Region + ' (CN)'
			when Region LIKE '%Mauricie%' THEN Region + ' (MAU)'
			when Region LIKE '%Abitibi%' THEN Region + ' (ABT)'
			when Region LIKE '%Gaspésie%' THEN Region + ' (GIM)'
			when Region LIKE '%Nord-du-Québec%' THEN Region + ' (CN)'
			ELSE Region
			end,
		
		Net,
		NetInd,
		NetUniv,
		NetRflex,

		NetPrec,
		NetIndPrec,
		NetUnivPrec,
		NetRflexPrec,

		Cumul,
		CumulInd,
		CumulUniv,
		CumulRflex,

		CumulPrec,
		CumulPrecInd,
		CumulPrecUniv,
		CumulPrecRflex,

		ObjSemaine = @ObjectifSemaine,
		ObjCumul = @ObjCumul,
		Weekno
		,RecrueRencontreCritere = ISNULL(RecrueRencontreCritere,0)
		,NetMoisPrec = @NetMoisPrec
		,ObjectifMoisActuel = @ObjectifMoisActuel
		,NetMois = @NetMois
		,StartDate = @StartDate
		,EndDate = @EndDate
		,StartDatePrec = @StartDatePrec
		,EndDatePrec = @EndDatePrec
	from 
		#table1 t
		
		left join (
			select 
				v.repid
				,RecrueRencontreCritere = CASE when 
												v.cumul >=
												(
												--CumulNecessaire
												case 
													-- embauché avant le début de l'année car ob.Weekno est NULL, 
													-- vu que businessStart ne fait pas partie d'une période de l'année en cours
													when isnull(ob.Weekno,0) = 0 then 150 / 52 * v.Weekno
													-- embauché après le début d'année car businessStart fait partie d'une période
													when isnull(ob.Weekno,0) > 0 then 150 / 52 * (v.Weekno - isnull(ob.Weekno,0))
												end
												)  then 1 ELSE 0
											end
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
	*/
END