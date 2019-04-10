
/****************************************************************************************************
Code de service		:		psREPR_RapportBoni_2019
Nom du service		:		
But					:		Calcul du boni au rep
Facette				:		REPR 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

select *
from Mo_Human h
join uN_rep r on r.RepID = h.HumanID
where h.LastName = 'mercier'						

Exemple d'appel:

	EXEC psREPR_RapportBoni_2019  '2019-01-01', '2019-01-13'
	EXEC psREPR_RapportBoni_2019  '2018-11-26', '2018-12-31'
		

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------


Historique des modifications :			
						Date		Programmeur			Description							Référence
						2019-01-14	Donald Huppé		Création du service

 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportBoni_2019]
	(	
	@StartDate		DATETIME,
	@EndDate		DATETIME
    )
AS
	BEGIN
	DECLARE @DateDebut DATETIME
	DECLARE @DateFin DATETIME
	DECLARE @StartDate52 DATETIME

	SET @DateDebut = @StartDate
	SET @DateFin = @EndDate
		
	SET @StartDate52 =  DATEADD(DAY,-363,@DateFin)





	CREATE table #critere (NetMIN FLOAT, NetMAX FLOAT, Boni MONEY)
	insert into #critere values (0,		150,	0.0		)
	insert into #critere values (150,	250,	10.0	)
	insert into #critere values (250,	400,	20.0	)
	insert into #critere values (400,	600,	36.0	)
	insert into #critere values (600,	800,	45.0	)
	insert into #critere values (800,	1000,	48.0	)
	insert into #critere values (1000,	1200,	50.0	)
	insert into #critere values (1200,	1500,	53.0	)
	insert into #critere values (1500,	10000,	55.0	)


	CREATE table #critereTransitoire (NetMIN FLOAT, NetMAX FLOAT, Boni MONEY)
	insert into #critereTransitoire values (0,		150,	8.0		)
	insert into #critereTransitoire values (150,	250,	8.0		)
	insert into #critereTransitoire values (250,	400,	10.0	)
	insert into #critereTransitoire values (400,	600,	10.0	)
	insert into #critereTransitoire values (600,	800,	12.0	)
	insert into #critereTransitoire values (800,	1000,	12.0	)
	insert into #critereTransitoire values (1000,	1200,	14.0	)
	insert into #critereTransitoire values (1200,	1500,	14.0	)
	insert into #critereTransitoire values (1500,	10000,	14.0	)



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

							--'7805',  --Steve Blais 
							--'7186',  --Chantal Jobin 
							--'7923',  --Amélie Rabcourt-Fortin 
							--'6158', --carole Marchand 
							--'70067' --Véronic Bénard 



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
		Reinscriptions24 FLOAT,
		DateUnite DATETIME)  

	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits_DateUnite
		@ReptreatmentID = NULL, 
		@StartDate = @StartDate52,
		@EndDate = @DateFin,
		@RepID = 0,
		@ByUnit = 1
		



	SELECT 
		gnu.RepID
		,PrenomRep = HR.FirstName
		,NomRep = HR.LastName
		,R.RepCode
		,R.BusinessStart
		,Recrue = CASE WHEN DATEADD(YEAR,1,R.BusinessStart) > @DateFin THEN 1 ELSE 0 END
		,UniteNettes52Sem = ROUND(SUM((Brut) - ( (Retraits) - (Reinscriptions) )),3)
		,UniteNettesPeriode = ROUND(
							SUM(
								CASE 
									WHEN GNU.DateUnite BETWEEN @StartDate and @DateFin THEN	(Brut) - ( (Retraits) - (Reinscriptions) )
									ELSE 0 
								END
								)
							,3),

		CalculerBoni = CASE WHEN 
									D.RepID		IS NOT NULL -- UN DIRECTEUR 
								OR	DA.RepID	IS NOT NULL -- UN DIRECTEUR ADJOINT

							THEN 0 ELSE 1 END,

		CalculerBoniTransitoire = CASE WHEN 
									D.RepID		IS NOT NULL -- UN DIRECTEUR 

							THEN 0 ELSE 1 END

				 
	INTO #TMP
	FROM 
		#GrossANDNetUnits GNU
		JOIN UN_REP R ON R.RepID = GNU.RepID
		JOIN Mo_Human HR ON HR.HumanID = GNU.RepID
		LEFT JOIN #ListeDirecteur D ON D.RepID = GNU.RepID
		LEFT JOIN #ListeDirecteurAdjoint DA ON DA.RepID = GNU.RepID
	WHERE R.BusinessEnd IS NULL 
		AND R.RepID <> 149772 --Vendeur Non-Actif
	GROUP BY 
		GNU.RepID,
		HR.FirstName,
		HR.LastName,
		R.RepCode,
		R.BusinessStart,
		D.RepID,
		DA.RepID	


	SELECT 
		T.RepID
		,T.PrenomRep
		,T.NomRep
		,T.RepCode
		,RepCodeINT = cast(case when ISNUMERIC(t.repcode) <> 0 then t.repcode else 0 end as int)
		,T.BusinessStart
		,T.Recrue
		,T.UniteNettes52Sem
		,T.UniteNettesPeriode
		--,TauxBoni = ISNULL(c.Boni,0) + CASE WHEN E.RepCode IS NOT NULL THEN 14 ELSE 0 END

		,TauxBoni = CASE 
					WHEN	T.Recrue = 1 
							THEN 20  -- taux des recrues
					ELSE ISNULL(c.Boni,0) 
					END
					* CalculerBoni
					
		,TauxBoni_Transitoire = CASE 
					WHEN	T.Recrue = 1 
							THEN 10  -- taux transitoire des recrues
					ELSE ISNULL(ct.Boni,0) 
					END
					* CalculerBoniTransitoire
					

		,BoniPayé = ROUND( T.UniteNettesPeriode * 
						(
						CASE 
						WHEN T.Recrue = 1 THEN 20  -- taux des recrues
						ELSE ISNULL(c.Boni,0) 
						END

						* CalculerBoni

						)
					,2)
	
		,BoniPayé_Transitoire = ROUND( T.UniteNettesPeriode * 
						(
						CASE 
						WHEN T.Recrue = 1 THEN 10  -- taux des recrues
						ELSE ISNULL(ct.Boni,0) 
						END

						* CalculerBoniTransitoire

						)
					,2)
	
	FROM #TMP t
		LEFT JOIN #critere c on t.UniteNettes52Sem >= c.NetMIN AND t.UniteNettes52Sem < c.NetMAX
		LEFT JOIN #critereTransitoire ct on t.UniteNettes52Sem >= ct.NetMIN AND t.UniteNettes52Sem < ct.NetMAX
	WHERE CalculerBoni = 1 OR CalculerBoniTransitoire = 1

	END
