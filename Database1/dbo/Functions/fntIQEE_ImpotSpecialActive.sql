CREATE FUNCTION [dbo].[fntIQEE_ImpotSpecialActive](
    @iID_Convention INT = NULL,
    @siAnneeFiscale SMALLINT = NULL,
    @bAnneePrecedente BIT = 0
)
RETURNS TABLE
AS RETURN
(
    SELECT iID_Impot_Special, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse,
           iID_Convention, vcNo_Convention, iID_Statut_Convention, 
           iID_Sous_Type, cTypeEnregistrement = (SELECT T.cCode_Type_SousType FROM dbo.vwIQEE_Enregistrement_TypeEtSousType T WHERE T.iID_Sous_Type = I.iID_Sous_Type),
           --iID_Remplacement_Beneficiaire, iID_Transfert, iID_Operation, iID_Cotisation, iID_RI, iID_Cheque,
           dtDate_Evenement, mCotisations_Retirees, mSolde_IQEE_Base, mSolde_IQEE_Majore, mIQEE_ImpotSpecial, mSolde_IQEE,
           mRadiation, mCotisations_Donne_Droit_IQEE, mJuste_Valeur_Marchande, mBEC, mSubvention_Canadienne,
           iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
           vcCode_Postal_Etablissement, vcNom_Etablissement,
           iID_Paiement_Impot_CBQ, iID_Paiement_Impot_MMQ,
           --mMontant_A, mMontant_B, mMontant_C, mMontant_AFixe, mEcart_ReelvsFixe,
           iID_Transaction_Convention_CBQ_Renversee, iID_Transaction_Convention_MMQ_Renversee,
           iID_Fichier_IQEE, iID_Ligne_Fichier
      FROM (
             SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY I.iID_Convention, I.siAnnee_Fiscale, I.dtDate_Evenement, I.iID_Sous_Type ORDER BY F.dtDate_Creation_Fichiers DESC, I.tiCode_Version DESC ),
                    I.iID_Impot_Special, I.siAnnee_Fiscale, I.iID_Sous_Type, I.tiCode_Version, I.cStatut_Reponse,
                    I.iID_Convention, I.vcNo_Convention, I.iID_Statut_Convention,
                    --I.iID_Remplacement_Beneficiaire, I.iID_Transfert, I.iID_Operation, I.iID_Cotisation, I.iID_RI, I.iID_Cheque,
                    I.dtDate_Evenement, I.mCotisations_Retirees, I.mSolde_IQEE_Base, I.mSolde_IQEE_Majore, I.mIQEE_ImpotSpecial, I.mSolde_IQEE,
                    I.mRadiation, I.mCotisations_Donne_Droit_IQEE, I.mJuste_Valeur_Marchande, I.mBEC, I.mSubvention_Canadienne,
                    I.iID_Beneficiaire, I.vcNAS_Beneficiaire, I.vcNom_Beneficiaire, I.vcPrenom_Beneficiaire, I.dtDate_Naissance_Beneficiaire, I.tiSexe_Beneficiaire,
                    I.vcCode_Postal_Etablissement, I.vcNom_Etablissement,
                    I.iID_Paiement_Impot_CBQ, I.iID_Paiement_Impot_MMQ,
                    --I.mMontant_A, I.mMontant_B, I.mMontant_C, I.mMontant_AFixe, I.mEcart_ReelvsFixe,
                    I.iID_Transaction_Convention_CBQ_Renversee, I.iID_Transaction_Convention_MMQ_Renversee,
                    I.iID_Fichier_IQEE, I.iID_Ligne_Fichier
               FROM dbo.tblIQEE_ImpotsSpeciaux I
                    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = I.iID_Fichier_IQEE
              WHERE ( I.siAnnee_Fiscale = ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1)
                      OR (@bAnneePrecedente <> 0 AND I.siAnnee_Fiscale < ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1))
                    )
                    AND I.iID_Convention = ISNULL(@iID_Convention, I.iID_Convention)
                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
           ) I
     WHERE RowNum = 1
)