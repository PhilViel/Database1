/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DestinationSoleilAgence2017
Description         :	Rapport Destination Soleil pour les Agence 2017
Valeurs de retours  :	Dataset 
Note                :	2015-02-25	Donald Huppé	Création (glpi 13670)
						2015-06-05	Donald Huppé	glpi 14752	 : Josée demande de mettre 15 unité par semaine au lieu de 15.385 + gestion du NB
						2015-11-30	Donald Huppé	GLPI 16229 (S Robinson) : Pour Cotis_Periode, filtrer sur inforceDate au lieu de signatureDate
						2016-08-25	Donald Huppé	jira ti-3835 : gestion des Rep Parti et Revenu qui ne sont pas des recrues
						2016-09-06	Donald Huppé	jira ti-4547

exec psREPR_DestinationSoleilAgence2017 '2015-10-05', '2016-08-28' , '2014-10-06',  '2015-08-30', 47

*********************************************************************************************************************/


CREATE procedure [dbo].[psREPR_DestinationSoleilAgence2017] 
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

	declare @DateDebutAnneePrec datetime = '2014-10-06' -- cast(year(@DateDuPrec) as varchar) + '-01-01' --6 octobre 2014 au 4 octobre 2015 
	declare @DateFinAnneePrec datetime = '2015-10-04'--cast(year(@DateDuPrec) as varchar) + '-09-28'

	--select @DateFinAnneePrec
	 
	create table #VentePrec (RepID int, NetPrec float, Objectif float) -- drop table #VentePrec

	insert into #VentePrec values (436381,/*Sophie Babeux*/ 12957 , 13346)
	insert into #VentePrec values (149489,/*Clément Blais*/  16566,	17431)
	--insert into #VentePrec values (440176,/*Maryse Breton*/ 5248,	5773 )-- est intégré à Clément Blais
	--insert into #VentePrec values (436873,/*Nataly Désormeaux*/  1841.051,	1933.104 ) -- est intégré à Sophie Babeux
	insert into #VentePrec values (671417,/*NB*/				1132,	1245) -- NB
	insert into #VentePrec values (149521,/*Michel Maheu*/  11111,	11444 )
	insert into #VentePrec values (149593,/*Martin Mercier*/  9145,	9602 )
	insert into #VentePrec values (149469,/*Roberto Perron*/ 5662,	6228 )
	insert into #VentePrec values (149602,/*Daniel Turpin*/  9536,	10013 )

	--select * from #VentePrec

	select 
		RepIDRevenu = rrevenu.RepID
	into #RepPartiRevenu -- donc ne sont pas des recrue
	from un_rep rrevenu
	where rrevenu.RepCode in (
		70085,
		70115,
		70135,
		70098,
		70190
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
	update BR set BR.BossID = LA.BossID
	from #BossRepActuel BR
	join tblREPR_LienAgenceRepresentantConcours LA ON BR.RepID = LA.RepID
	where LA.BossID = 671417

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #BossRepActuel set BossID = 436381 where BossID = 436873 
	-- Agence Maryse Breton est fusionnée à Clément Blais
	update #BossRepActuel set BossID = 149489 where BossID = 440176 

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

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsPrec g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #GrossANDNetUnitsPrec set BossID = 436381 where BossID = 436873 
	-- Agence Maryse Breton est fusionnée à Clément Blais
	update #GrossANDNetUnitsPrec set BossID = 149489 where BossID = 440176 

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
	INSERT #GrossANDNetUnits -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDu, @DateAu, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnits g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #GrossANDNetUnits set BossID = 436381 where BossID = 436873 

	-- Agence Maryse Breton est fusionnée à Clément Blais
	update #GrossANDNetUnits set BossID = 149489 where BossID = 440176 

	create table #GrossANDNetUnitsAnneePrecFull (
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
	INSERT #GrossANDNetUnitsAnneePrecFull -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateDebutAnneePrec, @DateFinAnneePrec, 0, 1

	-- glpi 10514
	update g SET g.BossID = LA.BossID
	from #GrossANDNetUnitsAnneePrecFull g
	JOIN dbo.Un_Unit u ON g.UnitID = u.UnitID
	join tblREPR_LienAgenceRepresentantConcours LA ON g.RepID = LA.RepID
	where u.dtFirstDeposit >= '2011-01-01'

	--L’AGENCE NATALY DÉSORMEAUX DOIVENT ÊTRE FUSIONNÉES À CELLES DE L’AGENCE SOPHIE BABEUX
	update #GrossANDNetUnitsAnneePrecFull set BossID = 436381 where BossID = 436873 

	select 

		Agence =  ltrim(rtrim(replace(Agence,'Agence','')))
		,BossID
		,QteUniteNettesAnneePrec = VentePrec.NetPrec
		,QteUniteNettesPrec
		,QteUniteNettes
		,VentePrec.Objectif
		,UniteAProduire = VentePrec.Objectif - QteUniteNettes
		,TauxCroissance = case when VentePrec.Objectif = 0 then 0 else (VentePrec.Objectif - QteUniteNettes) / VentePrec.Objectif end
		,QteUniteNettesRecrue
		--,ConsPct
		--,QualifNonRecrue
		--,QualifRecrue
		--,Croissance
		,Cotis_Periode = case when Cotis_Periode <0 then 0 else Cotis_Periode end

	from (

		select 
			Agence = hb.FirstName + ' ' + hb.LastName
			,BossID	

			,QteUniteNettesAnneePrec = SUM(QteUniteNettesAnneePrec)
			,QteUniteNettesPrec = SUM(QteUniteNettesPrec)

			,QteUniteNettes = SUM(QteUniteNettes)
			,QteUniteNettesRecrue = sum(QteUniteNettesRecrue)
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
		from 
			(

			SELECT 
				gnuF.BossID
				,QteUniteNettesAnneePrec = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
			FROM #GrossANDNetUnitsAnneePrecFull gnuF
			GROUP by 
				gnuF.BossID

			UNION ALL

			SELECT 
				gnuP.BossID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = 0
			FROM #GrossANDNetUnitsPrec gnuP
			GROUP by 
				gnuP.BossID

			UNION ALL

			SELECT 
				gnu.BossID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettesRecrue = 0
				,ConsPct =	CASE
								WHEN SUM(Brut24) <= 0 THEN 0
								ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
							END
				,Cotis_Periode = 0
			FROM #GrossANDNetUnits gnu
			GROUP by 
				gnu.BossID

			UNION ALL

			SELECT 
				gnu.BossID
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,ConsPct = 0
				,Cotis_Periode = 0
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
				,QteUniteNettesAnneePrec = 0
				,QteUniteNettesPrec = 0
				,QteUniteNettes = 0
				,QteUniteNettesRecrue = 0
				,ConsPct = 0
				,Cotis_Periode = sum(ct.Cotisation + ct.Fee)
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
				u.InForceDate BETWEEN @DateDu and @DateAu
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDu and @DateAu
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET')
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
	join #VentePrec VentePrec on v.BossID = VentePrec.RepID
	order by QteUniteNettes desc

end
	--select * from un_rep where RepID = 629154


