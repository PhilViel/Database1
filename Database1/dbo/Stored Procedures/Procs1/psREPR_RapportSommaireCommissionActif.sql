/********************************************************************************************************************
Copyrights (c) 2015 Gestion Universitas inc
Nom                 :	psREPR_RapportSommaireCommissionActif
Description         :	Pour le rapport SSRS "RapportSommaireCommissionActif" : permet d'obtenir les commissions sur l'actif
						pour un représentant en particulier pour une année choisi.
Valeurs de retours  :	Dataset 
Note                :	2016-05-26	Maxime Martel			Création
						2017-01-20	Donald Huppé			jira ti-6293 : corriger le calcul du mois et année (année : pas utile) dans le left join () C
exec psREPR_RapportSommaireCommissionActif '2016-12-20', 559035

SrvName=SRVSQLPROD&DbName=Univbase&EndDate=12/20/2016 00:00:00&RepID=559035
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportSommaireCommissionActif] 
	(
	@EndDate DATETIME, 
	@RepID INTEGER
	) 
AS
BEGIN

	DECLARE 
		@dateProgramRemun DATETIME = dbo.fnGENE_ObtenirParametre('CONV_DATE_SIGNATURE_MIN_COMM_ACTIF', GETDATE(), NULL, NULL, NULL, NULL, NULL),
		@xml AS XML,
		@dateCalculDebut DATETIME = CAST(CAST(YEAR(@EndDate) AS VARCHAR) + '-' + CAST(02 AS VARCHAR) + '-' + CAST(1 AS VARCHAR) AS DATETIME),
		@DateCalculFin DATETIME = DATEADD(mm, 1, @endDATe)
	
	SET @xml = CAST(('<X>'+REPLACE((SELECT months FROM sys.syslanguages WHERE alias = 'French'),',' ,'</X><X>')+'</X>') AS XML)
	SELECT 
		N.value('.', 'varchar(20)') AS NomMois, 
		ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS NumMois 
	INTO #tMois
	FROM @xml.nodes('X') AS T(N)


	SELECT DISTINCT 
		NumeroMois = TM.NumMois,
		NomMois = TM.NomMois, 
		Annee = YEAR(@EndDate),
		PrenomRep = R.PrenomRep,
		NomRep = R.NomRep,
		NumeroRep = R.NumeroRep,
		RepID = R.RepID,
		Solde = MAX(ISNULL(C.Solde, 0)) OVER(PARTITION BY TM.numMois, YEAR(@EndDate)),
		SoldeAvantEcheance = 
			CASE WHEN YEAR(@EndDate) > YEAR(GETDATE()) OR (YEAR(@EndDate) = YEAR(GETDATE()) AND TM.NumMois > MONTH(GETDATE())-1) 
			THEN NULL 
			ELSE 
				CASE WHEN YEAR(@EndDate) < YEAR(@dateProgramRemun) OR (YEAR(@EndDate) = YEAR(@dateProgramRemun) AND TM.numMois < MONTH(@dateProgramRemun)) 
				THEN NULL 
				ELSE 
					MAX(ISNULL(C.SommeEpargneMoyenAvantEcheance, 0)) OVER(PARTITION BY TM.NumMois, YEAR(@EndDate)) 
				END 
			END,
		SoldeApresEcheance = 
			CASE WHEN YEAR(@EndDate) > YEAR(GETDATE()) OR (YEAR(@EndDate) = YEAR(GETDATE()) AND TM.NumMois > MONTH(GETDATE())-1)  
			THEN NULL 
			ELSE 
				CASE WHEN YEAR(@EndDate) < YEAR(@dateProgramRemun) OR (YEAR(@EndDate) = YEAR(@dateProgramRemun) AND TM.numMois < MONTH(@dateProgramRemun))  
				THEN NULL 
				ELSE 
					MAX(ISNULL(C.SommeEpargneMoyenApresEcheance, 0)) OVER(PARTITION BY TM.NumMois, YEAR(@EndDate))
				END 
			END,
		SommeAvantEcheance = 
			CASE WHEN YEAR(@EndDate) > YEAR(GETDATE()) OR (YEAR(@EndDate) = YEAR(GETDATE()) AND TM.NumMois > MONTH(GETDATE())-1) 
			THEN NULL 
			ELSE 
				CASE WHEN YEAR(@EndDate) < YEAR(@dateProgramRemun) OR (YEAR(@EndDate) = YEAR(@dateProgramRemun) AND TM.numMois < MONTH(@dateProgramRemun)) 
				THEN NULL 
				ELSE 
					MAX(ISNULL(C.SommeAvantEcheance, 0)) OVER(PARTITION BY TM.NumMois, YEAR(@EndDate))
				END 
			END,
		SommeApresEcheance = 
			CASE WHEN YEAR(@EndDate) > YEAR(GETDATE()) OR (YEAR(@EndDate) = YEAR(GETDATE()) AND TM.NumMois > MONTH(GETDATE())-1)  
			THEN NULL 
			ELSE 
				CASE WHEN YEAR(@EndDate) < YEAR(@dateProgramRemun) OR (YEAR(@EndDate) = YEAR(@dateProgramRemun) AND TM.numMois < MONTH(@dateProgramRemun))  
				THEN NULL 
				ELSE 
					MAX(ISNULL(C.SommeApresEcheance, 0)) OVER(PARTITION BY TM.NumMois, YEAR(@EndDate))
				END 
			END,
		Statut = R.Statut
	FROM #tMois TM
	LEFT JOIN (
		SELECT 
			Mois = MONTH(DATEADD(MONTH,-1,CSA.dDate_Calcul)),--MONTH(CSA.dDate_Calcul)-1, --2017-01-20
			Année =  YEAR(DATEADD(MONTH,-1,CSA.dDate_Calcul)),--YEAR(CSA.dDate_Calcul), --2017-01-20
			Solde = SUM(CSA.mEpargneCalcul) OVER(PARTITION BY MONTH(CSA.dDate_Calcul), YEAR(CSA.dDate_Calcul)),
			SommeEpargneMoyenApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY MONTH(CSA.dDate_Calcul), YEAR(CSA.dDate_Calcul), CSA.bTaux_ApresEcheance), 
			SommeEpargneMoyenAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY MONTH(CSA.dDate_Calcul), YEAR(CSA.dDate_Calcul), CSA.bTaux_ApresEcheance),
			SommeApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 AND MONTH(GETDATE()) >= MONTH(CSA.dDate_Calcul)-1 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance),
			SommeAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 AND MONTH(GETDATE()) >= MONTH(CSA.dDate_Calcul)-1 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance)
		FROM vtblREPR_CommissionsSurActif_conv CSA
		WHERE CSA.RepID = @RepID AND CSA.dDate_Calcul between @dateCalculDebut AND @DateCalculFin
	   ) C ON C.Mois = TM.NumMois
	JOIN (
		 SELECT
		 	 PrenomRep = H.FirstName,
			 NomRep = H.LastName,
			 NumeroRep = R.RepCode,
			 Statut = CASE WHEN @EndDate >= R.BusinessStart AND (@EndDate < R.BusinessEnd OR R.BusinessEnd IS NULL) THEN 'Actif' ELSE 'Inactif' END,
			 RepID = R.RepID
		 FROM Un_Rep R 
		 JOIN Mo_Human H on H.HumanID = R.RepID
		 WHERE r.RepID = @RepID
		) r on @RepID = R.RepID  
	WHERE R.RepID = @RepID 
		and MONTH(@EndDate) >= TM.NumMois 
	ORDER BY NumeroMois

END
