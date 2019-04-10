CREATE FUNCTION [dbo].[fntIQEE_PaiementBeneficiaireActive](
    @iID_Convention INT = NULL,
    @siAnneeFiscale SMALLINT = NULL,
    @bAnneePrecedente BIT = 0
)
RETURNS TABLE
AS RETURN
(
    SELECT  iID_Paiement_Beneficiaire, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse,
            iID_Convention, vcNo_Convention, iID_Sous_Type,
            --iID_Bourse, iID_Paiement_Bourse, iID_Operation,
            dtDate_Paiement, bRevenus_Accumules, mCotisations_Retirees, mIQEE_CreditBase, mIQEE_Majoration, mPAE_Verse, mSolde_IQEE,
            mJuste_Valeur_Marchande, mCotisations_Versees, mBEC_Autres_Beneficiaires, mBEC_Beneficiaire, mSolde_SCEE, mProgrammes_Autres_Provinces,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire, bResidence_Quebec,
            tiType_Etudes, tiDuree_Programme, tiAnnee_Programme, dtDate_Debut_Annee_Scolaire, tiDuree_Annee_Scolaire,
            vcCode_Postal_Etablissement, vcNom_Etablissement,
            iID_Fichier_IQEE, iID_Ligne_Fichier
      FROM (
             SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY PB.iID_Convention, PB.siAnnee_Fiscale, PB.dtDate_Paiement ORDER BY F.dtDate_Creation_Fichiers DESC, PB.tiCode_Version DESC ),
                    PB.iID_Paiement_Beneficiaire, PB.siAnnee_Fiscale, PB.tiCode_Version, PB.cStatut_Reponse,
                    PB.iID_Convention, PB.vcNo_Convention, PB.iID_Sous_Type,
                    --PB.iID_Bourse, PB.iID_Paiement_Bourse, PB.iID_Operation,
                    PB.dtDate_Paiement, PB.bRevenus_Accumules, PB.mCotisations_Retirees, PB.mIQEE_CreditBase, PB.mIQEE_Majoration, PB.mPAE_Verse, PB.mSolde_IQEE,
                    PB.mJuste_Valeur_Marchande, PB.mCotisations_Versees, PB.mBEC_Autres_Beneficiaires, PB.mBEC_Beneficiaire, PB.mSolde_SCEE, PB.mProgrammes_Autres_Provinces,
                    PB.iID_Beneficiaire, PB.vcNAS_Beneficiaire, PB.vcNom_Beneficiaire, PB.vcPrenom_Beneficiaire, PB.dtDate_Naissance_Beneficiaire, PB.tiSexe_Beneficiaire, PB.bResidence_Quebec,
                    PB.tiType_Etudes, PB.tiDuree_Programme, PB.tiAnnee_Programme, PB.dtDate_Debut_Annee_Scolaire, PB.tiDuree_Annee_Scolaire,
                    PB.vcCode_Postal_Etablissement, PB.vcNom_Etablissement,
                    PB.iID_Fichier_IQEE, PB.iID_Ligne_Fichier
               FROM dbo.tblIQEE_PaiementsBeneficiaires PB
                    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = PB.iID_Fichier_IQEE
              WHERE ( PB.siAnnee_Fiscale = ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1)
                      OR (@bAnneePrecedente <> 0 AND PB.siAnnee_Fiscale < ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1))
                    )
                    AND PB.iID_Convention = ISNULL(@iID_Convention, PB.iID_Convention)
                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
           ) I
     WHERE RowNum = 1
)