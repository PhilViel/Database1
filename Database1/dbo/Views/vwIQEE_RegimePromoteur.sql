CREATE VIEW [dbo].[vwIQEE_RegimePromoteur] AS
    SELECT R.iID_Regime, R.vcNoRegime, 
           vcNom_Promoteur = RP.vcDescription, dtSignature_Promoteur = RP.dtSignature, RP.bOffreIQEE, 
           dtEntreeEnVigueur = CASE WHEN RP.dtSignature >= RF.dtSignature THEN RP.dtSignature ELSE RF.dtSignature END, 
           vcNom_Mandataire = RM.vcDescription, vcNEQ_Mandataire = RM.vcNEQ,
           vcNom_Fiduciaire = RF.vcDescription, vcNEQ_Fiduciaire = RF.vcNEQ, dtSignature_Fiduciaire = RF.dtSignature
      FROM dbo.tblSUBV_Regime R --ON R.vcNoRegime = EP.ExternalPlanGovernmentRegNo
           LEFT JOIN dbo.tblSUBV_RegimePromoteur RP ON RP.iID_RegimePromoteur = R.iID_RegimePromoteur
           LEFT JOIN dbo.tblSUBV_RegimeMandataire RM ON RM.iID_RegimeMandataire = R.iID_RegimeMandataire
           LEFT JOIN dbo.tblSUBV_RegimeFiduciaire RF ON RF.iID_RegimeFiduciaire = R.iID_RegimeFiduciaire
