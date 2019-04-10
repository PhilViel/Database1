CREATE FUNCTION dbo.fntIQEE_ObtenirEnregistrementID_FromLigneRQ (
    @iID_LigneFichier           INT
) 
RETURNS TABLE
RETURN (
    SELECT cCodeTypeEnregistrement = '02', iID_Evenement = iID_Demande_IQEE, iID_Convention, vcNo_Convention, siAnnee_Fiscale, 
           iID_Fichier_IQEE, tiCode_Version, cStatut_Reponse, CAST(NULL AS int) AS iID_Sous_Type, CAST(NULL AS date) AS dtDate_Evenement
      FROM dbo.tblIQEE_Demandes
     WHERE iID_Ligne_Fichier = @iID_LigneFichier
    UNION 
    SELECT '03', iID_Remplacement_Beneficiaire, iID_Convention, vcNo_Convention, siAnnee_Fiscale, 
           iID_Fichier_IQEE, tiCode_Version, cStatut_Reponse, NULL, dtDate_Remplacement
      FROM dbo.tblIQEE_RemplacementsBeneficiaire 
     WHERE iID_Ligne_Fichier = @iID_LigneFichier
    UNION 
    SELECT '04', iID_Transfert, iID_Convention, vcNo_Convention, siAnnee_Fiscale, 
           iID_Fichier_IQEE, tiCode_Version, cStatut_Reponse, iID_Sous_Type, dtDate_Transfert
      FROM dbo.tblIQEE_Transferts 
     WHERE iID_Ligne_Fichier = @iID_LigneFichier
    UNION 
    SELECT '05', iID_Paiement_Beneficiaire, iID_Convention, vcNo_Convention, siAnnee_Fiscale, 
           iID_Fichier_IQEE, tiCode_Version, cStatut_Reponse, iID_Sous_Type, dtDate_Paiement
      FROM dbo.tblIQEE_PaiementsBeneficiaires 
     WHERE iID_Ligne_Fichier = @iID_LigneFichier
    UNION 
    SELECT '06', iID_Impot_Special, iID_Convention, vcNo_Convention, siAnnee_Fiscale, 
           iID_Fichier_IQEE, tiCode_Version, cStatut_Reponse, iID_Sous_Type, dtDate_Evenement
      FROM dbo.tblIQEE_ImpotsSpeciaux 
     WHERE iID_Ligne_Fichier = @iID_LigneFichier
)
