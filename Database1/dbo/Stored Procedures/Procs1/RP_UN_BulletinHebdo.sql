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
Copyrights (c) 2009 Gestion Universitas Inc.
Nom                 :	RP_UN_BulletinHebdo 
Description         :	Procédure stockée du rapport : BulletinHebdoRep
Valeurs de retours  :	Dataset 
Note                :	2009-02-22	Donald Huppé        Création
						2009-04-27	Donald Huppé	    Sortir les Net ventilés par plan afin d'afficer les % de chaque plan
													    Chnager les date du tableau des objectifs pour le dimanche au lieu du lundi
						2009-05-27	Donald Huppé	    Remettre les dates du tableau des objectifs au lundi au lieu du dimmanche à partir de la semaine 24
						2009-09-18	Donald Huppé	    Mettre #TMPObjectifBulletin au lieu de dbo.TMPObjectifBulletin
						2010-01-08	Donald Huppé	    Ajustement pour les cas de divorce quand il n'y a pas de Directeur associé au inforceDate du Unitid
													    Alors on met le directeur actuel
						2010-01-20	Donald Huppé	    Refait la SP au complet à partir de SL_UN_RepGrossANDNetUnits au lieu de FN_UN_RepContestREP_Bulletin
													    Dans le but de faire un meilleur calcul des Recrues
                        2018-10-29  Piuerre-Luc Simard  N'est plus utilisée
													
exec RP_UN_BulletinHebdo_NEW '2009-12-21', '2009-12-31', '2008-12-21', '2008-12-31'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo] (
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
	DECLARE @TauxReeeflex FLOAT
	
	SET @TauxReeeflex = 1.25

	SET @JanuaryFirst = CAST(YEAR(@EndDate) as varchar(4)) + '-01-01'
	SET @JanuaryFirstPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-01-01'

	create table #TMPObjectifBulletin (
									DebutSem varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)
	insert into #TMPObjectifBulletin values ('2009-01-04',1,	1969.115788	,	1969.115788	)
	insert into #TMPObjectifBulletin values ('2009-01-11',2,	929.5771155	,	2898.692904	)
	insert into #TMPObjectifBulletin values ('2009-01-18',3,	700.1203143	,	3598.813218	)
	insert into #TMPObjectifBulletin values ('2009-01-25',4,	1447.61732	,	5046.430538	)
	insert into #TMPObjectifBulletin values ('2009-02-01',5,	1776.099577	,	6822.530114	)
	insert into #TMPObjectifBulletin values ('2009-02-08',6,	1978.700658	,	8801.230772	)
	insert into #TMPObjectifBulletin values ('2009-02-15',7,	1651.733417	,	10452.96419	)
	insert into #TMPObjectifBulletin values ('2009-02-22',8,	1090.151835	,	11543.11603	)
	insert into #TMPObjectifBulletin values ('2009-03-01',10,	1692.423902	,	13235.53993	)
	insert into #TMPObjectifBulletin values ('2009-03-08',11,	1398.019286	,	14633.55921	)
	insert into #TMPObjectifBulletin values ('2009-03-15',12,	1649.69804	,	16283.25725	)
	insert into #TMPObjectifBulletin values ('2009-03-22',13,	1540.221015	,	17823.47827	)
	insert into #TMPObjectifBulletin values ('2009-03-29',14,	1562.722768	,	19386.20104	)
	insert into #TMPObjectifBulletin values ('2009-04-05',15,	1299.80764	,	20686.00868	)
	insert into #TMPObjectifBulletin values ('2009-04-12',16,	1598.752188	,	22284.76087	)
	insert into #TMPObjectifBulletin values ('2009-04-19',17,	1552.064762	,	23836.82563	)
	insert into #TMPObjectifBulletin values ('2009-04-26',18,	1564.481757	,	25401.30738	)
	insert into #TMPObjectifBulletin values ('2009-05-03',19,	1761.421999	,	27162.72938	)
	insert into #TMPObjectifBulletin values ('2009-05-10',20,	1901.494515	,	29064.2239	)
	insert into #TMPObjectifBulletin values ('2009-05-17',21,	2020.988053	,	31085.21195	)
	insert into #TMPObjectifBulletin values ('2009-05-24',22,	2028.059837	,	33113.27179	)
	insert into #TMPObjectifBulletin values ('2009-05-31',23,	1480.429035	,	34593.70082	)
	insert into #TMPObjectifBulletin values ('2009-06-08',24,	1767.669737	,	36361.37056	)
	insert into #TMPObjectifBulletin values ('2009-06-15',25,	1523.473938	,	37884.8445	)
	insert into #TMPObjectifBulletin values ('2009-06-22',26,	1908.890458	,	39793.73495	)
	insert into #TMPObjectifBulletin values ('2009-06-29',27,	1634.295369	,	41428.03032	)
	insert into #TMPObjectifBulletin values ('2009-07-06',28,	1476.45894	,	42904.48926	)
	insert into #TMPObjectifBulletin values ('2009-07-13',29,	1460.943667	,	44365.43293	)
	insert into #TMPObjectifBulletin values ('2009-07-20',30,	1430.93678	,	45796.36971	)
	insert into #TMPObjectifBulletin values ('2009-07-27',31,	1194.273412	,	46990.64312	)
	insert into #TMPObjectifBulletin values ('2009-08-03',32,	1221.688733	,	48212.33186	)
	insert into #TMPObjectifBulletin values ('2009-08-10',33,	1588.631603	,	49800.96346	)
	insert into #TMPObjectifBulletin values ('2009-08-17',34,	2090.050981	,	51891.01444	)
	insert into #TMPObjectifBulletin values ('2009-08-24',35,	1899.839598	,	53790.85404	)
	insert into #TMPObjectifBulletin values ('2009-08-31',36,	2686.662208	,	56477.51624	)
	insert into #TMPObjectifBulletin values ('2009-09-07',37,	2452.972573	,	58930.48882	)
	insert into #TMPObjectifBulletin values ('2009-09-14',38,	2043.686007	,	60974.17482	)
	insert into #TMPObjectifBulletin values ('2009-09-21',39,	2247.349988	,	63221.52481	)
	insert into #TMPObjectifBulletin values ('2009-09-28',40,	2273.337304	,	65494.86212	)
	insert into #TMPObjectifBulletin values ('2009-10-05',41,	2235.606902	,	67730.46902	)
	insert into #TMPObjectifBulletin values ('2009-10-12',42,	2236.990549	,	69967.45957	)
	insert into #TMPObjectifBulletin values ('2009-10-19',43,	1891.044652	,	71858.50422	)
	insert into #TMPObjectifBulletin values ('2009-10-26',44,	2554.497465	,	74413.00169	)
	insert into #TMPObjectifBulletin values ('2009-11-02',45,	2202.549509	,	76615.55119	)
	insert into #TMPObjectifBulletin values ('2009-11-09',46,	1807.106238	,	78422.65743	)
	insert into #TMPObjectifBulletin values ('2009-11-16',47,	2363.030393	,	80785.68782	)
	insert into #TMPObjectifBulletin values ('2009-11-23',48,	2202.068388	,	82987.75621	)
	insert into #TMPObjectifBulletin values ('2009-11-30',49,	2556.11826	,	85543.87447	)
	insert into #TMPObjectifBulletin values ('2009-12-07',50,	2330.74245	,	87874.61692	)
	insert into #TMPObjectifBulletin values ('2009-12-14',51,	2345.884088	,	90220.50101	)
	insert into #TMPObjectifBulletin values ('2009-12-21',52,	2081.498301	,	92301.99931	)
	insert into #TMPObjectifBulletin values ('2009-12-28',53,	1187.280108	,	93489.27942	)

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

	insert into #GNUSemainePrec
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDatePrec,@EndDatePrec, 0, 1

	insert into #GNUCumul
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirst , @EndDate , 0, 1

	insert into #GNUCumulPrec
	exec SL_UN_RepGrossANDNetUnits NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1

	select 
		V.RepID,
		V.Recruit,
		V.RepCode,

		AgencyRepCode = case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 

		V.LastName,
		V.FirstName,
		V.BusinessStart,
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
		
	--into TMPNew -- drop table TMPNew

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

			Net = (Brut - Retraits + reinscriptions) * (case when c.planid in (10,12) then @TauxReeeflex else 1 end),
			NetInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			NetUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			NetRflex = @TauxReeeflex * (case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END),

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

			NetPrec = (Brut - Retraits + reinscriptions) * (case when c.planid in (10,12) then @TauxReeeflex else 1 end),
			NetIndPrec = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			NetUnivPrec = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			NetRflexPrec = @TauxReeeflex * (case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END),

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

			Cumul = (Brut - Retraits + reinscriptions) * (case when c.planid in (10,12) then @TauxReeeflex else 1 end),
			CumulInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulRflex = @TauxReeeflex * (case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END),

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

			CumulPrec = (Brut - Retraits + reinscriptions) * (case when c.planid in (10,12) then @TauxReeeflex else 1 end),
			CumulPrecInd = case when planid = 4 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulPrecUniv = case when planid = 8 then (Brut - Retraits + reinscriptions) else 0 END,
			CumulPrecRflex = @TauxReeeflex * (case when planid in (10,12) then (Brut - Retraits + reinscriptions) else 0 END)

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
	LEFT JOIN #TMPObjectifBulletin TMPObjectifBulletin on TMPObjectifBulletin.DebutSem = @StartDate

	-- where (case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end) not in ('60002', '50003') -- Exclure CGL et Industrielle Alliance

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
	*/	
END