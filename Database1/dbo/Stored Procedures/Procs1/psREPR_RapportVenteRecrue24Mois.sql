/****************************************************************************************************
Copyrights (c) 2015 Gestion Universitas Inc.
Nom                 :	psREPR_RapportVenteRecrue24Mois
Description         :	Procédure stockée du rapport du RAPPORT SUIVI DES RECRUES DE 24 MOIS ET MOINS (glpi 13874)
Valeurs de retours  :	Dataset 
Note                :	2015-03-18			Donald Huppé	Création

exec psREPR_RapportVenteRecrue24Mois '2015-03-09','2015-03-15'
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportVenteRecrue24Mois] (
	@StartDate DATETIME,
	@EndDate DATETIME
	)
AS
BEGIN

	--set @StartDate = '2015-03-09'
	--set @EndDate = '2015-03-09'

DECLARE
	@DateCumulDu DATETIME
	,@Date24Mois datetime

	set @Date24Mois = dateadd(MONTH,-24,@EndDate)

	set @DateCumulDu = cast(year(@StartDate) as VARCHAR) + '-01-01'

	create table #TMPObjectifBulletin (
									DateFinPeriode varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)

	-- Objectifs pour chaque semaine de l'année
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (1,'2015-01-04',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (2,'2015-01-11',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (3,'2015-01-18',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (4,'2015-01-25',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (5,'2015-02-01',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (6,'2015-02-08',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (7,'2015-02-15',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (8,'2015-02-22',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (9,'2015-03-01',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (10,'2015-03-08',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (11,'2015-03-15',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (12,'2015-03-22',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (13,'2015-03-29',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (14,'2015-04-05',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (15,'2015-04-12',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (16,'2015-04-19',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (17,'2015-04-26',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (18,'2015-05-03',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (19,'2015-05-10',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (20,'2015-05-17',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (21,'2015-05-24',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (22,'2015-05-31',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (23,'2015-06-07',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (24,'2015-06-14',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (25,'2015-06-21',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (26,'2015-06-28',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (27,'2015-07-05',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (28,'2015-07-12',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (29,'2015-07-19',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (30,'2015-07-26',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (31,'2015-08-02',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (32,'2015-08-09',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (33,'2015-08-16',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (34,'2015-08-23',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (35,'2015-08-30',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (36,'2015-09-06',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (37,'2015-09-13',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (38,'2015-09-20',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (39,'2015-09-27',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (40,'2015-10-04',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (41,'2015-10-11',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (42,'2015-10-18',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (43,'2015-10-25',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (44,'2015-11-01',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (45,'2015-11-08',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (46,'2015-11-15',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (47,'2015-11-22',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (48,'2015-11-29',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (49,'2015-12-06',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (50,'2015-12-13',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (51,'2015-12-20',0,0)
	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul) values (52,'2015-12-27',0,0)

	create table #GrossANDNetUnitsCumul ( -- drop table #GrossANDNetUnits
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
	INSERT #GrossANDNetUnitsCumul -- drop table #GrossANDNetUnitsCumul
	EXEC SL_UN_RepGrossANDNetUnits NULL, @DateCumulDu, @EndDate, 0, 1

	create table #GrossANDNetUnitsSem ( -- drop table #GrossANDNetUnits
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
	INSERT #GrossANDNetUnitsSem -- drop table #GrossANDNetUnitsSem
	EXEC SL_UN_RepGrossANDNetUnits NULL, @StartDate, @EndDate, 0, 1

	SELECT 

		Recrue
		,v.RepCode
		,Agence = hb.FirstName + ' ' + hb.LastName
		,inscription =LEFT(CONVERT(VARCHAR,  r.BusinessStart, 120), 10)
		,QteUniteNettesSemaine = sum(QteUniteNettesSemaine)
		,QteUniteNettesCumul = sum(QteUniteNettesCumul)
		,Weekno = isnull(Weekno,0)
		--,ConsPct = round(cast(max(ConsPct) as MONEY),2)

	from (

			SELECT 
				Recrue = hr.FirstName + ' ' + hr.LastName
				,r.RepCode
				,gnu.RepID
				,QteUniteNettesSemaine = 0
				,QteUniteNettesCumul = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				--,ConsPct =	CASE
				--				WHEN SUM(Brut24) <= 0 THEN 0
				--				ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
				--			END

			FROM #GrossANDNetUnitsCumul gnu
			join un_rep r on gnu.RepID = r.RepID
			JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
			where 
				r.BusinessStart >= dateadd(MONTH,-24,@EndDate)
				and isnull(r.BusinessEnd,'9999-12-31') > @StartDate
			GROUP by 
				 hr.FirstName + ' ' + hr.LastName
				,r.RepCode
				,gnu.RepID

			union ALL

			SELECT 
				Recrue = hr.FirstName + ' ' + hr.LastName
				,r.RepCode
				,gnu.RepID
				,QteUniteNettesSemaine = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
				,QteUniteNettesCumul = 0
				--,ConsPct =	CASE
				--				WHEN SUM(Brut24) <= 0 THEN 0
				--				ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
				--			END

			FROM #GrossANDNetUnitsSem gnu
			join un_rep r on gnu.RepID = r.RepID
			JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
			where 
				r.BusinessStart >= @Date24Mois
				and isnull(r.BusinessEnd,'9999-12-31') > @StartDate
			GROUP by 
				 hr.FirstName + ' ' + hr.LastName
				,r.RepCode
				,gnu.RepID

			union ALL

			select 
				Recrue = hr.FirstName + ' ' + hr.LastName
				,r.RepCode
				,r.RepID
				,QteUniteNettesSemaine = 0
				,QteUniteNettesCumul = 0
				--,ConsPct = 0
			
			from un_rep r
			JOIN dbo.Mo_Human hr on r.RepID = hr.HumanID
			where 
				r.BusinessStart >= @Date24Mois
				and isnull(r.BusinessEnd,'9999-12-31') > @StartDate
		) v

	join un_rep r on v.RepID = r.RepID
	join (
		SELECT
			RB.RepID,
			BossID = MAX(BossID) -- au cas ou il y a 2 boss avec le même %.  alors on prend l'id le + haut. ex : repid = 497171
		FROM 
			Un_RepBossHist RB
			JOIN (
				SELECT
					RepID,
					RepBossPct = MAX(RepBossPct)
				FROM 
					Un_RepBossHist RB
				WHERE 
					RepRoleID = 'DIR'
					AND StartDate IS NOT NULL
					AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
					AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)) 
				GROUP BY
						RepID
				) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
			WHERE RB.RepRoleID = 'DIR'
				AND RB.StartDate IS NOT NULL
				AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10)
				AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, GETDATE(), 120), 10))
			GROUP BY
				RB.RepID

		)br on r.RepID = br.RepID
	JOIN dbo.Mo_Human hb on br.BossID = hb.HumanID
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
				ObjCumul = sum(ObjSemaine)
			from #TMPObjectifBulletin
			where DateFinPeriode <= @EndDate
			) V
		join #TMPObjectifBulletin OB ON V.DateFinPeriode = OB.DateFinPeriode
		) TMPObjectifBulletin ON TMPObjectifBulletin.DateFinPeriode = @EndDate

	group by 
		Recrue
		,v.RepCode
		,hb.FirstName + ' ' + hb.LastName
		,LEFT(CONVERT(VARCHAR,  r.BusinessStart, 120), 10)
		,isnull(Weekno,0)
	order by 
		sum(QteUniteNettesCumul) desc
	
end

