CREATE TABLE [dbo].[tblIQEE_StatistiquesImpotsSpeciaux] (
    [iID_Statistique_Impots_Speciaux]     INT      IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_Reponse_Impots_Speciaux] INT      NOT NULL,
    [siAnnee_Fiscale]                     SMALLINT NOT NULL,
    [iNb_Avis_Zero]                       INT      NOT NULL,
    [iNb_Avis_Debiteurs]                  INT      NOT NULL,
    [iNb_Avis_Crediteurs]                 INT      NOT NULL,
    [mTotal_Cotisations_Avis_Zero]        MONEY    NOT NULL,
    [mTotal_Cotisations_Avis_Debiteurs]   MONEY    NOT NULL,
    [mTotal_Cotisations_Avis_Crediteurs]  MONEY    NOT NULL,
    [mTotal_Cotisations_Avis_Fictif]      MONEY    NOT NULL,
    [mTotal_Cotisations_Total_Avis]       MONEY    NOT NULL,
    [mSomme_Accaparee_Avis_Zero]          MONEY    NOT NULL,
    [mSomme_Accaparee_Avis_Debiteurs]     MONEY    NOT NULL,
    [mSomme_Accaparee_Avis_Crediteurs]    MONEY    NOT NULL,
    [mSomme_Accaparee_Avis_Fictif]        MONEY    NOT NULL,
    [mSomme_Accaparee_Total_Avis]         MONEY    NOT NULL,
    [bSomme_Accaparee_Balance]            BIT      NOT NULL,
    [mEcart_Somme_Accaparee_Total_Avis]   BIT      NOT NULL,
    [mInterets_Avis_Zero]                 MONEY    NOT NULL,
    [mInterets_Avis_Debiteurs]            MONEY    NOT NULL,
    [mInterets_Avis_Crediteurs]           MONEY    NOT NULL,
    [mInterets_Avis_Fictif]               MONEY    NOT NULL,
    [mInterets_Total_Avis]                MONEY    NOT NULL,
    [mSolde_Avis_Zero]                    MONEY    NOT NULL,
    [mSolde_Avis_Debiteurs]               MONEY    NOT NULL,
    [mSolde_Avis_Crediteurs]              MONEY    NOT NULL,
    [mSolde_Avis_Fictif]                  MONEY    NOT NULL,
    [mSolde_Total_Avis]                   MONEY    NOT NULL,
    [bSolde_Avis_Balance]                 BIT      NOT NULL,
    [mEcart_Solde_Total_Avis]             BIT      NOT NULL,
    CONSTRAINT [PK_IQEE_StatistiquesImpotsSpeciaux] PRIMARY KEY CLUSTERED ([iID_Statistique_Impots_Speciaux] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_StatistiquesImpotsSpeciaux_IQEE_Fichiers__iIDFichierReponseImpotsSpeciaux] FOREIGN KEY ([iID_Fichier_Reponse_Impots_Speciaux]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''un ensemble de statistiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_StatistiquesImpotsSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statistiques cumulées des montants de l''importation des fichiers COT lors de l''emploi de la stored proc psIQEE_ImporterFichierCOT.  Correspond aux champs "Type fiduciaire" du type d''enregistrement 04, "Type paiement" du type d''enregistrement 05 et "Raison de l''impôt spécial" du type d''enregistrement 06.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un ensemble de statistiques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Statistique_Impots_Speciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant d''un fichier réponse des impôts spéciaux(.COT).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Fichier_Reponse_Impots_Speciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Année fiscale des réponses provenant du fichier .COT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'siAnnee_Fiscale';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre des avis de cotisations qui ne requièrent pas de montant additionnel ni à débourser ni à encaisser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iNb_Avis_Zero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre des avis de cotisations qui requièrent un  montant additionnel à débourser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iNb_Avis_Debiteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre des avis de cotisations qui requièrent un  montant additionnel à encaisser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iNb_Avis_Crediteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations calculées par Revenu Québec qui ne requièrent pas de montant additionnel ni à débourser ni à encaisser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Avis_Zero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations calculées par Revenu Québec qui requièrent un  montant additionnel à débourser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Avis_Debiteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations calculées par Revenu Québec qui requièrent un  montant additionnel à encaisser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Avis_Crediteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la cotisation fictive calculé par Revenu Québec.  Les avis de cotisations fictifs font référence à des montants qui n’ont pu être attribués à un contrat en particulier pour une quelconque raison, principalement le fait que la transaction [T06] associée à cet impôt spécial ait été rejetée. Ce segment ne peut être retiré. Le seul traitement particulier requis est que vous identifiez les transactions en erreur, s’il y a lieu, et que vous les corrigiez.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Avis_Fictif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations calculées par Revenu Québec (Zéro, Débiteurs, Créditeurs et Fictif (ainsi que l''avis fictif du fichier qui sera toujours dans les fichiers .COT).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Total_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations déboursé par GUI lié à des conventions qui n''implique pas de montant additionnel ni à débourser ni à encaisser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSomme_Accaparee_Avis_Zero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations déboursé par GUI lié à des conventions dont un montant additionnel sera à débourser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSomme_Accaparee_Avis_Debiteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations déboursé par GUI lié à des conventions dont un montant additionnel sera à encaisser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSomme_Accaparee_Avis_Crediteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la somme accaparée de l''avis fictif calculé par Revenu Québec.  Les avis de cotisations fictifs font référence à des montants qui n’ont pu être attribués à un contrat en particulier pour une quelconque raison, principalement le fait que la transaction [T06] associée à cet impôt spécial ait été rejetée. Ce segment ne peut être retiré. Le seul traitement particulier requis est que vous identifiez les transactions en erreur, s’il y a lieu, et que vous les corrigiez.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSomme_Accaparee_Avis_Fictif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des sommes accaparées déboursées par GUI (Zéro, Débiteurs, Créditeurs et Fictif  (ainsi que l''avis fictif du fichier qui sera toujours dans les fichiers .COT)).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSomme_Accaparee_Total_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Booléen pour confirmer que le total des sommes accaparées déboursées par GUI correspond à nos calculs effectués lors l''importation du fichier .COT avec la procédure stockée psIQEE_ImporterFichierCOT. 1= Vrai, 0=Faux.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'bSomme_Accaparee_Balance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Si bSomme_Accaparee_Balance est Faux, montant de l''écart des sommes accaparées entre nos calculs et les montants de Revenu Québec.  Si bSomme_Accaparee_Balance est Vrai, la valeur sera 0.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mEcart_Somme_Accaparee_Total_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des intérêts calculé par Revenu Québec lié à des conventions qui n''implique pas de montant additionnel ni à débourser ni à encaisser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mInterets_Avis_Zero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des intérêts calculé par Revenu Québec lié à des conventions dont un montant additionnel sera à débourser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mInterets_Avis_Debiteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des intérêts calculé par Revenu Québec lié à des conventions dont un montant additionnel sera à encaisser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mInterets_Avis_Crediteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des intérêts de l''avis fictif calculé par Revenu Québec.  Les avis de cotisations fictifs font référence à des montants qui n’ont pu être attribués à un contrat en particulier pour une quelconque raison, principalement le fait que la transaction [T06] associée à cet impôt spécial ait été rejetée. Ce segment ne peut être retiré. Le seul traitement particulier requis est que vous identifiez les transactions en erreur, s’il y a lieu, et que vous les corrigiez.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mInterets_Avis_Fictif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des intérêts calculés par Revenu Québec (Zéro, Débiteurs, Créditeurs et Fictif  (ainsi que l''avis fictif du fichier qui sera toujours dans les fichiers .COT)).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mInterets_Total_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde des avis à Zéro traités (Cotisation totale+Somme Accaparée+Intérêts) lié à des conventions qui n''implique pas de montant additionnel ni à débourser ni à encaisser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Avis_Zero';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde des avis débiteurs traités (Cotisation totale+Somme Accaparée+Intérêts) lié à des conventions dont un montant additionnel sera à débourser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Avis_Debiteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde des avis créditeurs traités (Cotisation totale+Somme Accaparée+Intérêts) lié à des conventions dont un montant additionnel sera à encaisser par GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Avis_Crediteurs';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde de l''avis ficif créé (Cotisation totale+Somme Accaparée+Intérêts) calculé par Revenu Québec.  Les avis de cotisations fictifs font référence à des montants qui n’ont pu être attribués à un contrat en particulier pour une quelconque raison, principalement le fait que la transaction [T06] associée à cet impôt spécial ait été rejetée. Ce segment ne peut être retiré. Le seul traitement particulier requis est que vous identifiez les transactions en erreur, s’il y a lieu, et que vous les corrigiez.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Avis_Fictif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des soldes (Zéro, Débiteurs, Créditeurs et Fictif  (ainsi que l''avis fictif du fichier qui sera toujours dans les fichiers .COT)).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_Total_Avis';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Booléen pour confirmer que le total des soldes correspond à nos calculs effectués lors l''importation du fichier .COT avec la procédure stockée psIQEE_ImporterFichierCOT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'bSolde_Avis_Balance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Si bSolde_Avis_Balance est Faux, montant de l''écart des soldes entre nos calculs et les montants de Revenu Québec.  Si bSolde_Avis_Balance est Vrai, la valeur sera 0.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatistiquesImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mEcart_Solde_Total_Avis';

