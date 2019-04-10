
/******************************************************************************

  Liste les enregistrements de la table de configuration des minimums d'épargnes
  et frais par dépôts pour une convention selon la modalité de paiement et le
  plan.
                                                                             
  05-05-2003 Marcw           Création

******************************************************************************/
CREATE PROCEDURE SUn_MinDepositCfgList
 (@ConnectID    MoID) -- ID Unique de connexion de l'usager
AS
BEGIN
  SELECT
    M.MinDepositCfgID,
    M.PlanID,
    P.PlanDesc,
    M.EffectDate,
    M.ModalTypeID,
    M.MinAmount
  FROM Un_MinDepositCfg M
  JOIN Un_Plan P ON (P.PlanID = M.PlanID)
  ORDER BY P.PlanDesc, M.EffectDate, M.ModalTypeID DESC
END;

