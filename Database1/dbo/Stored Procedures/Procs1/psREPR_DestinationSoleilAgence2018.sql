/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DestinationSoleilAgence2018
Description         :	Rapport Destination Soleil pour les Agence 2018
Valeurs de retours  :	Dataset 
Note                :	2017-05-01	Donald Huppé	Création
						2017-05-17	Donald Huppé	Refonte
						2017-05-19	Donald Huppé	Faire les fusion d'agence
						2017-05-19	Donald Huppé	Objectif cotisation à 20 % pour tous
						2017-05-19	Donald Huppé	Ajout cotisation conv T
						2017-07-06	Donald Huppé	jira ti-7621 : Pour les cotisations, valider dtFirstDeposit au lieu de InForceDate
						2017-07-14	Donald Huppé	objectif de cotisation passe de 1.20 à 2.2045
						2018-09-07	Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU
exec psREPR_DestinationSoleilAgence2018 '2017-01-01', '2017-04-30' , '2016-01-01',  '2016-05-01', 16

*********************************************************************************************************************/


CREATE procedure [dbo].[psREPR_DestinationSoleilAgence2018] 
	(
	@DateDu DATETIME, -- Date de début
	@DateAu DATETIME, -- Date de fin
	@DateDuPrec DATETIME, -- Date de début
	@DateAuPrec DATETIME, -- Date de fin
	@NbSemaine int
	) 

as
BEGIN
	/*
		set @DateDu  = '2015-01-01'
		set @DateAu  = '2015-02-01'
		set @DateDuPrec  = '2014-01-01'
		set @DateAuPrec  = '2014-02-02'
		set @NbSemaine  = 5
	*/

	--declare @DateDebutAnneePrec datetime = '2016-01-01' -- cast(year(@DateDuPrec) as varchar) + '-01-01' --6 octobre 2014 au 4 octobre 2015 
	--declare @DateFinAnneePrec datetime = '2016-12-31'--cast(year(@DateDuPrec) as varchar) + '-09-28'


	 
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



	select 
		RepIDRevenu = rrevenu.RepID
	into #RepPartiRevenu -- donc ne sont pas des recrue
	from un_rep rrevenu
	where rrevenu.RepCode in (
				/*Siège	Social*/ '6141'
				/*André Larocque*/ ,'70135'
				 /*Ghislain Thibeault*/ ,'70098'
				 /*Manon Derome*/ ,'70174'
				 /*Chantale Ouellet*/ ,'70190'
				 /*Vincent Matte*/ ,'70207'
		)


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
			AND (StartDate <= @DateAu)
			AND (EndDate IS NULL OR EndDate >= @DateAu)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @DateAu)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @DateAu)
	GROUP BY
		RB.RepID	
 	
	-- changer le directeur actuel du rep pour les rep du NB :glpi 14752
	--update BR set BR.BossID = LA.BossID
	--from #BossRepActuel BR
	--join tblREPR_LienAgenceRepresentantConcours LA ON BR.RepID = LA.RepID
	--where LA.BossID = 671417

	----L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	--update #BossRepActuel set BossID = 436381 where BossID = 436873 
	---- Agence Maryse Breton est fusionnée à Clément Blais
	--update #BossRepActuel set BossID = 149489 where BossID = 440176 

	CREATE TABLE #UniteConvT (
		UnitID INT PRIMARY KEY, 
		RepID INT, 
		BossID INT,
		dtFirstDeposit DATETIME )

	INSERT INTO #UniteConvT
	SELECT * FROM fntREPR_ObtenirUniteConvT(1)


	create table #GrossANDNetUnitsPrec (
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

	-- Les données des Rep
	INSERT #GrossANDNetUnitsPrec -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDuPrec, @DateAuPrec, 0, 1

	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #GrossANDNetUnitsPrec set BossID = 671417 where BossID = 655109 

	---- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsPrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- Pour les totaux par agence, 
	update #GrossANDNetUnitsPrec SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnitsPrec SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602) 
	update #GrossANDNetUnitsPrec SET bossid = 149489 where bossid = 440176 --Fusionner pour toute les sections de qualifications les agences de Clément Blais et de Maryse Breton;
	update #GrossANDNetUnitsPrec SET bossid = 436381 where bossid = 436873 --Fusionner pour toute les sections de qualifications les agences de Sophie Babeux et de Nataly Desormeaux;


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

	-- Les données des Rep
	INSERT INTO #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDu, @DateAu, 0, 1


	-- Agence Nouveau-Brunswick remplace Anne LeBlanc-Levesque
	update #GrossANDNetUnits set BossID = 671417 where BossID = 655109 

	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	-- Pour les totaux par agence, 
	update #GrossANDNetUnits SET bossid = 440176 where bossid in ( 149464,149520) --Additionner (ou soustraire) les unités de Mario Béchard (149464) et Sylvain Bibeau(149520) à l’équipe de Maryse Breton (440176) 
	update #GrossANDNetUnits SET bossid = 149602 where bossid = 415878 --Additionner (ou soustraire) les unités de Dolorès(415878) à l’équipe de D Turpin(149602) 
	update #GrossANDNetUnits SET bossid = 149489 where bossid = 440176 --Fusionner pour toute les sections de qualifications les agences de Clément Blais et de Maryse Breton;
	update #GrossANDNetUnits SET bossid = 436381 where bossid = 436873 --Fusionner pour toute les sections de qualifications les agences de Sophie Babeux et de Nataly Desormeaux;



	---- glpi 10514
	--update g SET g.BossID = LA.BossID
	--from #GrossANDNetUnitsAnneePrecFull g
	--JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	--join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	--where u.dtFirstDeposit >= '2011-01-01'

	----L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	--update #GrossANDNetUnitsAnneePrecFull set BossID = 436381 where BossID = 436873 

	select 

		Agence =  ltrim(rtrim(replace(v.Agence,'Agence','')))
		,v.BossID
		--,QteUniteNettesAnneePrec = VentePrec.NetPrec
		,v.QteUniteNettesPrec
		,ObjectifUniteNette = OUN.Objectif * v.QteUniteNettesPrec
		,v.QteUniteNettes
		,TauxCroissanceUnite = case when (OUN.Objectif * v.QteUniteNettesPrec) = 0 then 0 else v.QteUniteNettes / (OUN.Objectif * v.QteUniteNettesPrec) end
		--,UniteAProduire = (OUN.Objectif * QteUniteNettesPrec) - QteUniteNettes

		,Cotis_PeriodePrec
		,ObjectifCotis = 2.2045 * Cotis_PeriodePrec
		,Cotis_Periode = case when Cotis_Periode <0 then 0 else Cotis_Periode end
		,TauxCroissanceCotis = case when (2.2045 * Cotis_PeriodePrec) = 0 then 0 else Cotis_Periode / (2.2045 * Cotis_PeriodePrec) end
		--,AR.TauxRecrueQualifiée

	from (

		select 
			Agence = hb.FirstName + ' ' + hb.LastName
			,BossID	

			--,QteUniteNettesAnneePrec = SUM(QteUniteNettesAnneePrec)
			,QteUniteNettesPrec = SUM(QteUniteNettesPrec)

			,QteUniteNettes = SUM(QteUniteNettes)
			--,QteUniteNettesRecrue = sum(QteUniteNettesRecrue)
			,ConsPct = round(MAX(ConsPct),2)
			,QualifNonRecrue = isnull(
									case 
									WHEN SUM(QteUniteNettes)>= 600 and round(SUM(ConsPct),2) >= 85 then 1
									when SUM(QteUniteNettes) >= @NbSemaine * 15 /*15.385*/  and round(SUM(ConsPct),2) >= 85 then 2
									end
								,999)
			,QualifRecrue = isnull(	
								case 
								WHEN SUM(QteUniteNettes)>= 300  and round(SUM(ConsPct),2) >= 95  then 1
								end
								,999)
			,Croissance =  SUM(QteUniteNettes) - SUM(QteUniteNettesPrec)
			,Cotis_Periode = sum(Cotis_Periode)
			,Cotis_PeriodePrec = sum(Cotis_PeriodePrec)
		from 
			(

			SELECT 
				gnuP.BossID
				--,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
				,Cotis_PeriodePrec = 0
			FROM #GrossANDNetUnitsPrec gnuP
			GROUP by 
				gnuP.BossID

			UNION ALL

			SELECT 
				gnu.BossID
				--,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				--,QteUniteNettesRecrue = 0
				,ConsPct =	CASE
								WHEN SUM(Brut24) <= 0 THEN 0
								ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
							END
				,Cotis_Periode = 0
				,Cotis_PeriodePrec = 0
			FROM #GrossANDNetUnits gnu
			GROUP by 
				gnu.BossID

			UNION ALL

			SELECT 
				gnu.BossID
			--	,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,ConsPct = 0
				,Cotis_Periode = 0
				,Cotis_PeriodePrec = 0
			FROM #GrossANDNetUnits gnu
			LEFT JOIN #RepPartiRevenu PR on PR.RepIDRevenu = gnu.RepID
			where 
				gnu.Recrue = 1
				and PR.RepIDRevenu is null
			GROUP by 
				gnu.BossID

			UNION ALL

	
			select 
				BossID =	CASE
								WHEN isnull(la.BossID,bu.BossID) = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
								WHEN isnull(la.BossID,bu.BossID) = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
								ELSE isnull(la.BossID,bu.BossID) -- s'il y a un boss de remplacement, on le prend
							END
			--	,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
				,Cotis_PeriodePrec = 0
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				join un_cotisation ct on ct.UnitID = u.UnitID
				join un_oper o on ct.OperID = o.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
				left join tblREPR_LienAgenceRepresentantConcours LA on LA.RepID = u.RepID
				left join (
					SELECT 
						M.UnitID,
						BossID = MAX(RBH.BossID)
					FROM (
						SELECT 
							U.UnitID,
							U.RepID,
							RepBossPct = MAX(RBH.RepBossPct)
						FROM dbo.Un_Unit U
						JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
						JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
						JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
						GROUP BY U.UnitID, U.RepID
						) M
					JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
					JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
					GROUP BY 
						M.UnitID
						)bu on bu.UnitID = u.UnitID
			where 
				/*u.InForceDate*/ u.dtFirstDeposit BETWEEN @DateDu and @DateAu
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDu and @DateAu
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				CASE
					WHEN isnull(la.BossID,bu.BossID) = 436873 THEN 436381  
					WHEN isnull(la.BossID,bu.BossID) = 440176 THEN 149489
					ELSE isnull(la.BossID,bu.BossID) -- s'il y a un boss de remplacement, on le prend
				END


			UNION ALL

			-- conv T
			select 
				BossID =	CASE
								WHEN T.BossID = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
								WHEN T.BossID = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
								ELSE T.BossID -- s'il y a un boss de remplacement, on le prend
							END
			--	,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
				,Cotis_PeriodePrec = 0
			--into #Cotis
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				join #UniteConvT T on u.UnitID = T.UnitID
				join un_cotisation ct on ct.UnitID = u.UnitID
				join un_oper o on ct.OperID = o.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			where 1=1
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDu and @DateAu
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				CASE
					WHEN T.BossID = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
					WHEN T.BossID = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
					ELSE T.BossID -- s'il y a un boss de remplacement, on le prend
				END


			UNION ALL

			-- conv T
			select 
				BossID =	CASE
								WHEN T.BossID = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
								WHEN T.BossID = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
								ELSE T.BossID -- s'il y a un boss de remplacement, on le prend
							END
			--	,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
				,Cotis_PeriodePrec = sum(ct.Cotisation + ct.Fee)
			--into #Cotis
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				join #UniteConvT T on u.UnitID = T.UnitID
				join un_cotisation ct on ct.UnitID = u.UnitID
				join un_oper o on ct.OperID = o.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
			where 1=1
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDuPrec and @DateAuPrec
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				CASE
					WHEN T.BossID = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
					WHEN T.BossID = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
					ELSE T.BossID -- s'il y a un boss de remplacement, on le prend
				END

			UNION ALL

	
			select 
				BossID =	CASE
								WHEN isnull(la.BossID,bu.BossID) = 436873 THEN 436381   --L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
								WHEN isnull(la.BossID,bu.BossID) = 440176 THEN 149489 -- Agence Maryse Breton est fusionnée à Clément Blais
								ELSE isnull(la.BossID,bu.BossID) -- s'il y a un boss de remplacement, on le prend
							END
			--	,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				--,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
				,Cotis_PeriodePrec = sum(ct.Cotisation + ct.Fee)
			from 
				Un_Convention c
				JOIN dbo.Un_Unit u on c.ConventionID = u.ConventionID
				join un_cotisation ct on ct.UnitID = u.UnitID
				join un_oper o on ct.OperID = o.OperID
				left join Un_Tio TIOt on TIOt.iTINOperID = o.operid
				left join Un_Tio TIOo on TIOo.iOUTOperID = o.operid
				left join tblREPR_LienAgenceRepresentantConcours LA on LA.RepID = u.RepID
				left join (
					SELECT 
						M.UnitID,
						BossID = MAX(RBH.BossID)
					FROM (
						SELECT 
							U.UnitID,
							U.RepID,
							RepBossPct = MAX(RBH.RepBossPct)
						FROM dbo.Un_Unit U
						JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
						JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
						JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
						GROUP BY U.UnitID, U.RepID
						) M
					JOIN dbo.Un_Unit U ON U.UnitID = M.UnitID
					JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
					GROUP BY 
						M.UnitID
						)bu on bu.UnitID = u.UnitID
			where 
				/*u.InForceDate*/ u.dtFirstDeposit BETWEEN @DateDuPrec and @DateAuPrec
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDuPrec and @DateAuPrec
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET','COU')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				CASE
					WHEN isnull(la.BossID,bu.BossID) = 436873 THEN 436381  
					WHEN isnull(la.BossID,bu.BossID) = 440176 THEN 149489
					ELSE isnull(la.BossID,bu.BossID) -- s'il y a un boss de remplacement, on le prend
				END

			) V

		JOIN dbo.Mo_Human hb on v.BossID = hb.HumanID

		GROUP BY
			hb.FirstName + ' ' + hb.LastName
			,BossID

		) v
	join #ObjectifUniteNette OUN on OUN.RepID = v.BossID

	order by QteUniteNettes desc


END