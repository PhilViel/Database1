/****************************************************************************************************
Code de service		:		psREPR_RapportBoni_2018
Nom du service		:		
But					:		
Facette				:		REPR 
Reférence			:		

Parametres d'entrée :	Parametres					Description
                        ----------                  ----------------

select *
from Mo_Human h
join uN_rep r on r.RepID = h.HumanID
where h.LastName = 'mercier'						

Exemple d'appel:

	EXEC psREPR_RapportBoni_2018  '2018-10-01', '2018-10-31'
		

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------


Historique des modifications :			
						Date		Programmeur			Description							Référence
						2018-01-03	Donald Huppé		Création du service
						2018-01-24	Donald Huppé		Les recrues ont le taux fixe sans additionner l'exception
						2018-01-30	Donald Huppé		Exclure des directeurs adjoints
						2018-02-14	Donald Huppé		Paula Gaudreau est à 20$ jusqu'au mois d'août
						2018-03-19	Donald Huppé		ajout Boni de 5$ par unité nette
						2018-03-20	Donald Huppé		Calculer Boni 5$ par unité pour les directeurs adjoints
						2018-03-23	Donald Huppé		Ajustement
						2018-04-30	Donald Huppé		Retirer 70224 de la liste des exceptions
						2018-07-31	Donald Huppé		Le Boni de 5$ se termine au 2018-12-31 au lieu de 2018-06-24
						2018-08-27	Donald Huppé		Terminer taux fixe (20) de Paula Gaudreau à la fin juillet au lieu de fin août
						2018-11-08	Donald Huppé		JIRA PROD-12879 : Retirer les dir adjoint suivant : Anne Leblanc-Levesque, Line Durivage et Myriam Derome 
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportBoni_2018]
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


/*
0	250	 $-   
250	300	 $10,00 
300	400	 $20,00 
400	600	 $36,00 
600	800	 $45,00 
800	1000	 $48,00 
1000	1200	 $50,00 
1200	1500	 $53,00 
1500	et plus	 $55,00 

*/


	CREATE table #critere (NetMIN FLOAT, NetMAX FLOAT, Boni MONEY)

	insert into #critere values (0,		250,	0.0		)
	insert into #critere values (250,	300,	10.0	)
	insert into #critere values (300,	400,	20.0	)
	insert into #critere values (400,	600,	36.0	)
	insert into #critere values (600,	800,	45.0	)
	insert into #critere values (800,	1000,	48.0	)
	insert into #critere values (1000,	1200,	50.0	)
	insert into #critere values (1200,	1500,	53.0	)
	insert into #critere values (1500,	10000,	55.0	)


	-- table des rep qui ont 14$ de plus en boni
	-- Liste fournie par le responsable du rapport
	CREATE table #Exception (RepCode VARCHAR(15))

	INSERT INTO #Exception values ('7460')
	INSERT INTO #Exception values ('7628')
	INSERT INTO #Exception values ('6508')
	--INSERT INTO #Exception values ('7862')
	INSERT INTO #Exception values ('7051')
	INSERT INTO #Exception values ('6630')
	--INSERT INTO #Exception values ('70224')
	INSERT INTO #Exception values ('70179')
	INSERT INTO #Exception values ('7288')


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
		CalculerBoni = CASE WHEN R.RepCode IN (
								'7036'  -- Sophie Babeux #7036
								,'6070' -- Clément Blais #6070
								,'5852' -- Martin Mercier #5852
								,'6262' -- Michel Maheu #6262
								,'1111' -- Vendeur Non-Actif	Vendeur de l'Ancien Systè
								,'7805' -- Steve Blais
								,'7186' -- Chantal Jobin 
								--,'7862' -- Anne Leblanc Lévesque

								--,'7361'		-- Myriam Derome
								,'7923'		-- Amélie Rancourt-Fortin
								,'70067'	-- Véronic Bénard
								--,'6987'		-- Line Durivage
								,'6158'		-- Carole Marchand 
								)
							THEN 0 ELSE 1 END,

		CalculerBoni_5_DollarsParUnite_PourDirAdjoint = CASE WHEN R.RepCode IN (
							'7805',  --Steve Blais 
							'7186',  --Chantal Jobin 
							--'7361',  --Myriam Derome 
							'7923',  --Amélie Rabcourt-Fortin 
							--'7862',	 --Anne Leblanc-lévesque 
							'6158', --carole Marchand 
							'70067' --Véronic Bénard 
							--,'6987' --Line Durivage 
								)
							THEN 1 ELSE 0 END

				 
	INTO #TMP
	FROM 
		#GrossANDNetUnits GNU
		JOIN UN_REP R ON R.RepID = GNU.RepID
		JOIN Mo_Human HR ON HR.HumanID = GNU.RepID
	WHERE R.BusinessEnd IS NULL


	GROUP BY 
		GNU.RepID,
		HR.FirstName,
		HR.LastName,
		R.RepCode,
		R.BusinessStart


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
						OR	(T.RepCode = '6431 ' AND @DateFin <= '2018-07-30') -- Paula Gaudreau est à 20$ jusqu'à la fin juillet
							THEN 20  -- taux des recrues
					ELSE ISNULL(c.Boni,0) 
					END
					* CalculerBoni
					
					

		,Boni = ROUND( T.UniteNettesPeriode * 
						(
						CASE 
						WHEN	T.Recrue = 1 
							OR	(T.RepCode = '6431 ' AND @DateFin <= '2018-07-30') -- Paula Gaudreau est à 20$ jusqu'à la fin juillet
							THEN 20  -- taux des recrues
						ELSE 
								ISNULL(c.Boni,0) 
							+	CASE WHEN E.RepCode IS NOT NULL THEN 14 ELSE 0 END
						END
						* CalculerBoni
						)

						+
						( --Boni_5_DollarsParUnite
						T.UniteNettesPeriode * 5.0 * (CASE WHEN @DateFin <= '2018-12-31' THEN 1 ELSE 0 END)
						)
						* CASE WHEN (CalculerBoni = 1 OR CalculerBoni_5_DollarsParUnite_PourDirAdjoint = 1) THEN 1 ELSE 0 END
					,2)
		,Excep = CASE WHEN E.RepCode IS NOT NULL AND T.Recrue <> 1 THEN 14 ELSE 0 END
		,Boni_5_DollarsParUnite = 
				T.UniteNettesPeriode 
				* 5.0 
				* (CASE WHEN @DateFin <= '2018-12-31' THEN 1 ELSE 0 END)
				* CASE WHEN (CalculerBoni = 1 OR CalculerBoni_5_DollarsParUnite_PourDirAdjoint = 1) THEN 1 ELSE 0 END

	FROM #TMP t
	LEFT JOIN #critere c on t.UniteNettes52Sem >= c.NetMIN AND t.UniteNettes52Sem < c.NetMAX
	LEFT JOIN #Exception E ON E.RepCode = T.RepCode

	WHERE CalculerBoni = 1 OR CalculerBoni_5_DollarsParUnite_PourDirAdjoint = 1

	END