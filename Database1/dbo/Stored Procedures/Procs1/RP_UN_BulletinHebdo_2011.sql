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
Nom                 :	RP_UN_BulletinHebdo_2011
Description         :	Procédure stockée du rapport du Bulletin Hebdomadaire 2011
Valeurs de retours  :	Dataset 
Note                :	2011-01-11	Donald Huppé	    Création
                        2018-10-29  Pierre-Luc Simard   N'est plus utilisée
												
exec RP_UN_BulletinHebdo_2011 '2011-07-25', '2011-07-31', '2010-07-26', '2010-08-01'

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[RP_UN_BulletinHebdo_2011] (
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
									DebutSem varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)

	insert into #TMPObjectifBulletin values (	'2011-01-01'	,	1	,	690.413		,	690.413		)
	insert into #TMPObjectifBulletin values (	'2011-01-10'	,	2	,	690.413		,	1380.826	)
	insert into #TMPObjectifBulletin values (	'2011-01-17'	,	3	,	690.413		,	2071.239	)
	insert into #TMPObjectifBulletin values (	'2011-01-24'	,	4	,	690.413		,	2761.653	)
	insert into #TMPObjectifBulletin values (	'2011-01-31'	,	5	,	1058.383	,	3820.035	)
	insert into #TMPObjectifBulletin values (	'2011-02-07'	,	6	,	1058.383	,	4878.418	)
	insert into #TMPObjectifBulletin values (	'2011-02-14'	,	7	,	1058.383	,	5936.801	)
	insert into #TMPObjectifBulletin values (	'2011-02-21'	,	8	,	1058.383	,	6995.184	)
	insert into #TMPObjectifBulletin values (	'2011-02-28'	,	9	,	1367.505	,	8362.689	)
	insert into #TMPObjectifBulletin values (	'2011-03-07'	,	10	,	1367.505	,	9730.195	)
	insert into #TMPObjectifBulletin values (	'2011-03-14'	,	11	,	1367.505	,	11097.700	)
	insert into #TMPObjectifBulletin values (	'2011-03-21'	,	12	,	1367.505	,	12465.205	)
	insert into #TMPObjectifBulletin values (	'2011-03-28'	,	13	,	1194.709	,	13659.915	)
	insert into #TMPObjectifBulletin values (	'2011-04-04'	,	14	,	1194.709	,	14854.624	)
	insert into #TMPObjectifBulletin values (	'2011-04-11'	,	15	,	1194.709	,	16049.333	)
	insert into #TMPObjectifBulletin values (	'2011-04-18'	,	16	,	1194.709	,	17244.043	)
	insert into #TMPObjectifBulletin values (	'2011-04-25'	,	17	,	1194.709	,	18438.752	)
	insert into #TMPObjectifBulletin values (	'2011-05-02'	,	18	,	1303.397	,	19742.149	)
	insert into #TMPObjectifBulletin values (	'2011-05-09'	,	19	,	1303.397	,	21045.546	)
	insert into #TMPObjectifBulletin values (	'2011-05-16'	,	20	,	1303.397	,	22348.943	)
	insert into #TMPObjectifBulletin values (	'2011-05-23'	,	21	,	1303.397	,	23652.340	)
	insert into #TMPObjectifBulletin values (	'2011-05-30'	,	22	,	1170.134	,	24822.474	)
	insert into #TMPObjectifBulletin values (	'2011-06-06'	,	23	,	1170.134	,	25992.607	)
	insert into #TMPObjectifBulletin values (	'2011-06-13'	,	24	,	1170.134	,	27162.741	)
	insert into #TMPObjectifBulletin values (	'2011-06-20'	,	25	,	1170.134	,	28332.874	)
	insert into #TMPObjectifBulletin values (	'2011-06-27'	,	26	,	1061.984	,	29394.859	)
	insert into #TMPObjectifBulletin values (	'2011-07-04'	,	27	,	1061.984	,	30456.843	)
	insert into #TMPObjectifBulletin values (	'2011-07-11'	,	28	,	1061.984	,	31518.827	)
	insert into #TMPObjectifBulletin values (	'2011-07-18'	,	29	,	1061.984	,	32580.811	)
	insert into #TMPObjectifBulletin values (	'2011-07-25'	,	30	,	980.319		,	33561.130	)
	insert into #TMPObjectifBulletin values (	'2011-08-01'	,	31	,	980.319		,	34541.449	)
	insert into #TMPObjectifBulletin values (	'2011-08-08'	,	32	,	980.319		,	35521.767	)
	insert into #TMPObjectifBulletin values (	'2011-08-15'	,	33	,	980.319		,	36502.086	)
	insert into #TMPObjectifBulletin values (	'2011-08-22'	,	34	,	980.319		,	37482.405	)
	insert into #TMPObjectifBulletin values (	'2011-08-29'	,	35	,	1113.298	,	38595.703	)
	insert into #TMPObjectifBulletin values (	'2011-09-05'	,	36	,	1113.298	,	39709.001	)
	insert into #TMPObjectifBulletin values (	'2011-09-12'	,	37	,	1113.298	,	40822.299	)
	insert into #TMPObjectifBulletin values (	'2011-09-19'	,	38	,	1113.298	,	41935.597	)
	insert into #TMPObjectifBulletin values (	'2011-09-26'	,	39	,	1353.568	,	43289.165	)
	insert into #TMPObjectifBulletin values (	'2011-10-03'	,	40	,	1353.568	,	44642.734	)
	insert into #TMPObjectifBulletin values (	'2011-10-10'	,	41	,	1353.568	,	45996.302	)
	insert into #TMPObjectifBulletin values (	'2011-10-17'	,	42	,	1353.568	,	47349.870	)
	insert into #TMPObjectifBulletin values (	'2011-10-24'	,	43	,	1353.568	,	48703.439	)
	insert into #TMPObjectifBulletin values (	'2011-10-31'	,	44	,	1181.280	,	49884.718	)
	insert into #TMPObjectifBulletin values (	'2011-11-07'	,	45	,	1181.280	,	51065.998	)
	insert into #TMPObjectifBulletin values (	'2011-11-14'	,	46	,	1181.280	,	52247.278	)
	insert into #TMPObjectifBulletin values (	'2011-11-21'	,	47	,	1181.280	,	53428.557	)
	insert into #TMPObjectifBulletin values (	'2011-11-28'	,	48	,	1316.289	,	54744.846	)
	insert into #TMPObjectifBulletin values (	'2011-12-05'	,	49	,	1316.289	,	56061.134	)
	insert into #TMPObjectifBulletin values (	'2011-12-12'	,	50	,	1316.289	,	57377.423	)
	insert into #TMPObjectifBulletin values (	'2011-12-19'	,	51	,	1316.289	,	58693.711	)
	insert into #TMPObjectifBulletin values (	'2011-12-26'	,	52	,	1316.289	,	60010.000	)

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
	LEFT JOIN #TMPObjectifBulletin TMPObjectifBulletin on TMPObjectifBulletin.DebutSem = @StartDate

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