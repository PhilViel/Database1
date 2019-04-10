
/**************************************************************************************
Copyrights (c) 2010 Gestion Universitas inc.

Code du service : psREPR_RapportSuiviRecrueParSemaine
Nom du service  : Rapport de suivi des ventes des recrues de 24 mois
But             : Alimentente le rapport du même nom, afin de faire un suivi des ventes des recrues
Facette         : REPR

Paramètres d’entrée : Paramètre                  Description
                      -------------------------- -----------------------------------
                      @EnDateDu					 Date du dimanche de la fin de la période à analyser à partir du début de l'année

Paramètres de sortie: Paramètre   Champ(s)               Description
                      ----------- ---------------------- ---------------------------


Exemple d’appel     : 


EXECUTE psREPR_RapportSuiviRecrueParSemaine @EnDateDu = '2017-01-22', @RepCode = NULL, @QteMoisRecrue = 24

EXECUTE psREPR_RapportSuiviRecrueParSemaine @EnDateDu = '2016-12-25', @RepCode = NULL, @QteMoisRecrue = 36
EXECUTE psREPR_RapportSuiviRecrueParSemaine @EnDateDu = '2017-02-12', @RepCode = NULL, @QteMoisRecrue = 36
EXECUTE psREPR_RapportSuiviRecrueParSemaine @EnDateDu = '2017-01-22', @RepCode = NULL, @QteMoisRecrue = 24

Historique des modifications:
        Date            Programmeur                         Description
        ------------    ----------------------------------	---------------------------
        2016-06-02      Donald Huppé						Création du service (jira ti-3146)
		2016-06-15		Donald Huppé						Ajustement calcul semaine début rep
		2016-06-16		Donald Huppé						Exclure des reps.
        2016-07-13      Pierre-Luc Simard                   Réintégrer Anne Jetté, RepCode 70151
		2016-09-08		Donald Huppé						Exclure les rep de l'Agence Siège Social. Ce sont des employés
		2016-11-30		Donald Huppé						Clarifier paramètre d'appel de SL_UN_RepGrossANDNetUnits
		2016-12-21		Donald Huppé						jira ti-6127 : d'option pour rep 36 mois 
		2017-01-25		Donald Huppé						Ajustement suite au jira ti-6127 : les 36 mois incluent les 24 mois, 
															exclure 70193
															Prendre les vente pour le cumul des 3 année complete précédente car peut être les 36 mois
		2018-02-26		Donald Huppé						Jira ti-11726 : Gestion des semaines de 2018
		drop proc psREPR_RapportSuiviRecrueParSemaine
**************************************************************************************/


CREATE procedure [dbo].[psREPR_RapportSuiviRecrueParSemaine] 
	(
	@EnDateDu DATETIME -- Date de début
	,@RepCode VARCHAR(15) = NULL
	,@QteMoisRecrue INT = 24
	) 

as
BEGIN


	DECLARE @startDateSunDay DATETIME
	DECLARE @endDateSunDay DATETIME

	DECLARE @DateDebutAnnee DATETIME
	--DECLARE @DateFinAnneePrec DATETIME
	--DECLARE @DateFin2AnneePrec DATETIME

	DECLARE @DateDu_AnPrec1 DATETIME
	DECLARE @DateAu_AnPrec1 DATETIME

	DECLARE @DateDu_AnPrec2 DATETIME
	DECLARE @DateAu_AnPrec2 DATETIME

	DECLARE @DateDu_AnPrec3 DATETIME
	DECLARE @DateAu_AnPrec3 DATETIME


	set @DateDebutAnnee = cast(year(@EnDateDu) as varchar(4)) + '-01-01'
	--set @DateFinAnneePrec = dateadd(DAY,-1,@DateDebutAnnee)
	--set @DateFin2AnneePrec = DATEADD(YEAR,-2,@DateFinAnneePrec)

	set @DateDu_AnPrec1 = DATEADD(YEAR,-1,@DateDebutAnnee)
	set @DateAu_AnPrec1 = DATEADD(DAY,-1,@DateDebutAnnee)

	set @DateDu_AnPrec2 = DATEADD(YEAR,-1,@DateDu_AnPrec1)
	set @DateAu_AnPrec2 = DATEADD(YEAR,-1,@DateAu_AnPrec1)

	set @DateDu_AnPrec3 = DATEADD(YEAR,-2,@DateDu_AnPrec1)
	set @DateAu_AnPrec3 = DATEADD(YEAR,-2,@DateAu_AnPrec1)


	--select @DateDu_AnPrec1
	--select @DateAu_AnPrec1

	--select @DateDu_AnPrec2
	--select @DateAu_AnPrec2

	--select @DateDu_AnPrec3
	--select @DateAu_AnPrec3

	--select @DateDebutAnnee
	--select @DateFinAnneePrec
	--select @DateFin2AnneePrec 



	-- Les mêmes no de semaine que dans le bulletin
	IF YEAR(@EnDateDu) = 2016
	BEGIN
		SET @startDateSunDay = '2016-01-10' -- 1er dimanche
		SET @endDateSunDay = '2016-12-25' -- dernier dimanche
	END


	IF YEAR(@EnDateDu) = 2017
	BEGIN
		SET @startDateSunDay = '2017-01-08' -- 1er dimanche
		SET @endDateSunDay = '2017-12-31' -- dernier dimanche
	END

	IF YEAR(@EnDateDu) = 2018
	BEGIN
		SET @startDateSunDay = '2018-01-07' -- 1er dimanche
		SET @endDateSunDay = '2018-12-30' -- dernier dimanche
	END;


	WITH dates(Date) AS 
	(
		SELECT @startDateSunDay as Date
		UNION ALL
		SELECT DATEADD(d,7,[Date])
		FROM dates 
		WHERE DATE < @endDateSunDay
	)


	SELECT 
		Semaine = DENSE_RANK() OVER (
									partition by null -- #2 : basé sur rien
									ORDER BY Date -- #1 : on numérote les Date
									)
		,DuLundi = cast(dateadd(DAY,-6, Date) as date)
		,AuDimanche = cast(Date  as date)
	into #Semaine -- drop table #Semaine
	FROM dates
	OPTION (MAXRECURSION 0)

	--select * from #Semaine


	create table #GrossANDNetUnitsAnneePrec1 (
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
		Reinscriptions24 FLOAT
		,DateUnite DATETIME) 

	create table #GrossANDNetUnitsAnneePrec2 (
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
		Reinscriptions24 FLOAT
		,DateUnite DATETIME) 


	create table #GrossANDNetUnitsAnneePrec3 (
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
		Reinscriptions24 FLOAT
		,DateUnite DATETIME) 

	--create table #GrossANDNetUnitsDebut (
	--	UnitID_Ori INTEGER,
	--	UnitID INTEGER,
	--	RepID INTEGER,
	--	Recrue INTEGER,
	--	BossID INTEGER,
	--	RepTreatmentID INTEGER,
	--	RepTreatmentDate DATETIME,
	--	Brut FLOAT,
	--	Retraits FLOAT,
	--	Reinscriptions FLOAT,
	--	Brut24 FLOAT,
	--	Retraits24 FLOAT,
	--	Reinscriptions24 FLOAT
	--	,DateUnite DATETIME) 

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
		Reinscriptions24 FLOAT
		,DateUnite DATETIME) 


	-- vente annéée prec 1
	INSERT #GrossANDNetUnitsAnneePrec1 -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite
		@ReptreatmentID = NULL,
		@StartDate = @DateDu_AnPrec1, -- Date de début
		@EndDate = @DateAu_AnPrec1, -- Date de fin
		@RepID = 0,
		@ByUnit = 1 

	-- vente annéée prec 2
	INSERT #GrossANDNetUnitsAnneePrec2 -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite
		@ReptreatmentID = NULL,--@ReptreatmentID, -- ID du traitement de commissions
		@StartDate = @DateDu_AnPrec2, -- Date de début
		@EndDate = @DateAu_AnPrec2, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	-- vente annéée prec 3
	INSERT #GrossANDNetUnitsAnneePrec3 -- drop table #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite 
		@ReptreatmentID = NULL,--@ReptreatmentID, -- ID du traitement de commissions
		@StartDate = @DateDu_AnPrec3, -- Date de début
		@EndDate = @DateAu_AnPrec3, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 

	---- Les données des Rep
	--INSERT #GrossANDNetUnitsDebut -- drop table #GrossANDNetUnits
	--EXEC SL_UN_RepGrossANDNetUnits_DateUnite 
	--	@ReptreatmentID = NULL,--@ReptreatmentID, -- ID du traitement de commissions
	--	@StartDate = @DateFin2AnneePrec, -- Date de début
	--	@EndDate = @DateFinAnneePrec, -- Date de fin
	--	@RepID = 0, --@RepID, -- ID du représentant
	--	@ByUnit = 1 

	-- Les données des Rep
	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite --NULL, @DateDebutAnnee, @EnDateDu, 0, 1
		@ReptreatmentID = NULL,--@ReptreatmentID, -- ID du traitement de commissions
		@StartDate = @DateDebutAnnee, -- Date de début
		@EndDate = @EnDateDu, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 
	select 
		v.RepID
		,v.Semaine
		,s.DuLundi
		,s.AuDimanche
		,SemaineDebutRep = Floor(datediff(DAY,r.BusinessStart, s.AuDimanche)/7.0 ) + 1
		,QteUnitéNettes  =sum(QteUnitéNettes)
	into #VenteParSemaine
	from (
		select 
			r.RepID
			,S.Semaine
			,QteUnitéNettes = 0
		from #Semaine s
		join un_rep r on 1=1
		where 
			r.BusinessStart >= dateadd(YEAR,-3,@EnDateDu)
			or dateadd(YEAR,3,r.BusinessStart) BETWEEN @DateDebutAnnee and @EnDateDu

		union all

		-- Total par semaine cette année
		SELECT 
			gnu.RepID
			,S.Semaine
			,QteUnitéNettes = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		from #GrossANDNetUnits gnu
		join #Semaine s on gnu.DateUnite BETWEEN s.DuLundi and s.AuDimanche
		join Un_Rep r on r.RepID = gnu.RepID
		where 
			r.BusinessStart >= dateadd(YEAR,-3,@EnDateDu)
			or dateadd(YEAR,3,r.BusinessStart) BETWEEN @DateDebutAnnee and @EnDateDu
		GROUP by 
			gnu.RepID
			,S.Semaine
		)v
		join #Semaine s on s.Semaine = v.Semaine
		join Un_Rep r on r.RepID = v.RepID
	GROUP BY
		v.RepID
		,v.Semaine
		,r.BusinessStart,s.DuLundi, s.AuDimanche
	order by v.RepID,v.Semaine

	-- Toutes les ventes des rep des 3 année précédentes complète : 
	-- Normalement, comme ça, on rammasse toute les ventes des rep de 36 mois
	select 
		RepID
		,SoldeNetDebut = sum(SoldeNetDebut)
	into #SoldeNetDebut -- drop table #SoldeNetDebut
	from (
	
		SELECT 
			gnu1.RepID
			,SoldeNetDebut = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		from #GrossANDNetUnitsAnneePrec1 gnu1
		where 
			gnu1.RepID in (select repid from #VenteParSemaine )
		GROUP by gnu1.RepID

		UNION ALL

		SELECT 
			gnu2.RepID
			,SoldeNetDebut = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		from #GrossANDNetUnitsAnneePrec2 gnu2
		where 
			gnu2.RepID in (select repid from #VenteParSemaine )
		GROUP by gnu2.RepID

		UNION ALL

		SELECT 
			gnu3.RepID
			,SoldeNetDebut = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		from #GrossANDNetUnitsAnneePrec3 gnu3
		where 
			gnu3.RepID in (select repid from #VenteParSemaine )
		GROUP by gnu3.RepID
	) v
	GROUP by RepID

	select 
		vs.RepID
		,Representant = hr.FirstName + ' ' + hr.LastName
		,Agence = hb.FirstName + ' ' + hb.LastName
		,r.RepCode
		,r.BusinessStart
		,vs.Semaine
		,vs.DuLundi
		,vs.AuDimanche
		,vs.SemaineDebutRep
		,vs.QteUnitéNettes 
		,Cumul = isnull(sd.SoldeNetDebut,0) + sum(vs2.QteUnitéNettes)
		,DateFinQteMois =	DATEADD(MONTH,@QteMoisRecrue,r.BusinessStart)
						/*
							CASE 
								WHEN DATEDIFF(DAY,r.BusinessStart,@EnDateDu) / 7.0 <= 104.0 THEN  DATEADD(MONTH,24,r.BusinessStart) 
								ELSE DATEADD(MONTH,36,r.BusinessStart) 
							END
						*/
		,QteMoisRecrueEnCour = @QteMoisRecrue -- CASE WHEN DATEDIFF(DAY,r.BusinessStart,@EnDateDu) / 7.0 <= 104.0 THEN 24 ELSE 36 END
	from #VenteParSemaine vs
	join #VenteParSemaine vs2 on vs.repid = vs2.repid and vs2.AuDimanche <= vs.AuDimanche
	JOIN (
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
		)BR ON BR.RepID = vs.repid
	join Mo_Human hb on hb.HumanID = br.BossID
	join Mo_Human hr on hr.HumanID = vs.repid
	join un_rep r on vs.repid = r.RepID
	left join #SoldeNetDebut sd on vs.repid = sd.repid
	where 1=1
		and r.BusinessEnd is null
		and br.BossID <> 149876
		and vs.AuDimanche <= @EnDateDu
		and vs.SemaineDebutRep BETWEEN 0 and ((@QteMoisRecrue / 12.0) * 52)
		AND /*QteMoisRecrueEnCour*/ ( CASE WHEN DATEDIFF(DAY,r.BusinessStart,@EnDateDu) / 7.0 <= 104.0 THEN 24 ELSE 36 END ) <= @QteMoisRecrue
		and (r.RepCode = @RepCode or @RepCode is null)
		and r.RepCode not in (
				--'70151' -- Anne Jetté, réintégré le 2016-07-13 JIRA TI-3991
				'70164'
				,'70090'
				,'70104'
				,'70105'
				,'70122'
				,'70147'
				,'70154'
				,'70165'
				,'70152'
				,'70155'
				,'70193'
				)

	GROUP BY
		vs.RepID
		,hr.FirstName + ' ' + hr.LastName
		,hb.FirstName + ' ' + hb.LastName
		,r.RepCode
		,r.BusinessStart
		,vs.Semaine
		,vs.DuLundi
		,vs.AuDimanche
		,vs.SemaineDebutRep
		,vs.QteUnitéNettes 
		,isnull(sd.SoldeNetDebut,0)


END
