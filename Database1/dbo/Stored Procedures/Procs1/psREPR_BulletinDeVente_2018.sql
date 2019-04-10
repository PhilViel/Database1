/****************************************************************************************************
Copyrights (c) 2010 Gestion Universitas Inc.
Nom                 :	psREPR_BulletinDeVente_2018
Description         :	Procédure stockée du rapport du Bulletin de vente 2018
Valeurs de retours  :	Dataset 
Note                :	2018-04-11			Donald Huppé	Création
						2018-06-19			Donald Huppé	jira prod-10290 : Dans les agence, inclure les rep qui ont été actif durant la période de cumul (depuis le 1er janvier) - RepIsActiveDuringPeriod
						2018-09-17			Donald Huppé	Rep Marie-Josée Lessard n'est pas recrue
						2018-09-25			Donald Huppé	JIRA PROD-11900 : Ajout des directeurs ajoints pour option de la afficher dans un tableazu à part dans le bulletin
						2018-09-07			Maxime Martel	JIRA MP-699 Ajout de OpertypeID COU
						2018-11-12			Donald Huppé	Exclure 3 directeur adjoint
															Programmation pour aller chercher les dir adjoint (qui sont rep Niveau 3)
						2018-12-17			Donald Huppé	jira prod-13348 : semaine 52 termine le 31 déc au lieu du 30 déc
						2019-01-17			Donald Huppé	jira ti-15364 : faire sortir les rep actifs qui sont à zéro

exec psREPR_BulletinDeVente_2018_test '2019-01-07','2019-01-13','2018-01-08','2018-01-14'
exec psREPR_BulletinDeVente_2018_test '2019-01-14','2019-01-20','2018-01-15','2018-01-21'

--drop proc psREPR_BulletinDeVente_2018_test

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_BulletinDeVente_2018] (
	@StartDate DATETIME,
	@EndDate DATETIME, 
	@StartDatePrec DATETIME,
	@EndDatePrec DATETIME
	) 
AS
BEGIN
--DECLARE
--	@StartDate DATETIME = '2018-01-15',
--	@EndDate DATETIME = '2018-01-21', 
--	@StartDatePrec DATETIME = '2017-01-16',
--	@EndDatePrec DATETIME = '2017-01-22'

set arithabort on

	DECLARE 
		@JanuaryFirst AS DATETIME,
		@JanuaryFirstPrec AS DATETIME,
		@Diviseur AS FLOAT = 2500.0
		
		--@NetSemaine float,
		--@NetSemainePrec float,
		--@ObjectifSemaine float,
		--@NetMoisPrec float,
		--@ObjectifMoisActuel float,
		--@NetMois float,
		--@ObjCumul float
		
	if @StartDate = '9999-12-31'
		begin
		set @StartDate = DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0)
		set @EndDate = dateadd(dd,6, DATEADD(wk, DATEDIFF(wk,0,GETDATE()), 0))
		--set @StartDatePrec = DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())), 0)
		--set @EndDatePrec = dateadd(dd,6, DATEADD(wk, DATEDIFF(wk,0, dateadd(yy,-1, GETDATE())   ), 0))
		end




	SET @JanuaryFirst = CAST(YEAR(@EndDate) as varchar(4)) + '-01-01'
	SET @JanuaryFirstPrec = CAST(YEAR(@EndDatePrec) as varchar(4)) + '-01-01'

	create table #TMPObjectifBulletin (
									DateFinPeriode varchar(10),
									Weekno int,
									ObjSemaine float,
									ObjCumul float
									)


	
	DECLARE @startDateSunDay DATETIME
	DECLARE @endDateSunDay DATETIME

	SET @startDateSunDay = CASE 
							WHEN YEAR(@EndDate) = 2018 THEN '2018-01-07' 
							WHEN YEAR(@EndDate) = 2019 THEN '2019-01-06' 
							ELSE NULL END-- 1er dimanche
	SET @endDateSunDay = CASE 
							WHEN YEAR(@EndDate) = 2018 THEN '2018-12-30' 
							WHEN YEAR(@EndDate) = 2019 THEN '2019-12-29' 
							ELSE NULL END ; -- dernier dimanche

	WITH dates(Date) AS 
	(
		SELECT @startDateSunDay as Date
		UNION ALL
		SELECT DATEADD(d,7,[Date])
		FROM dates 
		WHERE DATE < @endDateSunDay
	)

	insert into #TMPObjectifBulletin(Weekno,DateFinPeriode,ObjSemaine,ObjCumul)
	SELECT 
		RangDate = DENSE_RANK() OVER (
									partition by null -- #2 : basé sur rien
									ORDER BY Date -- #1 : on numérote les Date
									)
		,Dimanche = cast(Date  as date)
		,ObjSemaine = 0
		,ObjCumul = 0
	FROM dates
	OPTION (MAXRECURSION 0)


	IF YEAR(@EndDate) = 2018
	BEGIN
		-- ON FORCE LE DERNIER JOUR DU BULLETIN 52 AU 2018-12-31 AU LIEU DU 30
		UPDATE #TMPObjectifBulletin SET DateFinPeriode = '2018-12-31' WHERE DateFinPeriode =  '2018-12-30'
	END		

	SELECT RepID
	INTO #ListeDirecteur
	FROM Un_Rep
	WHERE RepID IN (
		149593,--	5852--Martin Mercier
		149489,--	6070-- Clément Blais
		149521,--	6262--Michel Maheu
		436381	--	7036--Sophie Babeux
		)


	SELECT
		R.RepID
	INTO #ListeDirecteurAdjoint
	FROM Un_Rep R
	JOIN Un_RepLevelHist H ON R.RepID = H.RepID
	JOIN Un_RepLevel L ON L.RepLevelID = H.RepLevelID
	--JOIN Un_RepRole Ro ON Ro.RepRoleID = L.RepRoleID
	WHERE 1=1
		AND  L.RepRoleID = 'REP'
		AND l.LevelShortDesc = '5'
		AND @EndDate BETWEEN h.StartDate AND ISNULL(h.EndDate,'9999-12-31')
		AND ISNULL(r.BusinessEnd,'9999-12-31') > @EndDate
		AND r.RepID not in (SELECT RepID FROM #ListeDirecteur)

	--SELECT * FROM #ListeDirecteur
	--SELECT * FROM #ListeDirecteurAdjoint

	SELECT 
		RepID,
		RepCode,
		BusinessStart = CASE 
						WHEN RepID = 795683 THEN '2002-05-28' --Sophie Asselin
						WHEN RepID = 719791 THEN '2003-01-06' --Ghislain Thibeault
						WHEN RepID = 815078 THEN '2011-10-25' --Marie-Josée Lessard
						ELSE BusinessStart
						END
		,BusinessEnd
	INTO #tUn_Rep
	FROM Un_Rep


	SELECT RepID
	INTO #ListeRepSiegeSocial
	FROM Un_Rep
	WHERE RepID IN (
			149876	,--siege social
			764401	,--Nadine Babin
			584143	,--Véronique Guimond
			764400	,--Martine Larrivée
			769040	,--Annie Poirier
			770362	,--Caroline Samson
			752607	-- Hélène Roy
			)

	--RETURN

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
 	


	SELECT UnitID,	RepID,	BossID,	dtFirstDeposit 
	INTO #Unit_T
	FROM fntREPR_ObtenirUniteConvT (1)


	CREATE TABLE #tOperTable(
		OperID INT PRIMARY KEY)

	-- période en cours
	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		WHERE OperDate BETWEEN @JanuaryFirst AND @EndDate
				AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI TIN NSF OUT RES RET COU', 1) > 0
	
	-- période précédente
	INSERT INTO #tOperTable(OperID)
		SELECT 
			OperID
		FROM Un_Oper o WITH(NOLOCK) 
		WHERE OperDate BETWEEN @JanuaryFirstPrec AND @EndDatePrec
				AND CharIndex(o.OperTypeID, 'CPA CHQ PRD RDI TIN NSF OUT RES RET COU', 1) > 0


	SELECT 
		RepID,
		PrenomRep,
		NomRep,
		RepCode,
		Directeur
		,RepCodeDirecteur 
		,Recrue 
		,EpargneEtFrais = SUM( EpargneEtFrais)
		,EpargneEtFraisCumul = SUM(EpargneEtFraisCumul)
		,EpargneEtFraisPREC = SUM(EpargneEtFraisPREC)
		,EpargneEtFraisCumulPREC = sum(EpargneEtFraisCumulPREC)
	INTO #Cotisation

	from (
			select 
				R.RepID,
				PrenomRep = hr.FirstName,
				NomRep = hr.LastName,
				r.RepCode,
				Directeur = CASE 
							WHEN HB.HumanID IS NULL OR HB.HumanID = 149876 THEN HBS.FirstName + ' ' + HBS.LastName 
							ELSE hb.FirstName + ' ' + hb.LastName
							END
				,RepCodeDirecteur  = 
							CASE 
							WHEN HB.HumanID IS NULL OR HB.HumanID = 149876 THEN RB.RepCode 
							ELSE RBU.RepCode
							END
				,Recrue = 0 -- CASE WHEN O.OperDate BETWEEN R.BusinessStart AND DATEADD(YEAR,1,R.BusinessStart) THEN 1 ELSE 0 END
				,EpargneEtFrais = SUM( 
										CASE 
										WHEN O.OperDate BETWEEN @StartDate AND @EndDate 
											AND (u.dtFirstDeposit BETWEEN @JanuaryFirst and @EndDate OR C.PlanID = 4 ) 
										THEN  ct.Cotisation + ct.Fee ELSE 0 END)

				,EpargneEtFraisCumul = SUM( 
										CASE 
										WHEN O.OperDate BETWEEN @JanuaryFirst AND @EndDate 
											AND (u.dtFirstDeposit BETWEEN @JanuaryFirst and @EndDate OR C.PlanID = 4 ) 
										THEN  ct.Cotisation + ct.Fee ELSE 0 END)

				,EpargneEtFraisPREC = SUM( 
										CASE 
										WHEN O.OperDate BETWEEN @StartDatePrec AND @EndDatePrec 
											AND (u.dtFirstDeposit BETWEEN @JanuaryFirstPrec and @EndDatePrec OR C.PlanID = 4 ) 
										THEN  ct.Cotisation + ct.Fee ELSE 0 END)

				,EpargneEtFraisCumulPREC = SUM( 
										CASE 
										WHEN O.OperDate BETWEEN @JanuaryFirstPrec AND @EndDatePrec 
											AND (u.dtFirstDeposit BETWEEN @JanuaryFirstPrec and @EndDatePrec OR C.PlanID = 4 ) 
										THEN  ct.Cotisation + ct.Fee ELSE 0 END)

			from 
				un_cotisation ct
				JOIN un_oper o on ct.OperID = o.OperID
				JOIN #tOperTable ot on ot.OperID = o.OperID
				JOIN Un_Unit u on u.UnitID = ct.UnitID
				JOIN Un_Convention c on c.ConventionID = u.ConventionID
				JOIN Un_Subscriber S ON C.SubscriberID = S.SubscriberID
				JOIN Un_Rep r on r.RepID = u.RepID
				JOIN Mo_Human hr on hr.HumanID = r.RepID
				LEFT JOIN (
					SELECT 
						M.UnitID,
						BossID = MAX(RBH.BossID)
					FROM (
						SELECT 
							U.UnitID,
							U.RepID,
							RepBossPct = MAX(RBH.RepBossPct)
						FROM Un_Unit U
						JOIN Un_RepBossHist RBH ON RBH.RepID = U.RepID AND (U.InForceDate >= RBH.StartDate) AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND (RBH.RepRoleID = 'DIR')
						JOIN Un_RepLevel BRL ON (BRL.RepRoleID = RBH.RepRoleID)
						JOIN Un_RepLevelHist BRLH ON (BRLH.RepLevelID = BRL.RepLevelID) AND (BRLH.RepID = RBH.BossID) AND (U.InForceDate >= BRLH.StartDate)  AND (U.InForceDate <= BRLH.EndDate  OR BRLH.EndDate IS NULL)
						GROUP BY U.UnitID, U.RepID
						) M
					JOIN Un_Unit U ON U.UnitID = M.UnitID
					JOIN Un_RepBossHist RBH ON RBH.RepID = M.RepID AND RBH.RepBossPct = M.RepBossPct AND (U.InForceDate >= RBH.StartDate)  AND (U.InForceDate <= RBH.EndDate OR RBH.EndDate IS NULL) AND RBH.RepRoleID = 'DIR'
					GROUP BY 
						M.UnitID
						)bu on bu.UnitID = u.UnitID
				LEFT JOIN Mo_Human hb on bu.BossID = hb.HumanID
				LEFT JOIN Un_Rep RBU ON RBU.RepID = BU.BossID
				LEFT JOIN (
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
								AND LEFT(CONVERT(VARCHAR, StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)
								AND (EndDate IS NULL OR LEFT(CONVERT(VARCHAR, EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)) 
							GROUP BY
									RepID
							) MRB ON MRB.RepID = RB.RepID AND MRB.RepBossPct = RB.RepBossPct
						WHERE RB.RepRoleID = 'DIR'
							AND RB.StartDate IS NOT NULL
							AND LEFT(CONVERT(VARCHAR, RB.StartDate, 120), 10) <= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10)
							AND (RB.EndDate IS NULL OR LEFT(CONVERT(VARCHAR, RB.EndDate, 120), 10) >= LEFT(CONVERT(VARCHAR, @EndDate, 120), 10))
						GROUP BY
							RB.RepID
					)BR ON BR.RepID = S.RepID
				LEFT JOIN Mo_Human HBS ON HBS.HumanID = BR.BossID
				LEFT JOIN Un_Rep RB	ON RB.RepID = BR.BossID
				LEFT JOIN Un_Tio TIOt on TIOt.iTINOperID = o.operid
				LEFT JOIN Un_Tio TIOo on TIOo.iOUTOperID = o.operid
				LEFT JOIN (
					select u1.ConventionID, MinUnitID =  min(u1.UnitID), Date1erDepotConv = min(u1.dtFirstDeposit)
					from Un_Unit u1
					GROUP BY u1.ConventionID
					) mu on  mu.ConventionID = u.ConventionID --and mu.MinUnitID = u.UnitID
				LEFT JOIN #Unit_T t on t.unitid = u.UnitID
			where 1=1
				AND t.unitid is null
				--AND (u.dtFirstDeposit BETWEEN @JanuaryFirst and @EndDate OR C.PlanID = 4 ) 
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------

				AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------

						

			group by 
				R.RepID,
				hr.FirstName,
				hr.LastName,
				r.RepCode,
				CASE 
					WHEN HB.HumanID IS NULL OR HB.HumanID = 149876 THEN HBS.FirstName + ' ' + HBS.LastName 
					ELSE hb.FirstName + ' ' + hb.LastName
					END,
				CASE 
					WHEN HB.HumanID IS NULL OR HB.HumanID = 149876 THEN RB.RepCode 
					ELSE RBU.RepCode
					END


		UNION ALL

			-- contrat T et I BEC

			select 
				R.RepID,
				PrenomRep = hr.FirstName,
				NomRep = hr.LastName,
				r.RepCode,
				Directeur = hb.FirstName + ' ' + hb.LastName
				,RepCodeDirecteur  = RB.RepCode
				,Recrue = 0 --CASE WHEN O.OperDate BETWEEN R.BusinessStart AND DATEADD(YEAR,1,R.BusinessStart) THEN 1 ELSE 0 END
				,EpargneEtFrais = SUM( CASE WHEN O.OperDate BETWEEN @StartDate AND @EndDate THEN  ct.Cotisation + ct.Fee ELSE 0 END)
				,EpargneEtFraisCumul = SUM( CASE WHEN O.OperDate BETWEEN @JanuaryFirst AND @EndDate THEN  ct.Cotisation + ct.Fee ELSE 0 END)

				,EpargneEtFraisPREC = SUM( CASE WHEN O.OperDate BETWEEN @StartDatePrec AND @EndDatePrec THEN  ct.Cotisation + ct.Fee ELSE 0 END)
				,EpargneEtFraisCumulPREC = SUM( CASE WHEN O.OperDate BETWEEN @JanuaryFirstPrec AND @EndDatePrec THEN  ct.Cotisation + ct.Fee ELSE 0 END)
			from 
				un_cotisation ct
				join #Unit_T t on t.unitid = ct.UnitID
				join un_oper o on ct.OperID = o.OperID
				join #tOperTable ot on ot.OperID = o.OperID
				join Un_Unit u on u.UnitID = ct.UnitID
				JOIN Un_Rep r on r.RepID = t.RepID
				join Mo_Human hr on hr.HumanID = r.RepID
				join Mo_Human hb on hb.HumanID = T.BossID
				JOIN Un_Rep RB ON RB.RepID = T.BOSSID
				LEFT JOIN Un_Tio TIOt on TIOt.iTINOperID = o.operid
				LEFT JOIN Un_Tio TIOo on TIOo.iOUTOperID = o.operid
				LEFT JOIN (
					select u1.ConventionID, MinUnitID =  min(u1.UnitID), Date1erDepotConv = min(u1.dtFirstDeposit)
					from Un_Unit u1
					GROUP BY u1.ConventionID
					) mu on  mu.ConventionID = u.ConventionID --and mu.MinUnitID = u.UnitID
							
			where 1=1
							
				--AND u.dtFirstDeposit BETWEEN @DateDu and @DateAu
				------------------- Même logique que dans les rapports d'opération cashing et payment --------------------

				AND tiot.iTINOperID is NULL -- TIN qui n'est pas un TIO
				AND tioo.iOUTOperID is NULL -- OUT qui n'est pas un TIO
				-----------------------------------------------------------------------------------------------------------
			group by 
				R.RepID,
				hr.FirstName,
				hr.LastName,
				r.RepCode,
				hb.FirstName,
				hb.LastName,
				--CASE WHEN O.OperDate BETWEEN R.BusinessStart AND DATEADD(YEAR,1,R.BusinessStart) THEN 1 ELSE 0 END,
				RB.RepCode
		)v
	GROUP BY
		RepID,
		PrenomRep,
		NomRep,
		RepCode,
		Directeur,
		RepCodeDirecteur,
		Recrue 

	HAVING 
		SUM( EpargneEtFrais) <> 0
		OR SUM(EpargneEtFraisCumul) <> 0
		OR SUM(EpargneEtFraisPREC) <> 0
		OR sum(EpargneEtFraisCumulPREC) <> 0
--RETURN

	--SELECT * from #Cotisation where repid = 805797


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
	exec SL_UN_RepGrossANDNetUnits --NULL, @StartDate,@EndDate, 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDate, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		--,@QteMoisRecrue = 12


	/*
	-- Pas besoin pour l'instant
	insert into #GNUSemainePrec
	exec SL_UN_RepGrossANDNetUnits --NULL, @StartDatePrec,@EndDatePrec, 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @StartDatePrec, -- Date de début
		@EndDate = @EndDatePrec, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		--,@QteMoisRecrue = 12
 	*/


	insert into #GNUCumul
	exec SL_UN_RepGrossANDNetUnits --NULL, @JanuaryFirst , @EndDate , 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @JanuaryFirst, -- Date de début
		@EndDate = @EndDate, -- Date de fin
		@RepID = 0, -- ID du représentant
		@ByUnit = 1 
		--,@QteMoisRecrue = 12

	

	insert into #GNUCumulPrec
	exec SL_UN_RepGrossANDNetUnits --NULL, @JanuaryFirstPrec , @EndDatePrec , 0, 1
		@ReptreatmentID = NULL,-- ID du traitement de commissions
		@StartDate = @JanuaryFirstPrec, -- Date de début
		@EndDate = @EndDatePrec, -- Date de fin
		@RepID = 0, --@RepID, -- ID du représentant
		@ByUnit = 1 
		--,@QteMoisRecrue = 12


--DECLARE
--	@StartDate DATETIME = '2018-01-15',
--	@EndDate DATETIME = '2018-01-21', 
--	@StartDatePrec DATETIME = '2017-01-16',
--	@EndDatePrec DATETIME = '2017-01-22'
		
	select 
		V.RepID,
		PrenomRep,
		NomRep,

		Recrue =	CASE 
					WHEN R.BusinessStart > DATEADD(YEAR,-1,@StartDate) THEN 1
					ELSE 0
					END,

		--Recrue = CASE 
		--			WHEN V.RepID in (
		--					149632	, --Carole Delorme
		--					446583	, --Thérèse Lafrance
		--					469387	, --Marie-Louise Mujinga Muya
		--					527770	, --Aline Therrien
		--					562918	, --Richard Pelletier
		--					594232	, --Lise Fournier
		--					625284	, --Vénus Fréchette
		--					647603	, --Ronald Petroff
		--					711180	, --Marie-Eve Saulnier
		--					719791	, --Ghislain Thibeault
		--					727150	, --Claire Arseneau
		--					768019	, --Chantale Ouellet
		--					736892	, --André Larocque	
		--					795683    --Sophie Asselin
		--							)  THEN 0 
		--			WHEN R.BusinessStart > DATEADD(YEAR,-1,@StartDate) THEN 1
		--			ELSE 0
		--			END,

		V.RepCode,

		RepCodeDirecteur = case when V.RepCodeDirecteur = 'ND' then RB.RepCode else V.RepCodeDirecteur end, 

		BusinessStart = CAST(R.BusinessStart AS DATE), -- GLPI 4408 mettre les données de la nouvelle vie de Lise Fournier comme NON recrue
		
		RepIsActive =	CASE 
							WHEN isnull(R.BusinessEnd,'3000-01-01') > @EndDate THEN 1
							ELSE 0 
						END,

		RepIsActiveDuringPeriod =	CASE 
									WHEN R.BusinessStart <= @EndDate AND ISNULL(R.BusinessEnd,'3000-01-01') > @JanuaryFirst /* > : exclure les fin de contrat le 1er janvier*/ THEN 1
									ELSE 0 
									END,

		DirecteurActuel = B.FirstName + ' ' + B.LastName,

		DirecteurActuelRepID = RB.RepID,
		
		-- Si le Directeur lors de la vente est Nd (non déterminé en date de InforceDate), alors on met le directeur actuel,
		Directeur = case when V.Directeur = 'ND' then B.FirstName + ' ' + B.LastName else Directeur end,

		--DirecteurReconnu = CASE WHEN  /*RepCodeDirecteur */ ( CASE WHEN V.RepCodeDirecteur = 'ND' THEN RB.RepCode ELSE V.RepCodeDirecteur END )
		--					in (
		--					'7036'--Sophie Babeux
		--					,'6070'-- Clément Blais
		--					,'6262' --Michel Maheu
		--					,'5852' --Martin Mercier
		--					) then 1 ELSE 0 end,

		DirecteurReconnu = CASE WHEN  RB.RepID -- Basé sur le directeur actuel et non le dir de la vente
							in (
								SELECT RepID FROM #ListeDirecteur
							--149593,--	5852--Martin Mercier
							--149489,--	6070-- Clément Blais
							--149521,--	6262--Michel Maheu
							--436381	--	7036--Sophie Babeux
							) then 1 ELSE 0 end,



		Net = SUM(Net),
		NetPrec = SUM(NetPrec),
		Cumul = SUM(Cumul),
		CumulPrec = SUM(CumulPrec),

		Cotis = SUM (Cotis),
		CotisPrec = SUM (CotisPrec),
		CotisCumul = SUM (CotisCumul),
		CotisCumulPrec = SUM (CotisCumulPrec),

		Point = SUM(Net) + (SUM (Cotis) / @Diviseur),
		PointPrec = SUM(NetPrec) + (SUM (CotisPrec) / @Diviseur),
		PointCumul = SUM(Cumul) + (SUM (CotisCumul) / @Diviseur),
		PointCumulPrec = SUM(CumulPrec) + (SUM (CotisCumulPrec) / @Diviseur),


		Categorie = CASE WHEN V.repid in ( SELECT RepID FROM #ListeDirecteurAdjoint 
										--466100, --		Chantal Jobin
										--629154, --		Steve Blais

										---- DIRECTEURS ADJOINTS JIRA TI-11315
										--149497	, --	6158	Carole Marchand
										----422223	, --	6987	Line Durivage
										--702402	, --	70067	Véronic Bénard
										----500292	, --	7361	Myriam Derome
										--676177	 --	7923	Amélie Rancourt-Fortin										
										----,655109	 --	7862	Anne LeBlanc-Levesque
										) THEN 'ADJ'

							WHEN V.RepID in (SELECT RepID_Corpo FROM tblREPR_Lien_Rep_RepCorpo) THEN '' -- rep corpo qui sortent avec des cotisations

							WHEN v.RepID in (SELECT RepID FROM #ListeDirecteur) THEN '' -- les 4 directeur

							--WHEN v.RepCode in ('7036','6070','6262'	,'5852') THEN '' -- les 4 directeur

							WHEN R.BusinessStart >= DATEADD(YEAR,-4,@EndDate)	THEN 'TMP_0_48'
							WHEN R.BusinessStart < DATEADD(YEAR,-4,@EndDate)	THEN 'TMP_49_'
							END,
		StartDate = CAST(@StartDate AS DATE),
		EndDate = CAST(@EndDate AS DATE),
		Weekno = ISNULL(Weekno,0)
		
	INTO #table1 -- DROP TABLE #table1

	FROM (

		select 
			U.UnitID,
			Semaine.RepID,
			--Recrue,
			RREP.RepCode,
			RepCodeDirecteur = ISNULL(BREP.RepCode,'nd'),
			--NomRep = HREP.FirstName + ' ' + HREP.LastName,
			PrenomRep = HREP.FirstName,
			NomRep = HREP.LastName,
			
			--RREP.BusinessStart,
			Directeur = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			Net = (Brut - Retraits + reinscriptions),
			NetPrec = 0,
			Cumul = 0,
			CumulPrec = 0
			

			,Cotis = 0
			,CotisPrec = 0
			,CotisCumul = 0
			,CotisCumulPrec = 0
			
		from 
			#GNUSemaine Semaine
			JOIN dbo.Un_Unit U on U.UnitID = Semaine.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Semaine.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Semaine.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL 
		
		select 
			U.UnitID,
			SemainePrec.RepID,
			--Recrue,
			RREP.RepCode,
			RepCodeDirecteur = ISNULL(BREP.RepCode,'nd'),
			--NomRep = HREP.FirstName + ' ' + HREP.LastName,
			PrenomRep = HREP.FirstName,
			NomRep = HREP.LastName,
			--RREP.BusinessStart,
			Directeur = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			Net = 0,
			NetPrec = (Brut - Retraits + reinscriptions),
			Cumul = 0,
			CumulPrec = 0
			

			,Cotis = 0
			,CotisPrec = 0
			,CotisCumul = 0
			,CotisCumulPrec = 0

		from 
			#GNUSemainePrec SemainePrec
			JOIN dbo.Un_Unit U on U.UnitID = SemainePrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = SemainePrec.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = SemainePrec.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL 
		
		select 
			U.UnitID,
			Cumul.RepID,
			--Recrue,
			RREP.RepCode,
			RepCodeDirecteur = ISNULL(BREP.RepCode,'nd'),
			--NomRep = HREP.FirstName + ' ' + HREP.LastName,
			PrenomRep = HREP.FirstName,
			NomRep = HREP.LastName,
			--RREP.BusinessStart,
			Directeur = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			Net = 0,
			NetPrec = 0,
			Cumul = (Brut - Retraits + reinscriptions),
			CumulPrec = 0
			

			,Cotis = 0
			,CotisPrec = 0
			,CotisCumul = 0
			,CotisCumulPrec = 0

		from 
			#GNUCumul Cumul
			JOIN dbo.Un_Unit U on U.UnitID = Cumul.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = Cumul.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = Cumul.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID
		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0
		
		UNION ALL 
		
		select 
			U.UnitID,
			CumulPrec.RepID,
			--Recrue,
			RREP.RepCode,
			RepCodeDirecteur = ISNULL(BREP.RepCode,'nd'),
			--NomRep = HREP.FirstName + ' ' + HREP.LastName,
			PrenomRep = HREP.FirstName,
			NomRep = HREP.LastName,
			--RREP.BusinessStart,
			Directeur = ISNULL(HBoss.FirstName + ' ' + HBoss.LastName,'ND'),
			Net = 0,
			NetPrec = 0,
			Cumul = 0,
			CumulPrec = (Brut - Retraits + reinscriptions)
			

			,Cotis = 0
			,CotisPrec = 0
			,CotisCumul = 0
			,CotisCumulPrec = 0

		from 
			#GNUCumulPrec CumulPrec
			JOIN dbo.Un_Unit U on U.UnitID = CumulPrec.UnitID
			JOIN dbo.Un_Convention C ON	C.Conventionid = U.ConventionID
			JOIN dbo.Mo_Human HS on HS.humanid = C.subscriberid
			JOIN UN_REP RREP on RREP.RepID = CumulPrec.RepID
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
			LEFT JOIN UN_REP BREP on BREP.RepID = CumulPrec.BossID
			LEFT JOIN dbo.Mo_Human HBoss on HBoss.HumanID = BREP.RepID

		where Brut <> 0 OR Retraits <> 0 OR Reinscriptions <> 0

		UNION ALL

		SELECT 
			UnitID = 0,
			ct.RepID,
			--ct.Recrue,
			ct.RepCode,
			ct.RepCodeDirecteur,
			ct.PrenomRep,
			ct.NomRep,
			--r.BusinessStart,
			ct.Directeur,

			Net = 0,
			NetPrec = 0,
			Cumul = 0,
			CumulPrec = 0


			,Cotis = ct.EpargneEtFrais
			,CotisPrec = ct.EpargneEtFraisPREC
			,CotisCumul = ct.EpargneEtFraisCumul
			,CotisCumulPrec = ct.EpargneEtFraisCumulPREC

		FROM #Cotisation ct 
		join Un_Rep r on r.RepID = ct.RepID


		--- Tous les rep actif
		-- Valeurs à zéro pour tous les rep actif pour qu'ils sortent même si aucune vente à date
		UNION ALL 
		
		SELECT 
			UnitID = 0,
			RepID = RREP.RepID,
			RREP.RepCode,
			RepCodeDirecteur = '',
			PrenomRep = HREP.FirstName,
			NomRep = HREP.LastName,
			Directeur = '',
			Net = 0,
			NetPrec = 0,
			Cumul = 0,
			CumulPrec = 0
			

			,Cotis = 0
			,CotisPrec = 0
			,CotisCumul = 0
			,CotisCumulPrec = 0

		FROM  
			UN_REP RREP
			JOIN dbo.Mo_Human HREP on HREP.HumanID = RREP.RepID
		WHERE ISNULL(RREP.BusinessEnd,'9999-12-31') > @EndDate

		
		) V
	
	JOIN #BossRepActuel M ON V.RepID = M.RepID
	JOIN dbo.Mo_Human B ON B.HumanID = M.BossID
	JOIN Un_Rep RB ON RB.RepID = M.BossID
	JOIN #tUn_Rep R on R.RepID = V.repID
	LEFT JOIN (
		select 
			V.DateFinPeriode,
			V.Weekno
		from (
			select 
				DateFinPeriode = max(DateFinPeriode),
				Weekno = max(Weekno)
			from #TMPObjectifBulletin
			where DateFinPeriode <= @EndDate
			) V
		join #TMPObjectifBulletin OB ON V.DateFinPeriode = OB.DateFinPeriode
		) TMPObjectifBulletin ON TMPObjectifBulletin.DateFinPeriode = @EndDate

	WHERE 
		V.repid not in (
			SELECT RepID FROM #ListeRepSiegeSocial
			)

	group by
	
		V.RepID,
		PrenomRep,
		NomRep,
		V.RepCode,
		V.RepCodeDirecteur,RB.RepCode, 
		R.BusinessStart,
		R.BusinessEnd, --case when isnull(R.BusinessEnd,'3000-01-01') > @EndDate then 1 else 0 end,
		B.FirstName,B.LastName,
		RB.RepID,
		V.Directeur,
		isnull(Weekno,0)

	order by
	 	V.RepID
	
	--SELECT * FROM #table1 -- drop table #table1



--	SELECT * FROM #table1 WHERE REPID = 629154

	SELECT 
		Numero =				ROW_NUMBER() OVER (PARTITION BY REPLACE(Categorie,'TMP_','')		  ORDER BY				   SUM(PointCumul)  DESC),

		-- ON CALCULE LA POSITION 0 DES RECRUE, LE RESTE EST EN DOUBLE POUR LES 0_48. ALORS ON VA LES RECALCULER JUSTE APRÈS POUR LES POSITIONs 1 À N des non recrues
		NumeroPourPhoto =	CASE 
							WHEN recrue = 1 THEN 
								ROW_NUMBER() OVER (PARTITION BY REPLACE(Categorie,'TMP_',''), recrue  ORDER BY SUM(Point) DESC,SUM(PointCumul)  DESC) - 1 
							ELSE 
								ROW_NUMBER() OVER (PARTITION BY REPLACE(Categorie,'TMP_',''), recrue  ORDER BY SUM(Point) DESC,SUM(PointCumul)  DESC)
							END
							,


		RepID,	
		PrenomRep,
		NomRep,
		Recrue,	
		RepCode,	
		RepCodeDirecteur = '',	
		BusinessStart,	
		RepIsActive,	
		DirecteurActuel,	
		DirecteurActuelRepID,	
		Net = SUM(Net),	
		NetPrec = SUM(NetPrec),	
		Cumul = SUM(Cumul),	
		CumulPrec = SUM(CumulPrec),	

		Cotis = SUM(Cotis),
		CotisPrec = SUM(CotisPrec),
		CotisCumul = SUM(CotisCumul),
		CotisCumulPrec = SUM(CotisCumulPrec),

		Point = SUM(Point),
		PointPrec = SUM(PointPrec),
		PointCumul = SUM(PointCumul),
		PointCumulPrec = SUM(PointCumulPrec),

		Categorie = REPLACE(Categorie,'TMP_',''),
		Weekno,	
		StartDate,
		EndDate,
		Diviseur = @Diviseur

	INTO #FINAL
	FROM 
		#table1
	WHERE 
			RepIsActive = 1
		AND Categorie <> ''
	GROUP BY	 
		RepID,	
		PrenomRep,
		NomRep,
		Recrue,	
		RepCode,	
		--RepCodeDirecteur,	
		BusinessStart,	
		RepIsActive,	
		DirecteurActuel,	
		DirecteurActuelRepID,
		Weekno,		
		StartDate,
		EndDate,
		REPLACE(Categorie,'TMP_','')
	ORDER BY Categorie,recrue,SUM(Net) DESC,SUM(Cumul) DESC

	--ON RECALCULE LES POSITIONS 1 À N des non recrues dans 0_48
	UPDATE F 
	SET F.NumeroPourPhoto = FF.NumeroPourPhoto2
	FROM #FINAL F
	JOIN (
		SELECT RepID,PrenomRep,NomRep, NumeroPourPhoto2 =	ROW_NUMBER() OVER (/*PARTITION BY  */  ORDER BY Point DESC,PointCumul  DESC)
		FROM #FINAL
		WHERE 
			NumeroPourPhoto > 0 -- on commence après la position 0 qui est la recrue no 1
			AND Categorie = '0_48'
		)FF on F.RepID = FF.RepID


	--SELECT * FROM #FINAL -- drop table #FINAL


	INSERT INTO #FINAL -- DROP TABLE #FINAL
	SELECT 

		Numero = ROW_NUMBER() OVER (/*partition by*/ ORDER BY SUM(PointCumul) DESC),

		-- Ce numéro n'est pas pour la photo mais je me sert de ce champs quand même. il sert à détermner celui qui a le plus de point dans la semaine
		NumeroPourPhoto = ROW_NUMBER() OVER (/*partition by*/ ORDER BY SUM(Point) DESC), 
		RepID = 0,
		PrenomRep = '',
		NomRep = DirecteurActuel, --Directeur, On associe toutes les vente et résil au directeur actuel et non au directeur de la vente, pour les rep actif : S Robinson et Nadia Marcoux 2018-04-20
		Recrue = 0,
		RepCode = '',
		RepCodeDirecteur = '',
		BusinessStart = NULL,
		RepIsActive = 0,
		DirecteurActuel = '',
		DirecteurActuelRepID = 0,

		Net = SUM(Net),
		NetPrec = SUM(NetPrec),
		Cumul =  SUM(Cumul),
		CumulPrec = SUM(CumulPrec),

		Cotis = SUM (Cotis),
		CotisPrec = SUM (CotisPrec),
		CotisCumul = SUM (CotisCumul),
		CotisCumulPrec = SUM (CotisCumulPrec),

		Point = SUM(Point),
		PointPrec = SUM(PointPrec),
		PointCumul = SUM(PointCumul),
		PointCumulPrec = SUM(PointCumulPrec),

		Categorie = 'DIR',
		Weekno,
		StartDate,
		EndDate,
		Diviseur = @Diviseur

	FROM 
		#table1 
	WHERE 
		DirecteurReconnu = 1
		AND RepIsActiveDuringPeriod = 1
		--AND RepIsActive = 1
	GROUP BY 
		DirecteurActuel,
		Weekno,
		StartDate,
		EndDate
	

	SELECT 
		Numero ,

		-- Ce numéro n'est pas pour la photo mais je me sert de ce champs quand même. il sert à détermner celui qui a le plus de point dans la semaine
		NumeroPourPhoto, 
		RepID,
		PrenomRep,
		NomRep, --Directeur, On associe toutes les vente et résil au directeur actuel et non au directeur de la vente, pour les rep actif : S Robinson et Nadia Marcoux 2018-04-20
		Recrue,
		RepCode,
		RepCodeDirecteur,
		BusinessStart,
		RepIsActive,
		DirecteurActuel,
		DirecteurActuelRepID,

		Net,
		NetPrec,
		Cumul,
		CumulPrec,

		Cotis,
		CotisPrec,
		CotisCumul,
		CotisCumulPrec,

		Point,
		PointPrec,
		PointCumul,
		PointCumulPrec,

		Categorie,
		Weekno,
		StartDate,
		EndDate,
		Diviseur,
		DirecteurActuelAbrege = 
			SUBSTRING(DirecteurActuel,1,1 ) + -- 1ere lettre du prénom
			'. ' +
			SUBSTRING (DirecteurActuel,
						PATINDEX ('% %',DirecteurActuel ) + 1, -- le reste du nom qui suit l'espace
						500 
					  )		 	
	 
	FROM #FINAL



	



set arithabort off	
		
END