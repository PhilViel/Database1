CREATE TABLE [dbo].[tblIQEE_ImpotsSpeciaux] (
    [iID_Impot_Special]                        INT           IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]                         INT           NOT NULL,
    [tiCode_Version]                           TINYINT       NOT NULL,
    [cStatut_Reponse]                          CHAR (1)      NOT NULL,
    [iID_Convention]                           INT           NOT NULL,
    [vcNo_Convention]                          VARCHAR (15)  NOT NULL,
    [iID_Sous_Type]                            INT           NOT NULL,
    [iID_Remplacement_Beneficiaire]            INT           NULL,
    [iID_Transfert]                            INT           NULL,
    [iID_Operation]                            INT           NULL,
    [iID_Cotisation]                           INT           NULL,
    [iID_RI]                                   INT           NULL,
    [iID_Cheque]                               INT           NULL,
    [iID_Statut_Convention]                    INT           NULL,
    [dtDate_Evenement]                         DATETIME      NOT NULL,
    [mCotisations_Retirees]                    MONEY         NULL,
    [mSolde_IQEE_Base]                         MONEY         NULL,
    [mSolde_IQEE_Majore]                       MONEY         NULL,
    [mIQEE_ImpotSpecial]                       MONEY         NULL,
    [mRadiation]                               MONEY         NULL,
    [mCotisations_Donne_Droit_IQEE]            MONEY         NULL,
    [mJuste_Valeur_Marchande]                  MONEY         NULL,
    [mBEC]                                     MONEY         NULL,
    [mSubvention_Canadienne]                   MONEY         NULL,
    [mSolde_IQEE]                              MONEY         NULL,
    [iID_Beneficiaire]                         INT           NOT NULL,
    [vcNAS_Beneficiaire]                       VARCHAR (9)   NOT NULL,
    [vcNom_Beneficiaire]                       VARCHAR (20)  NOT NULL,
    [vcPrenom_Beneficiaire]                    VARCHAR (20)  NOT NULL,
    [dtDate_Naissance_Beneficiaire]            DATETIME      NOT NULL,
    [tiSexe_Beneficiaire]                      TINYINT       NOT NULL,
    [vcCode_Postal_Etablissement]              VARCHAR (10)  NULL,
    [vcNom_Etablissement]                      VARCHAR (150) NULL,
    [iID_Ligne_Fichier]                        INT           NULL,
    [iID_Paiement_Impot_CBQ]                   INT           NULL,
    [iID_Paiement_Impot_MMQ]                   INT           NULL,
    [mMontant_A]                               MONEY         NULL,
    [mMontant_B]                               MONEY         NULL,
    [mMontant_C]                               MONEY         NULL,
    [mMontant_AFixe]                           MONEY         NULL,
    [mEcart_ReelvsFixe]                        MONEY         NULL,
    [iID_Transaction_Convention_CBQ_Renversee] INT           NULL,
    [iID_Transaction_Convention_MMQ_Renversee] INT           NULL,
    [siAnnee_Fiscale]                          INT           NOT NULL,
    CONSTRAINT [PK_IQEE_ImpotsSpeciaux] PRIMARY KEY CLUSTERED ([iID_Impot_Special] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_ConventionOper_CBQ] FOREIGN KEY ([iID_Paiement_Impot_CBQ]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_ConventionOper_CBQ_Renversee] FOREIGN KEY ([iID_Transaction_Convention_CBQ_Renversee]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_ConventionOper_MMQ] FOREIGN KEY ([iID_Paiement_Impot_MMQ]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_ConventionOper_MMQ_Renversee] FOREIGN KEY ([iID_Transaction_Convention_MMQ_Renversee]) REFERENCES [dbo].[Un_ConventionOper] ([ConventionOperID]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_ImpotsSpeciaux_IQEE_SousTypeEnregistrement__iIDSousType] FOREIGN KEY ([iID_Sous_Type]) REFERENCES [dbo].[tblIQEE_SousTypeEnregistrement] ([iID_Sous_Type])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ImpotsSpeciaux_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_ImpotsSpeciaux]([iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Impot_Special] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ImpotsSpeciaux_vcNoConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_ImpotsSpeciaux]([vcNo_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Impot_Special] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ImpotsSpeciaux_siAnnee_Fiscale]
    ON [dbo].[tblIQEE_ImpotsSpeciaux]([siAnnee_Fiscale] ASC, [iID_Fichier_IQEE] ASC, [iID_Impot_Special] ASC)
    INCLUDE([iID_Sous_Type], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_ImpotsSpeciaux_iIDBeneficiaire_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_ImpotsSpeciaux]([iID_Beneficiaire] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Impot_Special] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_ImpotsSpeciaux__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_ImpotsSpeciaux]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Impot_Special], [iID_Sous_Type], [tiCode_Version], [cStatut_Reponse]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de l''identifiant unique des transactions d''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_ImpotsSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des transactions de l''IQÉÉ de type 06 - Impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de l''IQÉÉ de type 06 - Impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Impot_Special';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de transactions de l''IQÉÉ associé à la transaction de type 06.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de version de la transaction.  Il fait référence à la table "tblIQEE_VersionsTransaction".  0=Originale, 1=Annulation, 2=Reprise  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'tiCode_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de la transaction.  Il correspond à la table de référence "tblIQEE_StatutsTransaction"   A=En attente d''une réponse, E=En erreur, R=Réponse reçue (positive ou négative), D=Annulation en attente d''une réponse, T=Transaction annulée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'cStatut_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention fesant l''objet d''un impôt spécial.  La convention doit être connue de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention fesant l''objet d''un impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcNo_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du sous type de l''enregistrement d''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de type 03 - Remplacement de bénéficiaire.  S''applique aux impôts spéciaux de sous type 01.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Remplacement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de type 04 - Transfert entre régimes.  S''applique aux impôts spéciaux de sous type 11.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Transfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération à l''origine de l''impôt spécial.  Ce champ s''applique aux impôts spéciaux de sous type 23, 24, 31, 32 et 41.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la cotisation à l''origine de l''impôt spécial.  Ce champ s''applique aux impôts spéciaux de sous type 23 et 24.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de remboursement intégral d''où proviennent les informations sur les études pour une transaction d''impôt spécial de sous type 23.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_RI';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du chèque résultant de l''opération à l''origine de l''impôt spécial.  Ce champ s''applique aux impôts spéciaux de sous type 23, 24, 31, 32 et 41.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Cheque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du changement de statut de la convention à l''origine de l''impôt spécial.  Ce champ s''applique à l''impôt spécial de sous type 91.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Statut_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de l''événement d''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'dtDate_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de cotisations retirées dans le cas d''un retrait de cotisations (sous type 22, 23 et 24).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mCotisations_Retirees';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de l''IQÉÉ de base à rembourser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_IQEE_Base';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de l''IQÉÉ majoré à rembourser.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_IQEE_Majore';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant d''IQÉÉ remboursé à RQ suite à l''événement d''impôt spécial (mSoldeIQEE_Base + mSoldeIQEE_Majore).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mIQEE_ImpotSpecial';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de radiation.  Montant d''IQÉÉ non remboursé dans le cas d''un compte à perte pour les sous type 51 et 91.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mRadiation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total de cotisations ayant donné droit à l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mCotisations_Donne_Droit_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de la juste valeur marchande de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mJuste_Valeur_Marchande';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de BEC.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mBEC';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des subventions canadiennes SCEE et SCEE bonifié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSubvention_Canadienne';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Solde de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'mSolde_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcNAS_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcNom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcPrenom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de naissance du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'dtDate_Naissance_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sexe du du bénéficiaire affecté par l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'tiSexe_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal de l''établissement d''enseignement qui bénificie d''un paiement.  Ce champ s''applique au sous type d''impôt spécial 31.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcCode_Postal_Etablissement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de l’établissement d’enseignement qui bénificie d''un paiement.  Ce champ s''applique au sous type d''impôt spécial 31.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'vcNom_Etablissement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la ligne correspondante à la transaction du fichier physique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Ligne_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction CBQ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Paiement_Impot_CBQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la transaction MMQ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Paiement_Impot_MMQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération CBQ de renversement lors de l''importation d''une erreur liée à la déclaration de l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Convention_CBQ_Renversee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération MMQ de renversement lors de l''importation d''une erreur liée à la déclaration de l''impôt spécial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_ImpotsSpeciaux', @level2type = N'COLUMN', @level2name = N'iID_Transaction_Convention_MMQ_Renversee';

