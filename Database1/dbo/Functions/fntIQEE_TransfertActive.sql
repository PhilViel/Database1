CREATE FUNCTION [dbo].[fntIQEE_TransfertActive](
    @iID_Convention INT = NULL,
    @siAnneeFiscale SMALLINT = NULL,
    @bAnneePrecedente BIT = 0
)
RETURNS TABLE
AS RETURN
(
    SELECT  iID_Transfert, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse,
            iID_Convention, vcNo_Convention, dtDate_Debut_Convention, iID_Sous_Type,
            --iID_Operation, iID_TIO, iID_Operation_RIO, iID_Cotisation, iID_Cheque,
            dtDate_Transfert, mTotal_Transfert, mIQEE_CreditBase_Transfere, mIQEE_Majore_Transfere, mCotisations_Donne_Droit_IQEE,
            mCotisations_Versees_Avant_Debut_IQEE, mCotisations_Non_Donne_Droit_IQEE,
            ID_Autre_Promoteur, ID_Regime_Autre_Promoteur, vcNo_Contrat_Autre_Promoteur,
            iID_Beneficiaire, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, dtDate_Naissance_Beneficiaire, tiSexe_Beneficiaire,
            iID_Adresse_Beneficiaire, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire,
            vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire,
            vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire,
            bTransfert_Total, bPRA_Deja_Verse, mJuste_Valeur_Marchande, mBEC, bTransfert_Autorise,
            iID_Souscripteur, tiType_Souscripteur, vcNAS_Souscripteur, vcNEQ_Souscripteur, vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur,
            iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur,
            vcLigneAdresse2_Souscripteur, vcLigneAdresse3_Souscripteur,
            vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur,
            iID_Cosouscripteur, vcNAS_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur, tiID_Lien_Cosouscripteur,
            iID_Fichier_IQEE, iID_Ligne_Fichier
      FROM (
             SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY T.iID_Convention, T.siAnnee_Fiscale, T.dtDate_Transfert ORDER BY F.dtDate_Creation_Fichiers DESC, T.tiCode_Version DESC ),
                    T.iID_Transfert, T.siAnnee_Fiscale, T.tiCode_Version, T.cStatut_Reponse,
                    T.iID_Convention, T.vcNo_Convention, T.dtDate_Debut_Convention, T.iID_Sous_Type,
                    --T.iID_Operation, T.iID_TIO, T.iID_Operation_RIO, T.iID_Cotisation, T.iID_Cheque,
                    T.dtDate_Transfert, T.mTotal_Transfert, T.mIQEE_CreditBase_Transfere, T.mIQEE_Majore_Transfere, T.mCotisations_Donne_Droit_IQEE,
                    T.mCotisations_Versees_Avant_Debut_IQEE, T.mCotisations_Non_Donne_Droit_IQEE,
                    T.ID_Autre_Promoteur, T.ID_Regime_Autre_Promoteur, T.vcNo_Contrat_Autre_Promoteur,
                    T.iID_Beneficiaire, T.vcNAS_Beneficiaire, T.vcNom_Beneficiaire, T.vcPrenom_Beneficiaire, T.dtDate_Naissance_Beneficiaire, T.tiSexe_Beneficiaire,
                    T.iID_Adresse_Beneficiaire, T.vcAppartement_Beneficiaire, T.vcNo_Civique_Beneficiaire, T.vcRue_Beneficiaire,
                    T.vcLigneAdresse2_Beneficiaire, T.vcLigneAdresse3_Beneficiaire,
                    T.vcVille_Beneficiaire, T.vcProvince_Beneficiaire, T.vcPays_Beneficiaire, T.vcCodePostal_Beneficiaire,
                    T.bTransfert_Total, T.bPRA_Deja_Verse, T.mJuste_Valeur_Marchande, T.mBEC, T.bTransfert_Autorise,
                    T.iID_Souscripteur, T.tiType_Souscripteur, T.vcNAS_Souscripteur, T.vcNEQ_Souscripteur, T.vcNom_Souscripteur, T.vcPrenom_Souscripteur, T.tiID_Lien_Souscripteur,
                    T.iID_Adresse_Souscripteur, T.vcAppartement_Souscripteur, T.vcNo_Civique_Souscripteur, T.vcRue_Souscripteur,
                    T.vcLigneAdresse2_Souscripteur, T.vcLigneAdresse3_Souscripteur,
                    T.vcVille_Souscripteur, T.vcProvince_Souscripteur, T.vcPays_Souscripteur, T.vcCodePostal_Souscripteur,
                    T.iID_Cosouscripteur, T.vcNAS_Cosouscripteur, T.vcNom_Cosouscripteur, T.vcPrenom_Cosouscripteur, T.tiID_Lien_Cosouscripteur,
                    T.iID_Fichier_IQEE, T.iID_Ligne_Fichier
               FROM dbo.tblIQEE_Transferts T
                    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE
              WHERE ( T.siAnnee_Fiscale = ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1)
                      OR (@bAnneePrecedente <> 0 AND T.siAnnee_Fiscale < ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1))
                    )
                    AND T.iID_Convention = ISNULL(@iID_Convention, T.iID_Convention)
                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
           ) I
     WHERE RowNum = 1
)