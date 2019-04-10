/****************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_DestinationSoleilAgence2016
Description         :	Rapport Destination Soleil pour les Agence 2016
Valeurs de retours  :	Dataset 
Note                :	2015-02-25	Donald Huppé	Création (glpi 13670)
						2015-06-05	Donald Huppé	glpi 14752	 : Josée demande de mettre 15 unité par semaine au lieu de 15.385 + gestion du NB

J’aurais besoin des données pour la période suivante :

Pour 2015 c’est du 01/01/2015 au 01/03/2015
Pour 2014 c’est du 01/01/2014 au 02/03/2014

Merci beaucoup!

02/02/2015 au 01/03/2015
03/02/2014 au 02/03/2014

*********************************************************************************************************************/
-- drop proc psREPR_DestinationSoleilAgence2016
--  exec psREPR_DestinationSoleilAgence2016 '2015-01-01', '2015-05-31' , '2014-01-01',  '2014-06-01', 22

CREATE procedure [dbo].[psREPR_DestinationSoleilAgence2016] 
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

	declare @DateDebutAnneePrec datetime = cast(year(@DateDuPrec) as varchar) + '-01-01'
	declare @DateFinAnneePrec datetime = cast(year(@DateDuPrec) as varchar) + '-09-28'

	--select @DateFinAnneePrec
	 
	create table #Vente2014 (RepID int, Net2014 float, Objectif float) -- drop table #Vente2014

	insert into #Vente2014 values (436381,/*Sophie Babeux*/ 6782.504 , 6782.504)
	insert into #Vente2014 values (149489,/*Clément Blais*/  8849.248,	8849.248)
	insert into #Vente2014 values (440176,/*Maryse Breton*/ 3517.786,	3588.142 )
	insert into #Vente2014 values (436873,/*Nataly Désormeaux*/  1841.051,	1933.104 )
	insert into #Vente2014 values (671417,/*NB*/				872.346,	915.963) -- NB
	insert into #Vente2014 values (149521,/*Michel Maheu*/  7132.759,	7132.759 )
	insert into #Vente2014 values (149593,/*Martin Mercier*/  6207.03,	6207.03 )
	insert into #Vente2014 values (149469,/*Roberto Perron*/ 3516.953,	3587.292 )
	insert into #Vente2014 values (149602,/*Daniel Turpin*/  6326.437,	6326.437 )

	--select * from #Vente2014

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

	select 

		Agence =  ltrim(rtrim(replace(Agence,'Agence','')))
		,BossID
		,QteUniteNettesAnneePrec = v2014.Net2014
		,QteUniteNettesPrec
		,QteUniteNettes
		,v2014.Objectif
		,UniteAProduire = v2014.Objectif - QteUniteNettes
		,TauxCroissance = case when QteUniteNettesPrec = 0 then 0 else (QteUniteNettes / QteUniteNettesPrec) end
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
			where gnu.Recrue = 1
			GROUP by 
				gnu.BossID

			UNION ALL

			select 
				BossID = isnull(la.BossID,bu.BossID) -- s'il y a un boss de remplacement, on le prend
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
				u.SignatureDate BETWEEN @DateDu and @DateAu
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------
				and o.OperDate BETWEEN @DateDu and @DateAu
				and o.OperTypeID in ( 'CHQ','PRD','NSF','CPA','RDI','TIN','OUT','RES','RET')
				and tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				and tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				isnull(la.BossID,bu.BossID)  --bu.BossID

			) V

		JOIN dbo.Mo_Human hb on v.BossID = hb.HumanID

		GROUP BY
			hb.FirstName + ' ' + hb.LastName
			,BossID

		) v
	join #Vente2014 v2014 on v.BossID = v2014.RepID
	order by QteUniteNettes desc

end
	--select * from un_rep where RepID = 629154


