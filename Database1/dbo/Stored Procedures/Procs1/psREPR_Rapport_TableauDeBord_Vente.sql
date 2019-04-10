
/****************************************************************************************************
Code de service		:		[psREPR_Rapport_TableauDeBord_Vente
Nom du service		:		
But					:		
Facette				:		REPR 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

Exemple d'appel:

	EXEC psREPR_Rapport_TableauDeBord_Vente  
		@StartDateParam = '2018-01-01',
		@EndDateParam = '2018-12-30',

		@StartDateParamPrec = '2017-01-01',
		@EndDateParamPrec = '2017-12-31'
		

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------


Historique des modifications :			
						Date		Programmeur			Description							Référence
						2018-06-22	Donald Huppé		Création du service
						2018-09-24	Donald Huppé		ajustement quand on saisit un période dans le futur. div par 0
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_Rapport_TableauDeBord_Vente]
	(	
	@StartDateParam datetime,
	@EndDateParam datetime,

	@StartDateParamPrec datetime,
	@EndDateParamPrec datetime
    )
AS
	BEGIN

--set ARITHABORT ON



	create table #TMPSemaine (
									DateFinPeriode varchar(10),
									NoSemaine int
									)

	create	table #Mois (NoMois int, Mois varchar(30))
	insert into #Mois values (1,'Janvier')
	insert into #Mois values (2,'Février')
	insert into #Mois values (3,'Mars')
	insert into #Mois values (4,'Avril')
	insert into #Mois values (5,'Mai')
	insert into #Mois values (6,'Juin')
	insert into #Mois values (7,'juillet')
	insert into #Mois values (8,'Août')
	insert into #Mois values (9,'Septembre')
	insert into #Mois values (10,'Octobre')
	insert into #Mois values (11,'Novembre')
	insert into #Mois values (12,'Décembre')

	
	DECLARE @startDateSunDay DATETIME
	DECLARE @endDateSunDay DATETIME

	SET @startDateSunDay = '2018-01-07' -- 1er dimanche
	SET @endDateSunDay = '2018-12-30'; -- dernier dimanche

	WITH dates(Date) AS 
	(
		SELECT @startDateSunDay as Date
		UNION ALL
		SELECT DATEADD(d,7,[Date])
		FROM dates 
		WHERE DATE < @endDateSunDay
	)

	insert into #TMPSemaine(NoSemaine,DateFinPeriode)
	SELECT 
		RangDate = DENSE_RANK() OVER (
									partition by null -- #2 : basé sur rien
									ORDER BY Date -- #1 : on numérote les Date
									)
		,Dimanche = cast(Date  as date)

	FROM dates
	OPTION (MAXRECURSION 0)


	SET @startDateSunDay = '2017-01-08' -- 1er dimanche
	SET @endDateSunDay = '2017-12-31'; -- dernier dimanche

	WITH dates(Date) AS 
	(
		SELECT @startDateSunDay as Date
		UNION ALL
		SELECT DATEADD(d,7,[Date])
		FROM dates 
		WHERE DATE < @endDateSunDay
	)

	insert into #TMPSemaine(NoSemaine,DateFinPeriode)
	SELECT 
		RangDate = DENSE_RANK() OVER (
									partition by null -- #2 : basé sur rien
									ORDER BY Date -- #1 : on numérote les Date
									)
		,Dimanche = cast(Date  as date)

	FROM dates
	OPTION (MAXRECURSION 0)
		
	--SELECT * FROM #TMPSemaine

	CREATE table
		#GrossANDNetUnits (
		UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier  NewSale, terminated et ReUsed ensemble
		UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original
		RepID INTEGER,
		Recrue INTEGER, -- Indique si le rep était recrue quand la vente brute ou le retrait ou la réinscripteur a eu lieu (utile pour les rapports de vente des recrues)
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT,
		DateUnite DATETIME) 

	insert into #GrossANDNetUnits
	exec SL_UN_RepGrossANDNetUnits_DateUnite
		@ReptreatmentID = NULL,
		@StartDate = @StartDateParam, -- Date de début
		@EndDate = @EndDateParam, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
		--,@QteMoisRecrue = 12,
		--@incluConvT = 1

	--SELECT * from #GrossANDNetUnits


	CREATE table
		#GrossANDNetUnitsPrec (
		UnitID_Ori INTEGER, -- Le unitID_Ori permettra à la sp appelante de lier  NewSale, terminated et ReUsed ensemble
		UnitID INTEGER, -- Le unitID et égale au unitID_Ori partout sauf pour la réinscription. Dans ce cas le le unitId représente le nouveau groupe d'unité et le Ori est le group d'unité original
		RepID INTEGER,
		Recrue INTEGER, -- Indique si le rep était recrue quand la vente brute ou le retrait ou la réinscripteur a eu lieu (utile pour les rapports de vente des recrues)
		BossID INTEGER,
		RepTreatmentID INTEGER,
		RepTreatmentDate DATETIME,
		Brut FLOAT,
		Retraits FLOAT,
		Reinscriptions FLOAT,
		Brut24 FLOAT,
		Retraits24 FLOAT,
		Reinscriptions24 FLOAT,
		DateUnite DATETIME) 

	insert into #GrossANDNetUnitsPrec
	exec SL_UN_RepGrossANDNetUnits_DateUnite
		@ReptreatmentID = NULL,
		@StartDate = @StartDateParamPrec, -- Date de début
		@EndDate = @EndDateParamPrec, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 -- On veut les résultats groupés par unitID.  Sinon, c'est groupé par RepID et BossID
		--,@QteMoisRecrue = 12,
		--@incluConvT = 1

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
			AND (StartDate <= @EndDateParam)
			AND (EndDate IS NULL OR EndDate >= @EndDateParam)
		GROUP BY
			RepID
		) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
	WHERE RB.RepRoleID = 'DIR'
		AND RB.StartDate IS NOT NULL
		AND (RB.StartDate <= @EndDateParam)
		AND (RB.EndDate IS NULL OR RB.EndDate >= @EndDateParam)
	GROUP BY
		RB.RepID	


	CREATE table #Result1 (
		Groupe VARCHAR(20),
		Humain VARCHAR(255),
		UniteNette float,
		UniteBrute float,
		ConsPct float,
		EnDateDu datetime,
		NoSemaine int,
		Annee int,
		MoisNo int,
		mois VARCHAR(50)
		)

	INSERT INTO #Result1
	SELECT *
	FROM (

		SELECT 
			Groupe = 'DIR',
			Humain = case when  br.bossid in (
								149593,--	5852--Martin Mercier
								149489,--	6070-- Clément Blais
								149521,--	6262--Michel Maheu
								436381	--	7036--Sophie Babeux		
			) then hb.FirstName + ' ' + hb.LastName else 'Autre ' end,
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			ConsPct = 0,
			EnDateDu = DateUnite,
			S.NoSemaine,
			Annee = YEAR(g.DateUnite),
			MoisNo = MONTH(g.DateUnite),
			m.mois
		from #GrossANDNetUnits g
		join #BossRepActuel br on br.RepID = g.RepID
		join Mo_Human hb on hb.HumanID = br.bossid
		left join #TMPSemaine S on g.DateUnite BETWEEN DATEADD(DAY,-6,S.DateFinPeriode) AND S.DateFinPeriode
		left join #Mois m on m.nomois = MONTH(g.DateUnite)
		GROUP by 

			case when  br.bossid in (
								149593,--	5852--Martin Mercier
								149489,--	6070-- Clément Blais
								149521,--	6262--Michel Maheu
								436381	--	7036--Sophie Babeux		
			) then hb.FirstName + ' ' + hb.LastName else 'Autre ' end,
			DateUnite
			,S.NoSemaine
			,m.mois
		HAVING sum((Brut) - ( (Retraits) - (Reinscriptions) )) <> 0

		UNION ALL

		SELECT 
			Groupe = 'DIR',
			Humain = case when  br.bossid in (
								149593,--	5852--Martin Mercier
								149489,--	6070-- Clément Blais
								149521,--	6262--Michel Maheu
								436381	--	7036--Sophie Babeux		
			) then hb.FirstName + ' ' + hb.LastName else 'Autre ' end,
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			ConsPct = 0,
			EnDateDu = DateUnite,
			NoSemaine = isnull(S.NoSemaine,1),
			Annee = YEAR(g.DateUnite),
			MoisNo = MONTH(g.DateUnite),
			m.mois
		from #GrossANDNetUnitsPrec g
		join #BossRepActuel br on br.RepID = g.RepID
		join Mo_Human hb on hb.HumanID = br.bossid
		left join #TMPSemaine S on g.DateUnite BETWEEN DATEADD(DAY,-6,S.DateFinPeriode) AND S.DateFinPeriode
		left join #Mois m on m.nomois = MONTH(g.DateUnite)
		GROUP by 

			case when  br.bossid in (
								149593,--	5852--Martin Mercier
								149489,--	6070-- Clément Blais
								149521,--	6262--Michel Maheu
								436381	--	7036--Sophie Babeux		
			) then hb.FirstName + ' ' + hb.LastName else 'Autre ' end,
			DateUnite
			,S.NoSemaine
			,m.mois
		HAVING sum((Brut) - ( (Retraits) - (Reinscriptions) )) <> 0
		)v	
	order by 
		EnDateDu
		,Humain


	INSERT INTO #Result1
	SELECT *
	FROM (

		SELECT 
			Groupe = 'REP_EXP',
			Humain = 'tous',
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			ConsPct = 0,
			EnDateDu = DateUnite,
			S.NoSemaine,
			Annee = YEAR(g.DateUnite),
			MoisNo = MONTH(g.DateUnite),
			m.mois
		from #GrossANDNetUnits g
		join un_rep r on r.RepID = g.RepID
		join Mo_Human hr on hr.HumanID = r.RepID
		left join #TMPSemaine S on g.DateUnite BETWEEN DATEADD(DAY,-6,S.DateFinPeriode) AND S.DateFinPeriode
		left join #Mois m on m.nomois = MONTH(g.DateUnite)
		WHERE 
			R.BusinessStart < @StartDateParam
			AND ISNULL(R.BusinessEnd,'9999-12-31') > DATEADD(DAY,2,@StartDateParam)
			AND R.RepID <> 149876 -- SIEGE SOCIAL
		GROUP by 
			DateUnite
			,S.NoSemaine
			,m.mois
		HAVING sum((Brut) - ( (Retraits) - (Reinscriptions) )) <> 0

		UNION ALL

		SELECT 
			Groupe = 'REP_EXP',
			Humain = 'tous',
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			ConsPct = 0,
			EnDateDu = DateUnite,
			NoSemaine = isnull(S.NoSemaine,1),
			Annee = YEAR(g.DateUnite),
			MoisNo = MONTH(g.DateUnite),
			m.mois
		from #GrossANDNetUnitsPrec g
		join un_rep r on r.RepID = g.RepID
		join Mo_Human hr on hr.HumanID = r.RepID
		left join #TMPSemaine S on g.DateUnite BETWEEN DATEADD(DAY,-6,S.DateFinPeriode) AND S.DateFinPeriode
		left join #Mois m on m.nomois = MONTH(g.DateUnite)
		WHERE 
			R.BusinessStart < @StartDateParam
			AND ISNULL(R.BusinessEnd,'9999-12-31') > DATEADD(DAY,2,@StartDateParam)
			AND R.RepID <> 149876 -- SIEGE SOCIAL
		GROUP by 
			DateUnite
			,S.NoSemaine
			,m.mois
		HAVING sum((Brut) - ( (Retraits) - (Reinscriptions) )) <> 0
		)v	
	order by 
		EnDateDu
		,Humain


	INSERT INTO #Result1
	SELECT 
		Groupe = 'RECRUE',
		Humain = 'tous',
		UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
		UniteBrute =sum(Brut),
		ConsPct = 0,
		EnDateDu = DateUnite,
		NoSemaine = isnull(S.NoSemaine,1),
		Annee = YEAR(g.DateUnite),
		MoisNo = MONTH(g.DateUnite),
		m.mois
	from #GrossANDNetUnits g
	join un_rep r on r.RepID = g.RepID
	join Mo_Human hr on hr.HumanID = r.RepID
	left join #TMPSemaine S on g.DateUnite BETWEEN DATEADD(DAY,-6,S.DateFinPeriode) AND S.DateFinPeriode
	left join #Mois m on m.nomois = MONTH(g.DateUnite)
	WHERE R.BusinessStart >= @StartDateParam
	GROUP by 
		DateUnite
		,S.NoSemaine
		,m.mois


	INSERT INTO #Result1
	SELECT *
	FROM (
		SELECT 
			Groupe = 'GUI',
			Humain = 'Total',
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			-- Taux de cons des unités de la période - et non des unité 24 mois
			ConsPct =	sum((Brut) - ( (Retraits) - (Reinscriptions) ))
						/
						sum(Brut)
						* 100.0,
			EnDateDu = @EndDateParam,
			NoSemaine = 99,
			Annee =YEAR(@EndDateParam),
			MoisNo = 99,
			mois = ''
		from #GrossANDNetUnits g

		UNION ALL	

		SELECT 
			Groupe = 'GUI',
			Humain = 'Total',
			UniteNette = sum((Brut) - ( (Retraits) - (Reinscriptions) )),
			UniteBrute =sum(Brut),
			-- Taux de cons des unités de la période - et non des unité 24 mois
			ConsPct =	sum((Brut) - ( (Retraits) - (Reinscriptions) ))
						/
						sum(Brut)
						* 100.0,
			EnDateDu = @EndDateParamPrec,
			NoSemaine = 99,
			Annee =YEAR(@EndDateParamPrec),
			MoisNo = 99,
			mois = ''
		from #GrossANDNetUnitsPrec g

		UNION ALL

		SELECT 
			Groupe = 'GUI',
			Humain = 'Semaine',
			UniteNette = sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParam) AND @EndDateParam THEN  (Brut) - ( (Retraits) - (Reinscriptions) )  ELSE 0 END   ),
			UniteBrute =sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParam) AND @EndDateParam THEN  Brut  ELSE 0 END ),
			-- Taux de cons des unités de la période - et non des unité 24 mois
			ConsPct =	sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParam) AND @EndDateParam THEN  (Brut) - ( (Retraits) - (Reinscriptions) )  ELSE 0 END   )
						/
						CASE WHEN
							sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParam) AND @EndDateParam THEN  Brut  ELSE 0 END ) <> 0
							THEN
							sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParam) AND @EndDateParam THEN  Brut  ELSE 0 END )
							ELSE
							1
							END
							
						* 100.0,
			EnDateDu = @EndDateParam,
			NoSemaine = 88,
			Annee =YEAR(@EndDateParam),
			MoisNo = 88,
			mois = ''
		from #GrossANDNetUnits g


		UNION ALL

		SELECT 
			Groupe = 'GUI',
			Humain = 'Semaine',
			UniteNette = sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParamPrec) AND @EndDateParamPrec THEN  (Brut) - ( (Retraits) - (Reinscriptions) )  ELSE 0 END   ),
			UniteBrute =sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParamPrec) AND @EndDateParamPrec THEN  Brut  ELSE 0 END ),
			ConsPct =	sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParamPrec) AND @EndDateParamPrec THEN  (Brut) - ( (Retraits) - (Reinscriptions) )  ELSE 0 END   )
						/
						CASE WHEN
							sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParamPrec) AND @EndDateParamPrec THEN  Brut  ELSE 0 END ) <> 0
							THEN
							sum( CASE WHEN  DateUnite BETWEEN DATEADD(DAY,-6,@EndDateParamPrec) AND @EndDateParamPrec THEN  Brut  ELSE 0 END )
							ELSE
							1
							END
							
						* 100.0,
			EnDateDu = @EndDateParamPrec,
			NoSemaine = 88,
			Annee =YEAR(@EndDateParamPrec),
			MoisNo = 88,
			mois = ''
		from #GrossANDNetUnitsPrec g


		)V



	SELECT 
		r.Groupe,
		r.Humain, 
		r.Annee,	
		r.MoisNo,	
		r.mois,
		r.NoSemaine, 
		r.EnDateDu,
		r.UniteNette, 
		r.UniteBrute,
		r.ConsPct,

		UniteNetteDepuisDebut = sum(isnull(rb.UniteNette,0)),
		Janvier_a_FinMois = case when r.EnDateDu = LastDayOfMonth then 1 else 0 end
	INTO #Result2
	from #Result1 r
	left JOIN #Result1 rb  on rb.Groupe = r.Groupe AND rb.Humain = r.Humain and rb.annee = r.annee and rb.EnDateDu <= r.EnDateDu
	left join (
		SELECT Groupe,Humain, annee, moisno, LastDayOfMonth = max(EnDateDu)
		from #Result1
		group by Groupe,Humain,annee, moisno
		)ld on ld.Groupe = r.Groupe and ld.Humain = r.Humain and ld.annee = r.annee and ld.moisno = r.moisno
	GROUP BY r.Groupe, r.Humain, r.Annee,	r.MoisNo,	r.mois,r.NoSemaine,r.EnDateDu,r.UniteNette,	r.UniteBrute,r.ConsPct,LastDayOfMonth
	order by r.Groupe, r.Humain, r.Annee,	r.MoisNo,	r.mois,r.NoSemaine,r.EnDateDu


	SELECT 
		r.Groupe,
		r.Humain, 
		r.Annee,	
		r.MoisNo,	
		r.mois,
		r.NoSemaine, 
		r.EnDateDu,
		r.UniteNette, 
		r.UniteBrute,
		r.ConsPct,

		r.UniteNetteDepuisDebut,
		r.Janvier_a_FinMois,
	
		UniteNetteSemaineDepuisDebut = sum(isnull(rb.UniteNette,0)),
		Janvier_a_FinSemaine = case when r.EnDateDu = LastDayOfweek then 1 else 0 end

	INTO #Result3
	from #Result2 r
	left JOIN #Result2 rb  on rb.Groupe = r.Groupe AND rb.Humain = r.Humain and rb.annee = r.annee and rb.EnDateDu <= r.EnDateDu
	left join (
		SELECT Groupe,Humain, annee, NoSemaine, LastDayOfweek = max(EnDateDu)
		from #Result2
		group by Groupe,Humain,annee,NoSemaine
		)ld on ld.Groupe = r.Groupe and ld.Humain = r.Humain and ld.annee = r.annee and ld.NoSemaine = r.NoSemaine
	GROUP BY r.Groupe, r.Humain, r.Annee,	r.MoisNo,	r.mois,r.NoSemaine,r.EnDateDu,r.UniteNette,	r.UniteBrute,r.ConsPct,LastDayOfweek,r.UniteNetteDepuisDebut,r.Janvier_a_FinMois
	order by r.Groupe, r.Humain, r.Annee,	r.MoisNo,	r.mois,r.NoSemaine,r.EnDateDu



	SELECT 
		r.Groupe,
		r.Humain, 
		r.Annee,	
		r.MoisNo,	
		r.mois,
		r.NoSemaine, 
		r.EnDateDu,
		r.UniteNette, 
		r.UniteBrute,
		r.ConsPct,
		r.UniteNetteDepuisDebut,
		r.Janvier_a_FinMois,
		r.UniteNetteSemaineDepuisDebut,
		r.Janvier_a_FinSemaine,
		PctAugm_vs_AnneePrec = (r.UniteNetteDepuisDebut - r2.UniteNetteDepuisDebut) / r2.UniteNetteDepuisDebut --* 100
	FROM #Result3 r
	left join  #Result3 r2 on 
		r.Groupe = r2.Groupe 
		and r.Humain = r2.Humain 
		and r.Annee = year(@EndDateParam)
		and r2.Annee = year(@EndDateParamPrec)

		and r.moisno = r2.moisno
		and r.Janvier_a_FinMois = 1 
		and r2.Janvier_a_FinMois = 1 

	where 1=1




--SET ARITHABORT OFF

END
