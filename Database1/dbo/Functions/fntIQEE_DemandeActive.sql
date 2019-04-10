CREATE FUNCTION [dbo].[fntIQEE_DemandeActive](
    @iID_Convention INT = NULL,
    @siAnneeFiscale SMALLINT = NULL,
    @bAnneePrecedente BIT = 0
)
RETURNS TABLE
AS RETURN
(
    SELECT iID_Demande_IQEE, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse,
           iID_Convention, vcNo_Convention, dtDate_Debut_Convention,
           mCotisations, mTransfert_IN, mTotal_Cotisations_Subventionnables, mTotal_Cotisations,
           iID_Beneficiaire_31Decembre, vcNAS_Beneficiaire, vcNom_Beneficiaire, vcPrenom_Beneficiaire, tiSexe_Beneficiaire, dtDate_Naissance_Beneficiaire,
           iID_Adresse_31Decembre_Beneficiaire, tiNB_Annee_Quebec,
           vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire,
           vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire,
           vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec,
           iID_Souscripteur,  vcNom_Souscripteur, vcPrenom_Souscripteur, tiID_Lien_Souscripteur,
           tiType_Souscripteur, vcNAS_Souscripteur, vcNEQ_Souscripteur,
           iID_Adresse_Souscripteur, vcAppartement_Souscripteur, vcNo_Civique_Souscripteur, vcRue_Souscripteur,
           vcLigneAdresse2_Souscripteur, vcLigneAdresse3_Souscripteur,
           vcVille_Souscripteur, vcProvince_Souscripteur, vcPays_Souscripteur, vcCodePostal_Souscripteur, vcTelephone_Souscripteur,
           iID_Cosouscripteur, vcNom_Cosouscripteur, vcPrenom_Cosouscripteur, vcNAS_Cosouscripteur,
           tiID_Lien_Cosouscripteur, vcTelephone_Cosouscripteur,
           tiType_Responsable, vcNAS_Responsable, vcNEQ_Responsable, vcNom_Responsable, vcPrenom_Responsable, tiID_Lien_Responsable,
           vcAppartement_Responsable, vcNo_Civique_Responsable, vcRue_Responsable, vcLigneAdresse2_Responsable, vcLigneAdresse3_Responsable,
           vcVille_Responsable, vcProvince_Responsable, vcPays_Responsable, vcCodePostal_Responsable, vcTelephone_Responsable,
           bInd_Cession_IQEE, iID_Fichier_IQEE, iID_Ligne_Fichier
      FROM (
             SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY D.iID_Convention, D.siAnnee_Fiscale ORDER BY F.dtDate_Creation_Fichiers DESC, D.tiCode_Version DESC ),
                    D.iID_Demande_IQEE, D.siAnnee_Fiscale, D.tiCode_Version, D.cStatut_Reponse,
                    D.iID_Convention, D.vcNo_Convention, D.dtDate_Debut_Convention,
                    D.mCotisations, D.mTransfert_IN, D.mTotal_Cotisations_Subventionnables, D.mTotal_Cotisations,
                    D.iID_Beneficiaire_31Decembre, D.vcNAS_Beneficiaire, D.vcNom_Beneficiaire, D.vcPrenom_Beneficiaire, D.tiSexe_Beneficiaire, D.dtDate_Naissance_Beneficiaire,
                    D.iID_Adresse_31Decembre_Beneficiaire, D.tiNB_Annee_Quebec,
                    D.vcAppartement_Beneficiaire, D.vcNo_Civique_Beneficiaire, D.vcRue_Beneficiaire,
                    D.vcLigneAdresse2_Beneficiaire, D.vcLigneAdresse3_Beneficiaire,
                    D.vcVille_Beneficiaire, D.vcProvince_Beneficiaire, D.vcPays_Beneficiaire, D.vcCodePostal_Beneficiaire, D.bResidence_Quebec,
                    D.iID_Souscripteur,  D.vcNom_Souscripteur, D.vcPrenom_Souscripteur, D.tiID_Lien_Souscripteur,
                    D.tiType_Souscripteur, D.vcNAS_Souscripteur, D.vcNEQ_Souscripteur,
                    D.iID_Adresse_Souscripteur, D.vcAppartement_Souscripteur, D.vcNo_Civique_Souscripteur, D.vcRue_Souscripteur,
                    D.vcLigneAdresse2_Souscripteur, D.vcLigneAdresse3_Souscripteur,
                    D.vcVille_Souscripteur, D.vcProvince_Souscripteur, D.vcPays_Souscripteur, D.vcCodePostal_Souscripteur, D.vcTelephone_Souscripteur,
                    D.iID_Cosouscripteur, D.vcNom_Cosouscripteur, D.vcPrenom_Cosouscripteur, D.vcNAS_Cosouscripteur,
                    D.tiID_Lien_Cosouscripteur, D.vcTelephone_Cosouscripteur,
                    D.tiType_Responsable, D.vcNAS_Responsable, D.vcNEQ_Responsable, D.vcNom_Responsable, D.vcPrenom_Responsable, D.tiID_Lien_Responsable,
                    D.vcAppartement_Responsable, D.vcNo_Civique_Responsable, D.vcRue_Responsable, D.vcLigneAdresse2_Responsable, D.vcLigneAdresse3_Responsable,
                    D.vcVille_Responsable, D.vcProvince_Responsable, D.vcPays_Responsable, D.vcCodePostal_Responsable, D.vcTelephone_Responsable,
                    D.bInd_Cession_IQEE, D.iID_Fichier_IQEE, D.iID_Ligne_Fichier
               FROM dbo.tblIQEE_Demandes D
                    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
              WHERE ( D.siAnnee_Fiscale = ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1)
                      OR (@bAnneePrecedente <> 0 AND D.siAnnee_Fiscale < ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1))
                    )
                    AND D.iID_Convention = ISNULL(@iID_Convention, d.iID_Convention)
                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
           ) D
     WHERE RowNum = 1
)