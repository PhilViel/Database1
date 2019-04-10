CREATE VIEW [dbo].[VtblREPR_CommissionsSurActif_Conv]
AS
SELECT
     CSA.RepTreatmentID,
    C.ConventionID,
     CSA.RepID,
     CSA.bTaux_ApresEcheance,
     CSA.dTaux_Calcul,
     CSA.dDate_Calcul,
     mEpargneCalcul = SUM(CSA.mEpargne_Calcul),
     mEpargne_SoldeDebut = SUM(CSA.mEpargne_SoldeDebut),
     mEpargne_Periode = SUM(CSA.mEpargne_Periode),
     mEpargne_SoldeFin = SUM(CSA.mEpargne_SoldeFin),
    mMontant_ComActif = CAST(SUM(CSA.mMontant_ComActif) AS DECIMAL(7,2))
FROM tblREPR_CommissionsSurActif CSA 
JOIN Un_Unit U on CSA.UnitID = U.UnitID
JOIN Un_Convention C on C.ConventionID = U.ConventionID
GROUP BY 
    CSA.RepTreatmentID,
    C.ConventionID, 
    CSA.RepID, 
    CSA.dDate_Calcul, 
    CSA.bTaux_ApresEcheance, 
    CSA.dTaux_Calcul

