CREATE VIEW [dbo].[VtblREPR_CommissionsSuivi_Conv]
AS
SELECT
    CS.RepTreatmentID,
    C.ConventionID,
    CS.RepID,
    CS.bTaux_ApresEcheance,
    CS.dTaux_Calcul,
    CS.dDate_Calcul,
    mEpargneCalcul = SUM(CS.mEpargne_Calcul),
    mEpargne_SoldeDebut = SUM(CS.mEpargne_SoldeDebut),
    mEpargne_Periode = SUM(CS.mEpargne_Periode),
    mEpargne_SoldeFin = SUM(CS.mEpargne_SoldeFin),
    mMontant_ComActif = CAST(SUM(CS.mMontant_ComSuivi) AS DECIMAL(7,2))
FROM tblREPR_CommissionsSuivi CS 
JOIN Un_Unit U on CS.UnitID = U.UnitID
JOIN Un_Convention C on C.ConventionID = U.ConventionID
GROUP BY 
    CS.RepTreatmentID,
    C.ConventionID, 
    CS.RepID, 
    CS.dDate_Calcul, 
    CS.bTaux_ApresEcheance, 
    CS.dTaux_Calcul