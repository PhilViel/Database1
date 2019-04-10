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
Nom                 :	psREPR_ObtenirVenteRecrue 
Description         :	Procédure stockée du rapport : SSRS - Rapport de ventes des Recrues
Valeurs de retours  :	Dataset 
Note                :	2009-02-20	Donald Huppé	    Création
						2013-11-14	Donald Huppé	    glpi 10514 : Attribution des reps aux nouveaux directeurs
						2014-02-20	Donald Huppé	    7916 Liette Pelletier et 7909 Alain Bossé ne sont pas des recrue
						2015-10-22	Donald Huppé	    glpi 15916 : ajout du paramètre @QteMoisRecrue
                        2018-11-08  Pierre-Luc Simard   Utilisation des regroupements de régimes
												
exec psREPR_ObtenirVenteRecrue '2015-01-01', '2015-10-22', 24

********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_ObtenirVenteRecrue] (
	@StartDate DATETIME,
	@EndDate DATETIME,
	@QteMoisRecrue INTEGER = 12
	) 
AS
BEGIN
	SELECT 1/0
	/*
	create table #GNU (
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

	insert into #GNU
	exec SL_UN_RepGrossANDNetUnits NULL, @StartDate,@EndDate, 0, 1, @QteMoisRecrue

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GNU g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- glpi 10514
	update #GNU set bossid = 440176 where bossid in ( 149464,149520) -- Associer les unités de Mario Béchard et Sylvain Bibeau(149520) à Maryse Breton
	update #GNU SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602)	
	update #GNU set BossID = 675096 where BossID = 149614 --Jeannot Turgeon (remplacer son nom par : Cabinet Turgeon & associés(675096))

	select 
		V.RepID,
		V.Recruit,
		V.RepCode,

		AgencyRepCode = case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 

		RepName = V.LastName + ' ' + V.FirstName,
		
		V.BusinessStart,
		RepIsActive = case when isnull(R.BusinessEnd,@EndDate) >= @EndDate then 1 else 0 end,
		ActualAgency = B.FirstName + ' ' + B.LastName,

		-- Si l'agence lors de la vente est Nd (non déterminé en date de InforceDate), alors on met l'agence actuelle,
		Agency = case when V.Agency = 'nd' then B.FirstName + ' ' + B.LastName else Agency end,
		AgencyLastname = B.LastName,
		Province,
		Region,

		Brut = SUM(Brut),
		Retraits = SUM(Retraits),
		Reinscriptions = SUM(Reinscriptions),

		Net = SUM(Net),
		NetInd = SUM(NetInd),
		NetUniv = SUM(NetUniv),
		NetRflex = SUM(NetRflex)

	--into TMPNew -- drop table TMPNew

	FROM (

		select 
			U.UnitID,
			GNU.RepID,
			Recruit = Recrue,
			RREP.RepCode,
			AgencyRepCode = ISNULL(BREP.RepCode,'nd'),
			HREP.LastName,
			HREP.FirstName,
			RREP.BusinessStart,
			Agency = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'nd'),
			Province = case when HBoss.LastName like '%Logelin%' then 'Nouveau-Brunswick / New-Brunswick' else 'Québec / Quebec' end,
			AdrS.Region,

			Brut,
			Retraits,
			Reinscriptions,
			Net = (Brut - Retraits + reinscriptions) ,
			NetInd = case when RR.vcCode_Regroupement = 'IND' then (Brut - Retraits + reinscriptions) else 0 END,
			NetUniv = case when RR.vcCode_Regroupement = 'UNI' then (Brut - Retraits + reinscriptions) else 0 END,
			NetRflex = case when RR.vcCode_Regroupement = 'REF' then (Brut - Retraits + reinscriptions) else 0 END

		from 
			#GNU GNU
			JOIN dbo.Un_Unit U on U.UnitID = GNU.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
            JOIN Un_Plan P ON P.PlanID = C.PlanID
            JOIN tblCONV_RegroupementsRegimes RR ON RR.iID_Regroupement_Regime = P.iID_Regroupement_Regime
			JOIN dbo.MO_HUMAN HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = GNU.RepID
			JOIN dbo.MO_HUMAN HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = GNU.BossID
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
		
	left JOIN ( -- #MaxPctBoss
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
	left JOIN dbo.Mo_Human B ON B.HumanID = M.BossID
	left JOIN Un_Rep RB ON RB.RepID = M.BossID
	left JOIN Un_Rep R on R.RepID = V.repID

	where V.Recruit = 1
	AND V.RepCode NOT IN ('7794','7823','7782','7916'/*Liette Pelletier*/,'7909'/*Alain Bossé*/) --Vénus Fréchette (Ghislain Thibeault), Kathleen Fauteux (Sophie Babeux), Isabelle Danis-Marineau (Michel Maheu).

	group by
	
		V.RepID,
		Recruit,
		V.RepCode,
		case when V.AgencyRepCode = 'nd' then RB.RepCode else V.AgencyRepCode end, 
		V.LastName + ' ' + V.FirstName,
		V.BusinessStart,
		case when isnull(R.BusinessEnd,@EndDate) >= @EndDate then 1 else 0 end,
		B.FirstName + ' ' + B.LastName,
		case when V.Agency = 'nd' then B.FirstName + ' ' + B.LastName else Agency end,
		B.LastName,
		Province,
		Region

	order by
	 	V.RepID, V.Region
		*/
END