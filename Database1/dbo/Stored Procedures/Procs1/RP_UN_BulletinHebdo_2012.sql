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
Note                :	2012-01-10	Donald Huppé	    Création
						2012-08-07	Donald Huppé	    Modification du calcul de ObjCumul
													    Et GLPI 8023
						2018-10-29  Pierre-Luc Simard   N'est plus utilisée						

exec RP_UN_BulletinHebdo_2012 '2012-07-30', '2012-08-05', '2011-08-01', '2011-08-07'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo_2012] (
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

	-- #######################################################################################################################################
	-- ############# à partir de 2013, plus besoin d'inscrire ObjCumul car je le calcule dans le script en faisant sum(ObjSemaine) ###########
	-- #######################################################################################################################################

	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (1,'2012-01-08',856.94,856.94)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (2,'2012-01-15',856.94,1713.87)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (3,'2012-01-22',856.94,2570.81)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (4,'2012-01-29',856.94,3427.74)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (5,'2012-02-05',1494.67,4922.41)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (6,'2012-02-12',1494.67,6417.08)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (7,'2012-02-19',1494.67,7911.75)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (8,'2012-02-26',1494.67,9406.41)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (9,'2012-03-04',1465.88,10872.29)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (10,'2012-03-11',1465.88,12338.17)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (11,'2012-03-18',1465.88,13804.04)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (12,'2012-03-25',1465.88,15269.92)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (13,'2012-04-01',1608.55,16878.47)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (14,'2012-04-08',1608.55,18487.03)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (15,'2012-04-15',1608.55,20095.58)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (16,'2012-04-22',1608.55,21704.13)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (17,'2012-04-29',1608.55,23312.68)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (18,'2012-05-06',1408.84,24721.52)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (19,'2012-05-13',1408.84,26130.36)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (20,'2012-05-20',1408.84,27539.20)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (21,'2012-05-27',1408.84,28948.04)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (22,'2012-06-03',1438.45,30386.49)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (23,'2012-06-10',1438.45,31824.94)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (24,'2012-06-17',1438.45,33263.39)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (25,'2012-06-24',1438.45,34701.84)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (26,'2012-07-01',1213.58,35915.42)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (27,'2012-07-08',1213.58,37129.00)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (28,'2012-07-15',1213.58,38342.58)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (29,'2012-07-22',1213.58,39556.16)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (30,'2012-07-29',1213.58,40769.74)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (31,'2012-08-05',1325.23,42094.96)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (32,'2012-08-12',1325.23,43420.19)
	
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (33,'2012-08-19',1538,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (34,'2012-08-26',1273,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (35,'2012-09-02',1579,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (36,'2012-09-09',1579,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (37,'2012-09-16',1579,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (38,'2012-09-23',1579,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (39,'2012-09-30',1579,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (40,'2012-10-07',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (41,'2012-10-14',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (42,'2012-10-21',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (43,'2012-10-28',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (44,'2012-11-04',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (45,'2012-11-11',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (46,'2012-11-18',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (47,'2012-11-25',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (48,'2012-12-02',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (49,'2012-12-09',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (50,'2012-12-16',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (51,'2012-12-23',1336,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (52,'2012-12-31',1336,0)

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

	insert into #GNUSemainePrec
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec,@EndDatePrec, 0, 1

	update #GNUSemainePrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUSemainePrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUSemainePrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUSemainePrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUSemainePrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	insert into #GNUCumul
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirst , @EndDate , 0, 1

	update #GNUCumul set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumul set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumul set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumul set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumul set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	insert into #GNUCumulPrec
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1

	update #GNUCumulPrec set RepID = 580886 where repid = 584960 -- Jean-François Gemme
 	update #GNUCumulPrec set RepID = 580841 where repid = 584150 -- Paule Ducharme
 	update #GNUCumulPrec set RepID = 557514 where repid = 578803 -- Marcelle Poulin
 	update #GNUCumulPrec set RepID = 500292 where repid = 584963 -- Myriam Derome
 	update #GNUCumulPrec set RepID = 488309 where repid = 590338 -- Sébastien Sévigny
 	
	select 
		V.RepID,
		Recruit = case when V.RepID = 594232 then 0 else V.Recruit end, -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		V.RepCode,

		AgencyRepCode = case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 

		V.LastName,
		V.FirstName,
		BusinessStart = case when V.RepID = 594232 then '1950-01-01' else V.BusinessStart end, -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		RepIsActive = case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		ActualAgency = B.FirstName + ' ' + B.LastName,

		-- Si l'agence lors de la vente est Nd (non déterminé en date de InforceDate), alors on met l'agence actuelle,
		Agency = case when V.Agency = 'nd' then B.FirstName + ' ' + B.LastName else Agency end,
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
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'nd'),
			Province = case when HBoss.LastName like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
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
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'nd'),
			Province = case when HBoss.LastName like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
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
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'nd'),
			Province = case when HBoss.LastName like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
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
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'nd'),
			Province = case when HBoss.LastName like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
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
		B.FirstName + ' ' + B.LastName,
		case when V.Agency = 'nd' then B.FirstName + ' ' + B.LastName else Agency end,
		Province,
		Region,
		isnull(ObjSemaine,0),
		isnull(ObjCumul,0),
		isnull(Weekno,0)

	order by
	 	V.RepID, V.Region
	
	SELECT 
		RepID,
		Recruit,
		RepCode,

		AgencyRepCode, 

		LastName,
		FirstName,
		BusinessStart,
		RepIsActive,
		ActualAgency,

		Agency,

		Agency_Region = case 
			when Agency like '%Mercier%' then Agency + ' (QC-SLS-CN)' 
			when Agency like '%Turpin%' then Agency + ' (MTL-OUT-ABT)' 
			when Agency like '%Babeux%' then Agency + ' (MTL)' 
			when Agency like '%Maheu%' then Agency + ' (MTL)' 
			when Agency like '%Blais%' then Agency + ' (MTL)' 
			when Agency like '%Perron%' then Agency + ' (QC-CHA-BSL-GIM)' 
			when Agency like '%Breton%' then Agency + ' (CDQ-EST-MAU)' 
			when Agency like '%Logelin%' then Agency + ' (NB)' 
			when Agency like '%Dessureault%' then Agency + ' (MTL)' 
			when Agency like '%Thibeault%' then Agency + ' (MTL anglo)' 
		
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
	from 
		#table1
	*/
END