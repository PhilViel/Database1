CREATE TABLE [dbo].[tblIQEE_Transferts] (
    [iID_Transfert]                         INT          IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]                      INT          NOT NULL,
    [tiCode_Version]                        TINYINT      NOT NULL,
    [cStatut_Reponse]                       CHAR (1)     NOT NULL,
    [iID_Convention]                        INT          NOT NULL,
    [vcNo_Convention]                       VARCHAR (15) NOT NULL,
    [dtDate_Debut_Convention]               DATETIME     NOT NULL,
    [iID_Sous_Type]                         INT          NOT NULL,
    [iID_Operation]                         INT          NULL,
    [iID_TIO]                               INT          NULL,
    [iID_Operation_RIO]                     INT          NULL,
    [iID_Cotisation]                        INT          NULL,
    [iID_Cheque]                            INT          NULL,
    [dtDate_Transfert]                      DATETIME     NOT NULL,
    [mTotal_Transfert]                      MONEY        NOT NULL,
    [mIQEE_CreditBase_Transfere]            MONEY        CONSTRAINT [DF_IQEE_Transferts_mIQEECreditBaseTransfere] DEFAULT ((0)) NOT NULL,
    [mIQEE_Majore_Transfere]                MONEY        CONSTRAINT [DF_IQEE_Transferts_mIQEEMajoreTransfere] DEFAULT ((0)) NOT NULL,
    [mCotisations_Donne_Droit_IQEE]         MONEY        NOT NULL,
    [ID_Autre_Promoteur]                    VARCHAR (10) NOT NULL,
    [ID_Regime_Autre_Promoteur]             VARCHAR (15) NOT NULL,
    [vcNo_Contrat_Autre_Promoteur]          VARCHAR (15) NOT NULL,
    [iID_Beneficiaire]                      INT          NOT NULL,
    [vcNAS_Beneficiaire]                    VARCHAR (9)  NOT NULL,
    [vcNom_Beneficiaire]                    VARCHAR (20) NOT NULL,
    [vcPrenom_Beneficiaire]                 VARCHAR (20) NOT NULL,
    [dtDate_Naissance_Beneficiaire]         DATETIME     NOT NULL,
    [tiSexe_Beneficiaire]                   TINYINT      NOT NULL,
    [iID_Adresse_Beneficiaire]              INT          NULL,
    [vcAppartement_Beneficiaire]            VARCHAR (6)  NULL,
    [vcNo_Civique_Beneficiaire]             VARCHAR (10) NULL,
    [vcRue_Beneficiaire]                    VARCHAR (50) NULL,
    [vcLigneAdresse2_Beneficiaire]          VARCHAR (14) NULL,
    [vcLigneAdresse3_Beneficiaire]          VARCHAR (40) NULL,
    [vcVille_Beneficiaire]                  VARCHAR (30) NULL,
    [vcProvince_Beneficiaire]               VARCHAR (2)  NULL,
    [vcPays_Beneficiaire]                   VARCHAR (3)  NULL,
    [vcCodePostal_Beneficiaire]             VARCHAR (10) NULL,
    [bTransfert_Total]                      BIT          NULL,
    [bPRA_Deja_Verse]                       BIT          NULL,
    [mJuste_Valeur_Marchande]               MONEY        NULL,
    [mBEC]                                  MONEY        NULL,
    [bTransfert_Autorise]                   BIT          NULL,
    [iID_Souscripteur]                      INT          NULL,
    [tiType_Souscripteur]                   TINYINT      NULL,
    [vcNAS_Souscripteur]                    VARCHAR (9)  NULL,
    [vcNEQ_Souscripteur]                    VARCHAR (10) NULL,
    [vcNom_Souscripteur]                    VARCHAR (20) NULL,
    [vcPrenom_Souscripteur]                 VARCHAR (20) NULL,
    [tiID_Lien_Souscripteur]                TINYINT      NULL,
    [iID_Adresse_Souscripteur]              INT          NULL,
    [vcAppartement_Souscripteur]            VARCHAR (6)  NULL,
    [vcNo_Civique_Souscripteur]             VARCHAR (10) NULL,
    [vcRue_Souscripteur]                    VARCHAR (50) NULL,
    [vcLigneAdresse2_Souscripteur]          VARCHAR (14) NULL,
    [vcLigneAdresse3_Souscripteur]          VARCHAR (40) NULL,
    [vcVille_Souscripteur]                  VARCHAR (30) NULL,
    [vcProvince_Souscripteur]               VARCHAR (2)  NULL,
    [vcPays_Souscripteur]                   VARCHAR (3)  NULL,
    [vcCodePostal_Souscripteur]             VARCHAR (10) NULL,
    [iID_Cosouscripteur]                    INT          NULL,
    [vcNAS_Cosouscripteur]                  VARCHAR (9)  NULL,
    [vcNom_Cosouscripteur]                  VARCHAR (20) NULL,
    [vcPrenom_Cosouscripteur]               VARCHAR (20) NULL,
    [tiID_Lien_Cosouscripteur]              TINYINT      NULL,
    [mCotisations_Versees_Avant_Debut_IQEE] MONEY        CONSTRAINT [DF_IQEE_Transferts_mCotisationsVerseesAvantDebutIQEE] DEFAULT ((0)) NOT NULL,
    [mCotisations_Non_Donne_Droit_IQEE]     MONEY        NOT NULL,
    [iID_Ligne_Fichier]                     INT          NULL,
    [siAnnee_Fiscale]                       INT          NOT NULL,
    CONSTRAINT [PK_IQEE_Transferts] PRIMARY KEY CLUSTERED ([iID_Transfert] ASC),
    CONSTRAINT [FK_IQEE_Transferts_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_IQEE_Transferts_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_Transferts_IQEE_SousTypeEnregistrement__iIDSousType] FOREIGN KEY ([iID_Sous_Type]) REFERENCES [dbo].[tblIQEE_SousTypeEnregistrement] ([iID_Sous_Type])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Transferts_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Transferts]([iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Transfert] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Transferts_vcNoConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Transferts]([vcNo_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Transfert] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Transferts_siAnnee_Fiscale]
    ON [dbo].[tblIQEE_Transferts]([siAnnee_Fiscale] ASC, [iID_Fichier_IQEE] ASC, [iID_Transfert] ASC)
    INCLUDE([iID_Sous_Type], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Transferts_iIDBeneficiaire_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Transferts]([iID_Beneficiaire] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Transfert] ASC)
    INCLUDE([iID_Sous_Type], [iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_Transferts__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_Transferts]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Transfert], [tiCode_Version], [cStatut_Reponse]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''un transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Transferts';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des transactions de l''IQÉÉ de type 04 - Transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une transaction de type 04 - Transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Transfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de transactions de l''IQÉÉ associé à la transaction de type 04.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de version de la transaction.  Il fait référence à la table "tblIQEE_VersionsTransaction".  0=Originale, 1=Annulation, 2=Reprise  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'tiCode_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de la transaction.  Il correspond à la table de référence "tblIQEE_StatutsTransaction"   A=En attente d''une réponse, E=En erreur, R=Réponse reçue (positive ou négative), D=Annulation en attente d''une réponse, T=Transaction annulée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'cStatut_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention fesant l''objet d''un transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention fesant l''objet d''un transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNo_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début de la convention.  La date de début de convention est souvent différente des autres date de début parce qu''elle comprend la date de signature contrairement à la date de début de régime par exemple.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du sous type de l''enregistrement de transfert (01 pour fiduciaire cédant ou 02 pour fiduciaire cessionnaire).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Sous_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''opération de transfert dans UniAccès à l''origine de la transaction de transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique des informations de transfert IN/OUT dans UniAccès à l''origine de la transaction de transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_TIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique des informations de l''opération RIO dans UniAccès à l''origine de la transaction de transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Operation_RIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la cotisation dans UniAccès à l''origine de la transaction de transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Cotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du chèque dans UniAccès associé à l''opération à l''origine de la transaction de transfert entre régimes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Cheque';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date effective du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'dtDate_Transfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant global du transfert (pour l’ensemble des bénéficiaires impliqués dans le transfert).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'mTotal_Transfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme IQEE impliquée dans le transfert (pour le bénéficiaire indiqué seulement).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'mIQEE_CreditBase_Transfere';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme à l’origine utilisée pour le calcul de l’IQEE et qui est transférée (pour le bénéficiaire indiqué seulement).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'mCotisations_Donne_Droit_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la compagnie de l''autre promoteur impliqué dans le transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'ID_Autre_Promoteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du régime de l''autre promoteur impliqué dans le transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'ID_Regime_Autre_Promoteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de contrat de l''autre promoteur impliqué dans le transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNo_Contrat_Autre_Promoteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNAS_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcPrenom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de naissance du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'dtDate_Naissance_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sexe du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'tiSexe_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''adresse du bénéficiaire du transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Adresse_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''appartement du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcAppartement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcRue_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcVille_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcProvince_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcPays_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le transfert est un transfert partiel ou total.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'bTransfert_Total';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur de paiement de revenu accumulé déjà versé avant le transfert (Seule la valeur 0 est permise).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'bPRA_Deja_Verse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le transfert est autorisé ou non.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'bTransfert_Autorise';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de souscripteur (1=Particulier, 2=Entreprise)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'tiType_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNAS_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du Québec du souscripteur entreprise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNEQ_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNom_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcPrenom_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de lien entre le souscripteur et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'tiID_Lien_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''adresse du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Adresse_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Appartement du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcAppartement_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcRue_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcVille_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcProvince_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcPays_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNAS_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcNom_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'vcPrenom_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de lien entre le co-souscripteur et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'tiID_Lien_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Somme qui n’a pas été utilisée à l’origine pour le calcul de l’IQEE et qui est transférée (pour le bénéficiaire indiqué seulement).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'mCotisations_Non_Donne_Droit_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la ligne correspondante à la transaction du fichier physique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Transferts', @level2type = N'COLUMN', @level2name = N'iID_Ligne_Fichier';

