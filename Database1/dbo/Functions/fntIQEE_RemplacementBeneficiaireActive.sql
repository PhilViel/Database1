CREATE FUNCTION [dbo].[fntIQEE_RemplacementBeneficiaireActive](
    @iID_Convention INT = NULL,
    @siAnneeFiscale SMALLINT = NULL,
    @bAnneePrecedente BIT = 0
)
RETURNS TABLE
AS RETURN
(
    SELECT  iID_Remplacement_Beneficiaire, siAnnee_Fiscale, tiCode_Version, cStatut_Reponse,
            iID_Convention, vcNo_Convention,
            iID_Changement_Beneficiaire, dtDate_Remplacement, bInd_Remplacement_Reconnu, bLien_Frere_Soeur,
            iID_Ancien_Beneficiaire, vcNAS_Ancien_Beneficiaire, vcNom_Ancien_Beneficiaire, vcPrenom_Ancien_Beneficiaire, dtDate_Naissance_Ancien_Beneficiaire, tiSexe_Ancien_Beneficiaire,
            iID_Nouveau_Beneficiaire, vcNAS_Nouveau_Beneficiaire, vcNom_Nouveau_Beneficiaire, vcPrenom_Nouveau_Beneficiaire, dtDate_Naissance_Nouveau_Beneficiaire, tiSexe_Nouveau_Beneficiaire,
            tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire, bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial,
            iID_Adresse_Beneficiaire_Date_Remplacement, vcAppartement_Beneficiaire, vcNo_Civique_Beneficiaire, vcRue_Beneficiaire, 
            vcLigneAdresse2_Beneficiaire, vcLigneAdresse3_Beneficiaire,
            vcVille_Beneficiaire, vcProvince_Beneficiaire, vcPays_Beneficiaire, vcCodePostal_Beneficiaire, bResidence_Quebec,
            iID_Fichier_IQEE, iID_Ligne_Fichier

      FROM (
             SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY RB.iID_Convention, RB.siAnnee_Fiscale, RB.dtDate_Remplacement ORDER BY F.dtDate_Creation_Fichiers DESC, RB.tiCode_Version DESC ),
                    RB.iID_Remplacement_Beneficiaire, RB.siAnnee_Fiscale, RB.tiCode_Version, RB.cStatut_Reponse,
                    RB.iID_Convention, RB.vcNo_Convention,
                    RB.iID_Changement_Beneficiaire, RB.dtDate_Remplacement, RB.bInd_Remplacement_Reconnu, RB.bLien_Frere_Soeur,
                    RB.iID_Ancien_Beneficiaire, RB.vcNAS_Ancien_Beneficiaire, RB.vcNom_Ancien_Beneficiaire, RB.vcPrenom_Ancien_Beneficiaire, RB.dtDate_Naissance_Ancien_Beneficiaire, RB.tiSexe_Ancien_Beneficiaire,
                    RB.iID_Nouveau_Beneficiaire, RB.vcNAS_Nouveau_Beneficiaire, RB.vcNom_Nouveau_Beneficiaire, RB.vcPrenom_Nouveau_Beneficiaire, RB.dtDate_Naissance_Nouveau_Beneficiaire, RB.tiSexe_Nouveau_Beneficiaire,
                    RB.tiID_Type_Relation_Souscripteur_Nouveau_Beneficiaire, RB.bLien_Sang_Nouveau_Beneficiaire_Souscripteur_Initial,
                    RB.iID_Adresse_Beneficiaire_Date_Remplacement, RB.vcAppartement_Beneficiaire, RB.vcNo_Civique_Beneficiaire, RB.vcRue_Beneficiaire, 
                    RB.vcLigneAdresse2_Beneficiaire, RB.vcLigneAdresse3_Beneficiaire,
                    RB.vcVille_Beneficiaire, RB.vcProvince_Beneficiaire, RB.vcPays_Beneficiaire, RB.vcCodePostal_Beneficiaire, RB.bResidence_Quebec,
                    RB.iID_Fichier_IQEE, RB.iID_Ligne_Fichier
               FROM dbo.tblIQEE_RemplacementsBeneficiaire RB
                    JOIN dbo.tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = RB.iID_Fichier_IQEE
              WHERE ( RB.siAnnee_Fiscale = ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1)
                      OR (@bAnneePrecedente <> 0 AND RB.siAnnee_Fiscale < ISNULL(@siAnneeFiscale, YEAR(DATEADD(MONTH, -3, GETDATE())) - 1))
                    )
                    AND RB.iID_Convention = ISNULL(@iID_Convention, RB.iID_Convention)
                    AND F.bFichier_Test = 0 AND F.bInd_Simulation = 0
           ) I
     WHERE RowNum = 1
)