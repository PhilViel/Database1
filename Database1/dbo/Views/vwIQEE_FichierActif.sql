CREATE VIEW [dbo].[vwIQEE_FichierActif] WITH SCHEMABINDING AS
    SELECT F.iID_Fichier_IQEE, F.tiID_Type_Fichier, F.tiID_Statut_Fichier, F.vcCode_Simulation, F.iID_Parametres_IQEE,
           F.dtDate_Creation, F.dtDate_Creation_Fichiers, F.dtDate_Transmis,
           F.vcNom_Fichier, F.vcChemin_Fichier, F.iID_Lien_Fichier_IQEE_Demande, 
           F.dtDate_Traitement_RQ, F.dtDate_Production_Paiement, F.dtDate_Paiement, F.iNumero_Paiement, F.mMontant_Total_Paiement,
           F.vcInstitution_Paiement, F.vcTransit_Paiement, F.vcCompte_Paiement, F.vcNo_Identification_RQ,
           F.mMontant_Total_A_Payer, F.mMontant_Total_Cotise, F.mMontant_Total_Recu, F.mMontant_Total_Interets, F.mSolde_Paiement_RQ,
           F.dtDate_Sommaire_Avis_Cotisation_Impots_Speciaux,
           F.iID_Session, F.iID_Utilisateur_Creation, F.iID_Utilisateur_Modification, F.dtDate_Modification,
           F.iID_Utilisateur_Approuve, F.dtDate_Approve, F.iID_Utilisateur_Transmis
      FROM dbo.tblIQEE_Fichiers F
     WHERE F.bFichier_Test = 0
           AND F.bInd_Simulation = 0
GO
CREATE UNIQUE CLUSTERED INDEX [IXV_IQEE_FichierActif_iIDFichier]
    ON [dbo].[vwIQEE_FichierActif]([iID_Fichier_IQEE] ASC) WITH (STATISTICS_NORECOMPUTE = ON);

