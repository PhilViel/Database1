
/****************************************************************************************************
Code de service		:		psREPR_RapportDeVenteEtCommission_Sommaire
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

select	 * from un_def

EXEC psREPR_RapportDeVenteEtCommission_Sommaire_jira_ti_12642
					@StartDate = '2017-01-01', -- Date de début
					@EndDate = '2017-05-14', -- Date de fin
					@RepID = 476221
					,@Type = 'REP'


EXEC psREPR_RapportDeVenteEtCommission_Sommaire_jira_ti_12642
					@StartDate = '2018-01-01', -- Date de début
					@EndDate = '2018-05-13', -- Date de fin
					@RepID = 476221
					,@Type = 'REP'
					


SELECT *
from Mo_Human h
join uN_rep r on r.RepID = h.HumanID
where h.LastName like '%larocq%'

Parametres de sortie : Table						Champs										Description
					   -----------------			---------------------------					--------------------------


Historique des modifications :			
						Date		Programmeur			Description							Référence
						2017-08-29	Donald Huppé		Création du service
						2017-10-31	Donald Huppé		retirer : Nombre d''unités souscrites avec assurance
						2017-11-08	Donald Huppé		modifier des libellés
						2017-11-13	Donald Huppé		Correction du marketing
						2017-12-08	Donald Huppé		remettre : Nombre d''unités souscrites avec assurance
						2017-12-28	Donald Huppé		jira ti-10224 : changer libellé des RES et ajout du net 52 semaines
 ****************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportDeVenteEtCommission_Sommaire_jira_ti_12642]
	(	
	@StartDate		DATETIME,
	@EndDate		DATETIME,
	@RepID			INT,
	@Type			VARCHAR(3),
	@vcLangID		VARCHAR(3) = 'FRA'
    )
AS
	BEGIN

	DECLARE @DateFin DATETIME
	SET @DateFin = @EndDate
	DECLARE @StartDate52 DATETIME
	SET @StartDate52 =  DATEADD(DAY,-363,@DateFin)

	CREATE TABLE #Dataset_Sommaire (
		Sort FLOAT,
		GroupeID VARCHAR(20),
		LaDescription VARCHAR(150),
		Valeur FLOAT,
		ValeurTXT  VARCHAR (50),
		TypeValeur VARCHAR (15),
		CouleurDETAIL VARCHAR (30)

		)

	CREATE TABLE #Groupe (
		GroupeID VARCHAR(20),
		GroupeEntete VARCHAR (100),
		CouleurHEADER VARCHAR (30),
		CouleurFOOTER VARCHAR (30)
		)	

	INSERT INTO #Groupe values (1,'Ajouts',					/*VERT FONCÉ*/	'#bdd758',/*VERT PALE*/	'#e9f2ca')
	INSERT INTO #Groupe values (2,'Ajustements des unités',	/*VERT PALE*/	'#e9f2ca',				'No Color')
	INSERT INTO #Groupe values (3,'Commissions',			/*BLEU FONCÉ*/	'#55a8d8',/*BLEU PALE*/	'#d4effc')
	INSERT INTO #Groupe values (4,'Ajustements',			/*BLEU PALE*/	'#d4effc',				'No Color')
	INSERT INTO #Groupe values (5,'Autres informations',	/*GRIS*/		'#c3bfbf',				'No Color')


	CREATE table #Dataset (

		EstDirecteur INT,
        RepCode VARCHAR(15),
		Representant VARCHAR(200),
		ConventionNo VARCHAR(30),
		UnitID INT,
		Regime VARCHAR(30),
		DateNaissanceBenef DATETIME,
		SubscriberID INT,
		BeneficiaryID INT,
		NomSouscripteur VARCHAR(200),
		NouveauClient VARCHAR(10),
		TelSousc VARCHAR(30),
		CodePostalSousc VARCHAR(15),
		DateDebutOperFin DATETIME,
		Date1erDepot DATETIME,
		NbUniteActuel FLOAT,
		UniteAssure FLOAT,
		FraisCumululatif MONEY,
		NiveauRep1erDepot VARCHAR(100),

		Brut FLOAT,
		Reinscriptions FLOAT,
		Retraits_Partiel FLOAT,
		Retraits FLOAT,
		Net FLOAT,
		TFR FLOAT,
		Retraits_NON_ReduitTaux FLOAT,

		RepID_COM INT,
		RepCOM VARCHAR(200),
		RepRoleDesc VARCHAR(100),
		PeriodAdvance MONEY,
		CoverdAdvance MONEY,
		PeriodAdvanceResiliation MONEY,
		CumAdvance MONEY,
		ServiceComm MONEY,
		PeriodComm MONEY,
		PeriodCommResiliation MONEY,
		FuturComm MONEY,
		BusinessBonus MONEY,
		PeriodBusinessBonus MONEY,
		FuturBusinessBonus MONEY,
		mEpargne_SoldeDebutActif MONEY,
		mEpargne_PeriodeActif MONEY,
		mEpargne_SoldeFinActif MONEY,
		mEpargne_CalculActif MONEY,
		dTaux_CalculActif MONEY,
		mMontant_ComActif MONEY,
		mEpargne_SoldeDebutSuivi MONEY,
		mEpargne_PeriodeSuivi MONEY,
		mEpargne_SoldeFinSuivi MONEY,
		mEpargne_CalculSuivi MONEY,
		dTaux_CalculSuivi MONEY,
		mMontant_ComSuivi MONEY,
		BusinessBonusToPay INT
		)

	INSERT INTO #Dataset
	EXEC psREPR_RapportDeVenteEtCommission
				@StartDate,
				@EndDate,
				@RepID,
				@Type,
				@Data_DetailOuSommaire = 'D'


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



	INSERT #GrossANDNetUnits
	EXEC SL_UN_RepGrossANDNetUnits
		@ReptreatmentID = NULL, 
		@StartDate = @StartDate52,
		@EndDate = @DateFin,
		@RepID = 0,
		@ByUnit = 1
		



	SELECT 
		gnu.RepID,
		NomRep = HR.FirstName  + ' ' + HR.LastName,
		R.RepCode,
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
					END
		,UniteNettes52Sem = round(sum((Brut) - ( (Retraits) - (Reinscriptions) )),3)
	INTO #TAUXCONS
	FROM 
		#GrossANDNetUnits GNU
		JOIN UN_REP R ON R.RepID = GNU.RepID
		JOIN Mo_Human HR ON HR.HumanID = GNU.RepID
	--where GNU.BossID = @RepID
	GROUP BY 
		GNU.RepID,
		HR.FirstName,
		HR.LastName,
		R.RepCode


	SELECT 
		gnu.BossID,
		NomRep = HR.FirstName  + ' ' + HR.LastName,
		R.RepCode,
		ConsPct =	CASE
						WHEN SUM(Brut24) <= 0 THEN 0
						ELSE (sum(Brut24 - Retraits24 + Reinscriptions24) / SUM(Brut24)) * 100
					END
	INTO #TAUXCONS_DIR
	FROM 
		#GrossANDNetUnits GNU
		JOIN UN_REP R ON R.RepID = GNU.BossID
		JOIN Mo_Human HR ON HR.HumanID = GNU.BossID
	where GNU.BossID = @RepID
	GROUP BY 
		GNU.BossID,
		HR.FirstName,
		HR.LastName,
		R.RepCode


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 10, 
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN 'Nombre de plans' ELSE 'Nombre de plans' END, 
		Valeur = SUM(CASE WHEN Brut > 0 OR Reinscriptions > 0 OR TFR > 0 THEN 1 ELSE 0 END)  ,
		ValeurTXT = ''
		,TypeValeur = 'F0'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE (Brut > 0 OR Reinscriptions > 0 OR TFR > 0)

	

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 20,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN 'Nombre de bénéficiaires' ELSE  'Nombre de bénéficiaires' END,  
		Valeur = COUNT(DISTINCT BeneficiaryID )  ,
		ValeurTXT = ''
		,TypeValeur = 'F0'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE (Brut > 0 OR Reinscriptions > 0 OR TFR > 0)


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 30,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN 'Âge moyen des bénéficiaires' ELSE  'Âge moyen des bénéficiaires' END,  
		Valeur = 
					CASE WHEN (SELECT count(*) FROM #Dataset WHERE Brut > 0 OR Reinscriptions > 0 OR TFR > 0) <> 0
					THEN
							SUM(dbo.fn_Mo_Age(DateNaissanceBenef,Date1erDepot))  
								/ 
									(
										(SELECT count(*) FROM #Dataset WHERE Brut > 0 OR Reinscriptions > 0 OR TFR > 0) *1.0 -- POUR QUE LE COUNT DEVIENNE FLOAT
									) 
					ELSE 0 
					END				
							
							,
		ValeurTXT = ''
		,TypeValeur = 'F1'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Brut > 0 OR Reinscriptions > 0 or TFR > 0


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 35,  
		GroupeID =  1, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Moyenne d''unités vendues par plan' END,  
		Valeur = 
			CASE WHEN (SELECT count(*) FROM #Dataset WHERE Brut > 0 OR Reinscriptions > 0 OR TFR > 0) <> 0
			THEN
					SUM(Brut + Reinscriptions + TFR) / 
							(
								(SELECT count(*) FROM #Dataset WHERE Brut > 0 OR Reinscriptions > 0 OR TFR > 0) 
							) 
			ELSE 0
			END				
							,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 40,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités <i>REEE</i>FLEX souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0)	 ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Regime = 'Reeeflex'

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 50,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités UNIVERSITAS souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0) ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Regime = 'Universitas'

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 60,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités INDIVIDUEL souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0)	 ,
		ValeurTXT = ''	
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Regime = 'Individuel'

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 70,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités T souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0) ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Regime = 'Individuel-T'

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 80,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités BEC souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0)	 ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	WHERE Regime = 'Individuel-IBEC'


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 89,  
		GroupeID =  1,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Total des unités brutes souscrites' END,  
		Valeur = ISNULL(SUM(Brut),0)	 ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset 
	

	-------------------------------------------   2  Début  ----------------------------------------------------

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 90,  
		GroupeID =  2,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE 'Résiliations sans impact sur les unités nettes'  /*'Résiliations - 60 jours' */ END,  
		Valeur = SUM(Retraits_NON_ReduitTaux)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 100,  
		GroupeID =  2,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Réductions' END,  
		Valeur = SUM(Retraits_Partiel)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 110,   
		GroupeID =  2,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE 'Résiliations' /*'Résiliations + 60 jours'*/ END,  
		Valeur = SUM(Retraits)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 115,   
		GroupeID =  2,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Réinscriptions' END,  
		Valeur = SUM(Reinscriptions)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#e9f2ca' --VERT PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 120,   
		GroupeID =  2,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Total des unités nettes souscrites' END,  
		Valeur = SUM(Net)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = '#bdd758' --VERT FONCÉ
	FROM #Dataset




-------------------------------------------   2  FIN  ----------------------------------------------------



	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 200,   
		GroupeID =  3,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Avances de commissions' END,  
		Valeur = SUM(PeriodAdvance)   ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 210,    
		GroupeID =  3,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Commissions de service' END,  
		Valeur = SUM(PeriodComm)  ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 220 ,    
		GroupeID =  3,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Ristournes d''assurance' END,  
		Valeur = SUM(PeriodBusinessBonus) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT
		Sort = 230,   
		GroupeID =  3, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Commission sur l''épargne' END,  
		Valeur = SUM(CS.mMontant_ComActif),
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM [dbo].[VtblREPR_CommissionsSurActif_Conv] CS
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CS.RepTreatmentID
	WHERE CS.RepID = @RepID
		AND RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
	HAVING ISNULL(SUM(CS.mMontant_ComActif),0) <> 0


	INSERT INTO #Dataset_Sommaire
	SELECT
		Sort = 240,   
		GroupeID =  3, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Commissions de suivi' END,  
		Valeur = SUM(CS.mMontant_ComActif),
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM [dbo].[VtblREPR_CommissionsSuivi_Conv] CS
	JOIN Un_RepTreatment RT ON RT.RepTreatmentID = CS.RepTreatmentID
	WHERE CS.RepID = @RepID
		AND RT.RepTreatmentDate BETWEEN @StartDate AND @EndDate
	HAVING ISNULL(SUM(CS.mMontant_ComActif),0) <> 0


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 250 ,   
		GroupeID =  3, 
		LaDescription =  CT.RepChargeTypeDesc,  
		Valeur = SUM(C.RepChargeAmount) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM 
		Un_RepCharge C
		JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
	WHERE 1=1
		AND C.RepID = @RepID
		AND C.RepChargeTypeID NOT IN ('AVR','AVS')
		AND RepChargeDate BETWEEN @StartDate AND @EndDate
	GROUP BY CT.RepChargeTypeDesc




	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 260,    
		GroupeID =  3,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Total des commissions brutes' END, 
		Valeur = (SELECT SUM(VALEUR) FROM #Dataset_Sommaire WHERE Sort BETWEEN 200 AND 260)  , 
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	


	----------------------------------------------------------------------------------------------------------------



	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 300,    
		GroupeID =  4,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Résiliations et autres en dollars' END,  
		Valeur = SUM(PeriodAdvanceResiliation + PeriodCommResiliation)  ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM #Dataset


	--Avances spéciales - Période
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 310 ,   
		GroupeID =  4, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE   'Avances spéciales' END,  
		Valeur = SUM(C.RepChargeAmount) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM 
		Un_RepCharge C
		JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
	WHERE 1=1
		AND C.RepID = @RepID
		AND C.RepChargeTypeID = 'AVS'
		AND RepChargeDate BETWEEN @StartDate AND @EndDate
	HAVING ISNULL(SUM(C.RepChargeAmount),0) <> 0


	--Avances sur résiliations - période
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 320 ,   
		GroupeID =  4, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE   'Avance sur résiliation' END,  
		Valeur = SUM(C.RepChargeAmount) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#d4effc' --BLEU PALE
	FROM 
		Un_RepCharge C
		JOIN Un_RepChargeType CT ON CT.RepChargeTypeID = C.RepChargeTypeID
	WHERE 1=1
		AND C.RepID = @RepID
		AND C.RepChargeTypeID = 'AVR'
		AND RepChargeDate BETWEEN @StartDate AND @EndDate
	HAVING ISNULL(SUM(C.RepChargeAmount),0) <> 0


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 330,    
		GroupeID =  4,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Total des commissions nettes' END,  
		Valeur = (SELECT SUM(VALEUR) FROM #Dataset_Sommaire WHERE Sort BETWEEN 260 AND 330)  ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = '#55a8d8' --BLEU FONCÉ


 ----------------------------------------------------------------------------------------------------------------------------------


 

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 400,  
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Transferts de frais en unité' END,  
		Valeur = SUM(TFR)  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = 'No Color'
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 410,  
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Nombre d''unités souscrites avec assurance' END,  
		--Valeur = SUM(CASE WHEN UniteAssure > 0 THEN D.Brut + D.TFR ELSE 0 END) ,
		Valeur = SUM(CASE WHEN D.Brut > 0 or D.TFR > 0 THEN UniteAssure ELSE 0 END) ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = 'No Color'
	FROM #Dataset D


	--Avances spéciales - Période
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 420 ,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE   'Solde d''avances spéciales' END,  
		Valeur = ISNULL(SUM(sa.Amount),0) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = 'No Color'
	FROM Un_SpecialAdvance SA
	WHERE RepID = @RepID
		AND EffectDate <= @EndDate   
	



	--Avances sur résiliations - période
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 430 ,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE   'Solde d''avances sur résiliation' END,  
		Valeur = ISNULL(SUM(RepChargeAmount),0) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = 'No Color'
	FROM Un_RepCharge 
	WHERE RepID = @RepID
		AND RepChargeTypeID = 'AVR'  
		AND RepChargeDate <= @EndDate


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 440,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Solde d''avances à couvrir' END,  
		Valeur = SUM(CumAdvance) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = 'No Color'
	FROM #Dataset



	------------------------------------------------
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 450,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Commissions à venir' END,  
		Valeur = SUM(FuturComm) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = 'No Color'
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 460,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Ristournes d''assurance à venir' END,  
		Valeur = SUM(FuturBusinessBonus) ,
		ValeurTXT = ''
		,TypeValeur = 'C2'
		,CouleurDETAIL = 'No Color'
	FROM #Dataset


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 470,   
		GroupeID =  5,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Ratio nouveau client : client existant' END, 
		Valeur =
			CASE WHEN (SELECT count(*) FROM #Dataset WHERE (Brut > 0 OR Reinscriptions > 0 OR TFR > 0) AND NouveauClient = 'Non')  <> 0
			THEN
				(COUNT(*) * 1.0)
					/ 
				(SELECT count(*) FROM #Dataset WHERE (Brut > 0 OR Reinscriptions > 0 OR TFR > 0) AND NouveauClient = 'Non') 
			ELSE 0
			END 				
					, 
		ValeurTXT =  

					CAST (COUNT(*)  AS VARCHAR(10))

					+ '	: ' +
					
					CAST (
							(SELECT count(*) FROM #Dataset WHERE (Brut > 0 OR Reinscriptions > 0 OR TFR > 0) AND NouveauClient = 'Non') 
							AS VARCHAR(10)
						 )

		,TypeValeur = 'TEXT'
		,CouleurDETAIL = 'No Color'

	FROM #Dataset
	WHERE (Brut > 0 OR Reinscriptions > 0 or TFR > 0) AND NouveauClient = 'Oui'


	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 480,   
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Ratio avances sur résiliations'  END,  
		--avance spéciale(420) + avance à couvrir(440) + avance sur résil (430))/(Avance à couvrir(440) +commissions à venir(450)
		Valeur = 
					(
					case when (SELECT SUM(VALEUR) FROM #Dataset_Sommaire WHERE Sort in (440,450) )  <> 0 then
						(SELECT SUM(VALEUR) FROM #Dataset_Sommaire WHERE Sort in (420,430,440) )
						/
						(SELECT SUM(VALEUR) FROM #Dataset_Sommaire WHERE Sort in (440,450) ) 
					else 0
					end
					)

				,
		ValeurTXT = ''
		,TypeValeur = 'P1'
		,CouleurDETAIL = 'No Color'




	-- Taux du REP
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 490,  
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Taux de conservation 24 mois' END,  
		Valeur = ROUND(ConsPct,2)/100.0  ,
		ValeurTXT = ''
		,TypeValeur = 'P2'
		,CouleurDETAIL = 'No Color'
	FROM #TAUXCONS 
	WHERE RepID = @RepID
		AND EXISTS (SELECT 1 FROM #Dataset WHERE EstDirecteur = 0)


	-- Taux du directeur
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 495,   
		GroupeID =  5,
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Taux de conservation 24 mois' END,  
		Valeur = ROUND(ConsPct,2)/100  ,
		ValeurTXT = ''
		,TypeValeur = 'P2'
		,CouleurDETAIL = 'No Color'
	FROM #TAUXCONS_DIR 
	WHERE BossID = @RepID
		AND EXISTS (SELECT 1 FROM #Dataset WHERE EstDirecteur = 1)


	-- Total des unités nettes souscrites 12 derniers mois
	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 500,  
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'Total des unités nettes souscrites 12 derniers mois' END,  
		Valeur = UniteNettes52Sem  ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = 'No Color'
	FROM #TAUXCONS 
	WHERE RepID = @RepID
		AND EXISTS (SELECT 1 FROM #Dataset WHERE EstDirecteur = 0)

	INSERT INTO #Dataset_Sommaire
	SELECT 
		Sort = 600,  
		GroupeID =  5, 
		LaDescription = CASE WHEN @vcLangID = 'ND' THEN '' ELSE  'EpargneTotal' END,  
		Valeur = dbo.fnREPR_ObtenirEpargneTotale(@RepID, @EndDate) ,
		ValeurTXT = ''
		,TypeValeur = 'F3'
		,CouleurDETAIL = 'No Color'
	FROM #TAUXCONS 
	WHERE RepID = @RepID
		AND EXISTS (SELECT 1 FROM #Dataset WHERE EstDirecteur = 0)


	--insert into aaatmp_jira_ti_12642
	SELECT 
		--DateDu = @StartDate,
		--DateAu = @EndDate,
		RepID = @RepID,

		--G.GroupeID,
		--G.GroupeEntete,
		S.Sort,
		S.LaDescription,
		S.Valeur
		--S.ValeurTXT,
		--S.TypeValeur,
		--G.CouleurHEADER,
		--S.CouleurDETAIL,
		--G.CouleurFOOTER
	FROM 
		#Dataset_Sommaire S
		JOIN #Groupe G on G.GroupeID = S.GroupeID
	WHERE s.Sort in (
			10,120,
			200,
			210,
			220,
			230,
			240,
			250,
			440,
			450,
			460,
			490,
			600
			)
	ORDER BY 
		G.GroupeID, 
		S.Sort


	--select * from aaatmp_jira_ti_12642
END
