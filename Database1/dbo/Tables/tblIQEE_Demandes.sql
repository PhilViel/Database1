CREATE TABLE [dbo].[tblIQEE_Demandes] (
    [iID_Demande_IQEE]                    INT          IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]                    INT          NOT NULL,
    [tiCode_Version]                      TINYINT      NOT NULL,
    [cStatut_Reponse]                     CHAR (1)     NOT NULL,
    [iID_Convention]                      INT          NOT NULL,
    [vcNo_Convention]                     VARCHAR (15) NOT NULL,
    [dtDate_Debut_Convention]             DATETIME     NOT NULL,
    [mCotisations]                        MONEY        NOT NULL,
    [mTransfert_IN]                       MONEY        NOT NULL,
    [mTotal_Cotisations_Subventionnables] MONEY        NOT NULL,
    [mTotal_Cotisations]                  MONEY        NULL,
    [iID_Beneficiaire_31Decembre]         INT          NOT NULL,
    [vcNAS_Beneficiaire]                  VARCHAR (9)  NOT NULL,
    [vcNom_Beneficiaire]                  VARCHAR (20) NOT NULL,
    [vcPrenom_Beneficiaire]               VARCHAR (20) NOT NULL,
    [tiSexe_Beneficiaire]                 TINYINT      NOT NULL,
    [dtDate_Naissance_Beneficiaire]       DATETIME     NOT NULL,
    [iID_Adresse_31Decembre_Beneficiaire] INT          NOT NULL,
    [tiNB_Annee_Quebec]                   TINYINT      NULL,
    [vcAppartement_Beneficiaire]          VARCHAR (6)  NULL,
    [vcNo_Civique_Beneficiaire]           VARCHAR (10) NOT NULL,
    [vcRue_Beneficiaire]                  VARCHAR (50) NOT NULL,
    [vcLigneAdresse2_Beneficiaire]        VARCHAR (14) NULL,
    [vcLigneAdresse3_Beneficiaire]        VARCHAR (40) NULL,
    [vcVille_Beneficiaire]                VARCHAR (30) NOT NULL,
    [vcProvince_Beneficiaire]             VARCHAR (2)  NOT NULL,
    [vcPays_Beneficiaire]                 VARCHAR (3)  NOT NULL,
    [vcCodePostal_Beneficiaire]           VARCHAR (10) NOT NULL,
    [bResidence_Quebec]                   BIT          NOT NULL,
    [iID_Souscripteur]                    INT          NOT NULL,
    [tiType_Souscripteur]                 TINYINT      NOT NULL,
    [vcNAS_Souscripteur]                  VARCHAR (9)  NULL,
    [vcNEQ_Souscripteur]                  VARCHAR (10) NULL,
    [vcNom_Souscripteur]                  VARCHAR (20) NOT NULL,
    [vcPrenom_Souscripteur]               VARCHAR (20) NULL,
    [tiID_Lien_Souscripteur]              TINYINT      NOT NULL,
    [iID_Adresse_Souscripteur]            INT          NULL,
    [vcAppartement_Souscripteur]          VARCHAR (6)  NULL,
    [vcNo_Civique_Souscripteur]           VARCHAR (10) NULL,
    [vcRue_Souscripteur]                  VARCHAR (50) NULL,
    [vcLigneAdresse2_Souscripteur]        VARCHAR (14) NULL,
    [vcLigneAdresse3_Souscripteur]        VARCHAR (40) NULL,
    [vcVille_Souscripteur]                VARCHAR (30) NULL,
    [vcProvince_Souscripteur]             VARCHAR (2)  NULL,
    [vcPays_Souscripteur]                 VARCHAR (3)  NULL,
    [vcCodePostal_Souscripteur]           VARCHAR (10) NULL,
    [vcTelephone_Souscripteur]            VARCHAR (10) NULL,
    [iID_Cosouscripteur]                  INT          NULL,
    [vcNAS_Cosouscripteur]                VARCHAR (9)  NULL,
    [vcNom_Cosouscripteur]                VARCHAR (20) NULL,
    [vcPrenom_Cosouscripteur]             VARCHAR (20) NULL,
    [tiID_Lien_Cosouscripteur]            TINYINT      NULL,
    [vcTelephone_Cosouscripteur]          VARCHAR (10) NULL,
    [tiType_Responsable]                  TINYINT      NULL,
    [vcNAS_Responsable]                   VARCHAR (9)  NULL,
    [vcNEQ_Responsable]                   VARCHAR (10) NULL,
    [vcNom_Responsable]                   VARCHAR (20) NULL,
    [vcPrenom_Responsable]                VARCHAR (20) NULL,
    [tiID_Lien_Responsable]               TINYINT      NULL,
    [vcAppartement_Responsable]           VARCHAR (6)  NULL,
    [vcNo_Civique_Responsable]            VARCHAR (10) NULL,
    [vcRue_Responsable]                   VARCHAR (50) NULL,
    [vcLigneAdresse2_Responsable]         VARCHAR (14) NULL,
    [vcLigneAdresse3_Responsable]         VARCHAR (40) NULL,
    [vcVille_Responsable]                 VARCHAR (30) NULL,
    [vcProvince_Responsable]              VARCHAR (2)  NULL,
    [vcPays_Responsable]                  VARCHAR (3)  NULL,
    [vcCodePostal_Responsable]            VARCHAR (10) NULL,
    [vcTelephone_Responsable]             VARCHAR (10) NULL,
    [bInd_Cession_IQEE]                   BIT          NOT NULL,
    [iID_Ligne_Fichier]                   INT          NULL,
    [siAnnee_Fiscale]                     INT          NOT NULL,
    CONSTRAINT [PK_IQEE_Demandes] PRIMARY KEY CLUSTERED ([iID_Demande_IQEE] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_Demandes_Convention__iIDConvention] FOREIGN KEY ([iID_Convention]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_IQEE_Demandes_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Demandes_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Demandes]([iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Demande_IQEE] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Demandes_vcNoConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Demandes]([vcNo_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Demande_IQEE] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Demandes_siAnnee_Fiscale]
    ON [dbo].[tblIQEE_Demandes]([siAnnee_Fiscale] ASC, [iID_Fichier_IQEE] ASC, [iID_Demande_IQEE] ASC)
    INCLUDE([tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Demandes_iIDBeneficiaire_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Demandes]([iID_Beneficiaire_31Decembre] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Demande_IQEE] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Demandes_iIDSouscripteur_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Demandes]([iID_Souscripteur] ASC, [iID_Convention] ASC, [siAnnee_Fiscale] ASC, [iID_Demande_IQEE] ASC)
    INCLUDE([iID_Fichier_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_Demandes__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Demande_IQEE], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_1]
    ON [dbo].[tblIQEE_Demandes]([iID_Beneficiaire_31Decembre], [iID_Fichier_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_2]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE], [tiCode_Version]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_3]
    ON [dbo].[tblIQEE_Demandes]([tiCode_Version], [iID_Fichier_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_4]
    ON [dbo].[tblIQEE_Demandes]([iID_Demande_IQEE], [tiCode_Version]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_5]
    ON [dbo].[tblIQEE_Demandes]([tiCode_Version], [cStatut_Reponse], [iID_Convention]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_6]
    ON [dbo].[tblIQEE_Demandes]([cStatut_Reponse], [tiCode_Version], [iID_Convention]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_7]
    ON [dbo].[tblIQEE_Demandes]([iID_Convention], [iID_Fichier_IQEE], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_8]
    ON [dbo].[tblIQEE_Demandes]([cStatut_Reponse], [tiCode_Version], [iID_Beneficiaire_31Decembre]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_9]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE], [iID_Demande_IQEE], [iID_Beneficiaire_31Decembre]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_10]
    ON [dbo].[tblIQEE_Demandes]([tiCode_Version], [iID_Convention], [iID_Demande_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_11]
    ON [dbo].[tblIQEE_Demandes]([cStatut_Reponse], [iID_Demande_IQEE], [iID_Fichier_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_12]
    ON [dbo].[tblIQEE_Demandes]([iID_Convention], [tiCode_Version], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_13]
    ON [dbo].[tblIQEE_Demandes]([iID_Demande_IQEE], [iID_Fichier_IQEE], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_14]
    ON [dbo].[tblIQEE_Demandes]([iID_Demande_IQEE], [iID_Convention], [cStatut_Reponse], [tiCode_Version]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_15]
    ON [dbo].[tblIQEE_Demandes]([cStatut_Reponse], [iID_Beneficiaire_31Decembre], [iID_Fichier_IQEE], [tiCode_Version]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_16]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE], [iID_Convention], [iID_Demande_IQEE], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_17]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE], [iID_Convention], [dtDate_Debut_Convention], [cStatut_Reponse]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_18]
    ON [dbo].[tblIQEE_Demandes]([cStatut_Reponse], [tiCode_Version], [iID_Fichier_IQEE], [iID_Convention], [dtDate_Debut_Convention]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_19]
    ON [dbo].[tblIQEE_Demandes]([tiSexe_Beneficiaire], [iID_Demande_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Demandes_20]
    ON [dbo].[tblIQEE_Demandes]([iID_Fichier_IQEE], [iID_Demande_IQEE], [iID_Convention], [tiCode_Version]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des demandes à l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Demandes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des transactions de demandes à l''IQÉÉ qui correspondent au type d''enregistrement 02 des NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une demande à l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Demande_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier de transactions associé à la demande d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de version de la transaction.  Il fait référence à la table "tblIQEE_VersionsTransaction".  0=Originale, 1=Annulation, 2=Reprise  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiCode_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de la transaction.  Il correspond à la table de référence "tblIQEE_StatutsTransaction"   A=En attente d''une réponse, E=En erreur, R=Réponse reçue (positive ou négative), D=Annulation en attente d''une réponse, T=Transaction annulée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'cStatut_Reponse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention de la demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de la convention de la demande.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNo_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de début de la convention de la demande.  La date de début de convention est souvent différente des autres date de début parce qu''elle comprend la date de signature contrairement à la date de début de régime par exemple.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'dtDate_Debut_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de cotisation annuelle.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'mCotisations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant de cotisation annuelle issu d''un transfert.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'mTransfert_IN';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant des cotisations annuelles subventionnables.  Correspond à la somme des cotisations faites chez GUI et les cotisations faites dans l''année fiscale chez les concurrents avant un transfert chez GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations_Subventionnables';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Montant total des cotisations versées au régime.  C''est un plafond, les retraits ne compte pas dans le calcul de ce montant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'mTotal_Cotisations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du bénéficiaire au 31 décembre de l''année fiscale de la demande de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Beneficiaire_31Decembre';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNAS_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPrenom_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Sexe du bénéficiaire. (1=Féminin, 2=Masculin)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiSexe_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de naissance du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'dtDate_Naissance_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''adresse au 31 décembre de l''année fiscale de la demande du bénéficiaire à la même date.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Adresse_31Decembre_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nombre d''années où le bénéficiaire résidait au Québec depuis 2007 ou depuis sa naissance s''il est né après 2007.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiNB_Annee_Quebec';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''appartement du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcAppartement_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcRue_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcVille_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcProvince_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de pays du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPays_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Beneficiaire';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le bénéficiaire réside ou non au Québec.  L''adresse peux être au Québec dans UniAccès, mais ne pas être bonne ou à jour.  Il est donc possible que l''adresse du bénéficiaire de la transaction soit au Québec alors que l''indicateur de résidence sera à faux.  L''inverse est aussi possible.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'bResidence_Quebec';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du souscripteur à la date de la création de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de souscripteur. (1=Particulier, 2=Entreprise)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiType_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNAS_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''''entreprise du Québec du souscripteur entreprise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNEQ_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNom_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPrenom_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de lien entre le souscripteur et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiID_Lien_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''adresse du souscripteur à la date de création de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Adresse_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Appartement du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcAppartement_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcRue_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcVille_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcProvince_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPays_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de téléphone du souscripteur.  Seul les numéros à 7 ou 10 chiffres sont retenus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcTelephone_Souscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du co-souscripteur à la date de création de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNAS_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNom_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du co-souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPrenom_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de lien entre le co-souscripteur et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiID_Lien_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de téléphone du co-souscripteur.  Seul les numéros à 7 ou 10 chiffres sont retenus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcTelephone_Cosouscripteur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de reponsable principal. (1=Particulier, 2=Entreprise)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiType_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'NAS du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNAS_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro d''entreprise du Québec du principal responsable entreprise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNEQ_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNom_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Prénom du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPrenom_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Type de lien entre le principal responsable et le bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'tiID_Lien_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Appartement du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcAppartement_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro civique du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcNo_Civique_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rue du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcRue_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 2 du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse2_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ligne d''adresse 3 du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcLigneAdresse3_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ville du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcVille_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de province du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcProvince_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Pays du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcPays_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code postal du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcCodePostal_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro de téléphone du principal responsable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'vcTelephone_Responsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si GUI cède l''IQÉÉ au promoteur extérieur suite à un transfert total.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'bInd_Cession_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la ligne correspondante à la transaction du fichier physique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Demandes', @level2type = N'COLUMN', @level2name = N'iID_Ligne_Fichier';

