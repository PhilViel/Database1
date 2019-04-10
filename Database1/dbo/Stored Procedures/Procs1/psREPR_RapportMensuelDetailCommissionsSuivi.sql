/********************************************************************************************************************
Copyrights (c) 2017 Gestion Universitas inc
Nom                 :	psREPR_RapportMensuelDetailCommissionsSuivi
Description         :	Pour le rapport SSRS "RapportMensuelDetailCommissionsSuivi" : permet d'obtenir les commissions de suivi
						pour un représentant en particulier, pour un mois choisi.
Valeurs de retours  :	Dataset 
Note                :	2017-06-21	Pierre-Luc Simard	Création

exec psREPR_RapportMensuelDetailCommissionsSuivi '2017-06-01', 149509
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportMensuelDetailCommissionsSuivi] 
                        
	(
	@StartDate DATETIME, 
	@RepID INTEGER
	) 

AS
BEGIN
	DECLARE 
		@dtdateCalcul DATETIME = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@StartDate))-1),DATEADD(mm,1,@StartDate)),101)

	SELECT DISTINCT
		PrenomRep = R.PrenomRep, 
		NomRep = R.NomRep, 
		NumeroRep = R.NumeroRep, 
		RepID = R.RepID,
		Statut = R.Statut,
		PrenomSouscripteur = HS.FirstName,
		NomSouscripteur = HS.LastName,
		SouscripteurID = HS.humanID, 
		NumeroConvention = C.ConventionNo,
		DateSignatureConv = c.dtSignature,
		Echeance = CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN 'après' ELSE CASE WHEN CSA.bTaux_ApresEcheance = 0 then 'avant' ELSE NULL END END,
		TauxCommission = CSA.dTaux_Calcul,
		CommActif = SUM(CSA.mMontant_ComActif) OVER(PARTITION BY C.ConventionID, CSA.bTaux_ApresEcheance),
		EpargneDebut = SUM(CSA.mEpargne_SoldeDebut) OVER(PARTITION BY C.ConventionID, CSA.bTaux_ApresEcheance),
		EpargnePeriode = SUM(CSA.mEpargne_Periode) OVER(PARTITION BY C.ConventionID, CSA.bTaux_ApresEcheance),
		EpargneFinPeriode = SUM(CSA.mEpargne_SoldeFin) OVER(PARTITION BY C.ConventionID, CSA.bTaux_ApresEcheance),
		EpargneCalcul = SUM(CSA.mEpargneCalcul) OVER(PARTITION BY C.ConventionID, CSA.bTaux_ApresEcheance),
		SommeEpargneDebutApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mEpargne_SoldeDebut ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance), 
		SommeEpargneDebutAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mEpargne_SoldeDebut ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance),
		SommeEpargnePeriodeApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mEpargne_Periode ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance), 
		SommeEpargnePeriodeAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mEpargne_Periode ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance),
		SommeEpargneFinApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mEpargne_SoldeFin ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance), 
		SommeEpargneFinAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mEpargne_SoldeFin ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance),
		SommeEpargneMoyenApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mEpargneCalcul ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance), 
		SommeEpargneMoyenAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mEpargneCalcul ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance),  
		SommeCommActifApresEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 1 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance), 
		SommeCommActifAvantEcheance = SUM(CASE WHEN CSA.bTaux_ApresEcheance = 0 THEN CSA.mMontant_ComActif ELSE 0 END) OVER(PARTITION BY CSA.bTaux_ApresEcheance)
	FROM 
		 (
		 SELECT
		 	 PrenomRep = H.FirstName,
			 NomRep = H.LastName,
			 NumeroRep = R.RepCode,
			 Statut = CASE WHEN @StartDate >= R.BusinessStart AND (@StartDate < R.BusinessEnd OR R.BusinessEnd IS NULL) THEN 'Actif' ELSE 'Inactif' END,
			 RepID = R.RepID
		 FROM Un_Rep R 
		 JOIN Mo_Human H on H.HumanID = R.RepID
		 WHERE r.RepID = @RepID
		) R 
		LEFT JOIN VtblREPR_CommissionsSuivi_Conv CSA on CSA.RepID = R.RepID AND MONTH(@dtdateCalcul) = MONTH(CSA.dDate_Calcul) AND YEAR(@dtDateCalcul) = YEAR(CSA.dDate_Calcul)
		LEFT JOIN Un_Convention C on C.ConventionID = CSA.ConventionID
		LEFT JOIN Mo_Human HS ON HS.HumanID = C.SubscriberID
	WHERE R.RepID = @RepID
	ORDER BY C.ConventionNo, C.dtSignature
END