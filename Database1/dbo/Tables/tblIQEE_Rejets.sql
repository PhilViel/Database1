CREATE TABLE [dbo].[tblIQEE_Rejets] (
    [iID_Rejet]                    INT           IDENTITY (1, 1) NOT NULL,
    [iID_Fichier_IQEE]             INT           NOT NULL,
    [iID_Convention]               INT           NOT NULL,
    [iID_Validation]               INT           NOT NULL,
    [vcDescription]                VARCHAR (300) NOT NULL,
    [vcValeur_Reference]           VARCHAR (200) NULL,
    [vcValeur_Erreur]              VARCHAR (200) NULL,
    [iID_Lien_Vers_Erreur_1]       INT           NULL,
    [iID_Lien_Vers_Erreur_2]       INT           NULL,
    [iID_Lien_Vers_Erreur_3]       INT           NULL,
    [tCommentaires]                TEXT          NULL,
    [iID_Utilisateur_Modification] INT           NULL,
    [dtDate_Modification]          DATETIME      NULL,
    [siAnnee_Fiscale]              INT           NOT NULL,
    CONSTRAINT [PK_IQEE_Rejets] PRIMARY KEY CLUSTERED ([iID_Rejet] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_Rejets_IQEE_Fichiers__iIDFichierIQEE] FOREIGN KEY ([iID_Fichier_IQEE]) REFERENCES [dbo].[tblIQEE_Fichiers] ([iID_Fichier_IQEE]),
    CONSTRAINT [FK_IQEE_Rejets_IQEE_Validations__iIDValidation] FOREIGN KEY ([iID_Validation]) REFERENCES [dbo].[tblIQEE_Validations] ([iID_Validation])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Rejets_iIDConvention_siAnneeFiscale]
    ON [dbo].[tblIQEE_Rejets]([iID_Convention] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Fichier_IQEE], [iID_Validation], [iID_Lien_Vers_Erreur_1]);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_Rejets_siAnnee_Fiscale]
    ON [dbo].[tblIQEE_Rejets]([siAnnee_Fiscale] ASC, [iID_Fichier_IQEE] ASC, [iID_Rejet] ASC)
    INCLUDE([iID_Validation]);


GO
CREATE NONCLUSTERED INDEX [ixIQEE_Rejets__iIDFichier_siAnneeFiscale]
    ON [dbo].[tblIQEE_Rejets]([iID_Fichier_IQEE] ASC, [siAnnee_Fiscale] ASC)
    INCLUDE([iID_Rejet], [iID_Validation]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_1]
    ON [dbo].[tblIQEE_Rejets]([iID_Fichier_IQEE], [iID_Rejet]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_2]
    ON [dbo].[tblIQEE_Rejets]([iID_Validation], [iID_Fichier_IQEE]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_3]
    ON [dbo].[tblIQEE_Rejets]([iID_Fichier_IQEE], [iID_Lien_Vers_Erreur_1], [iID_Rejet]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_4]
    ON [dbo].[tblIQEE_Rejets]([iID_Rejet], [iID_Validation], [iID_Convention]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_5]
    ON [dbo].[tblIQEE_Rejets]([iID_Fichier_IQEE], [iID_Validation], [iID_Convention], [iID_Rejet]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_6]
    ON [dbo].[tblIQEE_Rejets]([iID_Rejet], [iID_Validation], [iID_Fichier_IQEE], [iID_Lien_Vers_Erreur_1]);


GO
CREATE STATISTICS [stat_tblIQEE_Rejets_7]
    ON [dbo].[tblIQEE_Rejets]([iID_Rejet], [iID_Convention], [iID_Fichier_IQEE], [iID_Lien_Vers_Erreur_1], [iID_Validation]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé unique d''une raison de rejet d''une transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_Rejets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Historique des raisons de rejet des transactions rejetées des différents types d''enregistrement en vertu des validations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Rejet';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du fichier IQÉÉ qui détermine le moment exacte du rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Fichier_IQEE';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention qui n''était pas valide pour la transaction en rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Convention';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la validation qui est à l''origine du rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Validation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la validation qui correspond au rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur qui a servie de référence à la validation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'vcValeur_Reference';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Valeur du champ en erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'vcValeur_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant qui sert de lien vers un enregistrement d''UniAccès qui est à l''origine de l''erreur.  Cette identifiant n''est pas modifié lors d''une fusion de bénéficiaires ou de souscripteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Lien_Vers_Erreur_1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant qui sert de lien vers un enregistrement d''UniAccès qui est à l''origine de l''erreur.  Cette identifiant n''est pas modifié lors d''une fusion de bénéficiaires ou de souscripteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Lien_Vers_Erreur_2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant qui sert de lien vers un enregistrement d''UniAccès qui est à l''origine de l''erreur.  Cette identifiant n''est pas modifié lors d''une fusion de bénéficiaires ou de souscripteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Lien_Vers_Erreur_3';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires des utilisateurs sur le rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'tCommentaires';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''utilisateur qui a fait la dernière modification du rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date et heure de la dernière modification au rejet.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_Rejets', @level2type = N'COLUMN', @level2name = N'dtDate_Modification';

