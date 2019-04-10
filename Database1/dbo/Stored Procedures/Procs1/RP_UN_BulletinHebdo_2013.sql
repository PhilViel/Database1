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
Note                :	2013-01-06 (environ)	Donald Huppé	Création
						2013-01-15		Donald Huppé	Couper à "Bakam" au lieu de "Bakam Epse Fokouo", sinon c'est trop long
														Remplacer 'Moreau Gignac Groupe' par 'Groupe Moreau Gignac'
						2013-03-25		Donald Huppé	 glpi 9363 : modification du calul de AgenceReconnue.
															on prend l'ActualAgency au lieu de Agency
						2013-04-02		Donald Huppé	création de AgenceActelReconnue et remettre calcul de AgenceReconnue comme avant.
						2013-04-19		Donald Huppé	Remplacer "agence Maryse Logelin" par "agence Nouveau-Brunswick"
						2013-04-30		Donald Huppé	GLPI 9568 : ajuster le rmeplacement de "agence Maryse Logelin" par "agence Nouveau-Brunswick"
						2013-05-17		Donald Huppé	glpi 9662 - Associer les ventes des rep du NB aux directeurs :  Jeannot Turgeon et Geneviève Duguay
						2013-05-28		Donald Huppé	Ajustement pour attribuer les ventes des boss actuel et ancien boss du NB à la province NB.
						2013-08-26		Donald Huppé	Correction de l'attribution des ventes pour le champ "Province".  il était bon seulement pour #GNUSemaine
						2013-10-03		Donald Huppé	GLPI 10257 - Attribution des rep à Nataly Désormeaux.   
														Ajout du champ RecrueRencontreCritere pour filtrer les recrue qui se qualifient dans le tableau des recrues
						2018-10-29  Pierre-Luc Simard   N'est plus utilisée
                        							
exec RP_UN_BulletinHebdo_2013_TEST '2013-09-30', '2013-10-06', '2012-10-01', '2012-10-07'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo_2013] (
	@StartDate DATETIME,
	@EndDate DATETIME, 
	@StartDatePrec DATETIME,
	@EndDatePrec DATETIME ) 
AS
BEGIN
    SELECT 1/0
    /*
	DECLARE @JanuaryFirst AS DATETIME
	DECLARE @JanuaryFirstPrec AS DATETIME
	--DECLARE @TauxReeeflex FLOAT
	
	--SET @TauxReeeflex = 1 -- Pas de majoration du ReeeFlex en 2011

	SET @JanuaryFirst = CAST(YEAR(@EndDate) as varchar(4)) + '-01-01'
	SET @JanuaryFirstPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-01-01'

	create table #TMPObjectifBulletin (
									DateFinPeriode varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)

	-- Objectifs pour chaque semaine de l'année
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (1,'2013-01-06',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (2,'2013-01-13',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (3,'2013-01-20',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (4,'2013-01-27',937.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (5,'2013-02-03',750,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (6,'2013-02-10',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (7,'2013-02-17',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (8,'2013-02-24',1687.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (9,'2013-03-03',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (10,'2013-03-10',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (11,'2013-03-17',1687.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (12,'2013-03-24',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (13,'2013-03-31',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (14,'2013-04-07',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (15,'2013-04-14',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (16,'2013-04-21',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (17,'2013-04-28',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (18,'2013-05-05',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (19,'2013-05-12',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (20,'2013-05-19',1687.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (21,'2013-05-26',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (22,'2013-06-02',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (23,'2013-06-09',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (24,'2013-06-16',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (25,'2013-06-23',937.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (26,'2013-06-30',1687.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (27,'2013-07-07',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (28,'2013-07-14',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (29,'2013-07-21',1125,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (30,'2013-07-28',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (31,'2013-08-04',937.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (32,'2013-08-11',937.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (33,'2013-08-18',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (34,'2013-08-25',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (35,'2013-09-01',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (36,'2013-09-08',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (37,'2013-09-15',1500,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (38,'2013-09-22',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (39,'2013-09-29',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (40,'2013-10-06',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (41,'2013-10-13',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (42,'2013-10-20',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (43,'2013-10-27',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (44,'2013-11-03',2062.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (45,'2013-11-10',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (46,'2013-11-17',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (47,'2013-11-24',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (48,'2013-12-01',1687.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (49,'2013-12-08',1312.5,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (50,'2013-12-15',1875,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (51,'2013-12-22',2250,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (52,'2013-12-29',750,0)

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
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDate,@EndDate, 0, 1

	update #GNUSemaine set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUSemaine set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUSemaine set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUSemaine set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUSemaine set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
 	--update #GNUSemaine set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
	update #GNUSemaine set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
	update #GNUSemaine set BossID = 675096 where RepID in (670591,149614)
	
	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUSemaine set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)

	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUSemaine set BossID = 149602 where bossid = 391561

	insert into #GNUSemainePrec
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec,@EndDatePrec, 0, 1

	update #GNUSemainePrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUSemainePrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUSemainePrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUSemainePrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUSemainePrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
 	--update #GNUSemainePrec set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
 	update #GNUSemainePrec set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
 	update #GNUSemainePrec set BossID = 675096 where RepID in (670591,149614)

	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUSemainePrec set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)

	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUSemainePrec set BossID = 149602 where bossid = 391561
 	
	insert into #GNUCumul
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirst , @EndDate , 0, 1

	update #GNUCumul set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumul set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumul set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumul set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumul set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
 	--update #GNUCumul set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
 	update #GNUCumul set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
 	update #GNUCumul set BossID = 675096 where RepID in (670591,149614)

	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) 
	update #GNUCumul set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)
	
	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUCumul set BossID = 149602 where bossid = 391561
	
	insert into #GNUCumulPrec
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1

	update #GNUCumulPrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumulPrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumulPrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumulPrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumulPrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
 	--update #GNUCumulPrec set BossID = 671417 where BossID = 298925 -- GLPI 9568 : Agence Maryse Logelin devient Agence Nouveau-Brunswick
	update #GNUCumulPrec set BossID = 659765 where RepID in (633701,655109,149509,149950,666383,665109,627824,659765)
	update #GNUCumulPrec set BossID = 675096 where RepID in (670591,149614)
	
	--glpi 10257 : l'agence Outaouais (Nataly Désormeaux) glpi 10257
	update #GNUCumulPrec set BossID = 436873 where RepID in (149957,436873,486526,507456,521423,531678,531679,546637,579157,649408,649409,664185,665199,665200)
	
	--glpi 10257 : nous souhaiterions que les unités de Ghislain Thibeault soit désormais attribuées à Daniel Turpin
	update #GNUCumulPrec set BossID = 149602 where bossid = 391561
	
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
	
	/*
	select 
		t.RepCode,
		t.BusinessStart
		,t.RepIsActive
		,t.cumul
		,SemaineArrivee = isnull(ob.Weekno,0)
		,t.Weekno
		,CumulNecessaire = case 
						-- embauché avant le début de l'année
						when isnull(ob.Weekno,0) = 0 then 150 / 52 * t.Weekno
						when isnull(ob.Weekno,0) > 0 then 150 / 52 * (t.Weekno - isnull(ob.Weekno,0))
						end
		, RecrueRencontreCritere = CASE when 
						t.cumul >=
						(--CumulNecessaire
						case 
						-- embauché avant le début de l'année
						when isnull(ob.Weekno,0) = 0 then 150 / 52 * t.Weekno
						when isnull(ob.Weekno,0) > 0 then 150 / 52 * (t.Weekno - isnull(ob.Weekno,0))
						end
						)  then 1 ELSE 0
					end
	from #table1 t
	left join #TMPObjectifBulletin ob on t.BusinessStart between dateadd(d,-7,ob.DateFinPeriode) and ob.DateFinPeriode
	where Recruit = 1
	and
		t.cumul >=
		(--CumulNecessaire
		case 
		-- embauché avant le début de l'année
		when isnull(ob.Weekno,0) = 0 then 150 / 52 * t.Weekno
		when isnull(ob.Weekno,0) > 0 then 150 / 52 * (t.Weekno - isnull(ob.Weekno,0))
		end
		)
	*/
	
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
							391561,--	Ghislain	Thibeault
							436381,--	Sophie	Babeux
							440176,--	Maryse	Breton
							658455--	Moreau Gignac	Groupe
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
							,'7863' --Moreau Gignac
							,'5632' --Roberto Perron
							,'6823' --Ghislain Thibeault,
							,'6413' --Daniel Turpin
							--,'7910' --Agence Nouveau-Brunswick
							,'7873' -- Geneviève Duguay
							,'6429' -- Jeannot Turgeon
							,'7919' -- Cabinet Turgeon et Associés
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

		ObjSemaine,
		ObjCumul,
		Weekno
		,RecrueRencontreCritere = ISNULL(RecrueRencontreCritere,0)
	from 
		#table1 t
		
		left join (
			select DISTINCT
				t.repid
				, RecrueRencontreCritere = CASE when 
								t.cumul >=
								(--CumulNecessaire
								case 
								-- embauché avant le début de l'année
								when isnull(ob.Weekno,0) = 0 then 150 / 52 * t.Weekno
								when isnull(ob.Weekno,0) > 0 then 150 / 52 * (t.Weekno - isnull(ob.Weekno,0))
								end
								)  then 1 ELSE 0
							end
			from #table1 t
			left join #TMPObjectifBulletin ob on t.BusinessStart between dateadd(d,-6,ob.DateFinPeriode) and ob.DateFinPeriode
			where Recruit = 1
			and
				t.cumul >=
				(--CumulNecessaire
				case 
				-- embauché avant le début de l'année
				when isnull(ob.Weekno,0) = 0 then 150 / 52 * t.Weekno
				when isnull(ob.Weekno,0) > 0 then 150 / 52 * (t.Weekno - isnull(ob.Weekno,0))
				end
				)
			)RRC on RRC.repid = t.repid AND t.Recruit = 1
	*/
END