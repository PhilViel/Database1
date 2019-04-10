CREATE TABLE [dbo].[tblIQEE_JustificationsRQ] (
    [tiID_Justification_RQ]           TINYINT       IDENTITY (1, 1) NOT NULL,
    [cCode]                           CHAR (2)      NOT NULL,
    [vcDescription]                   VARCHAR (250) NOT NULL,
    [tiID_Categorie_Justification_RQ] TINYINT       NOT NULL,
    CONSTRAINT [PK_IQEE_JustificationsRQ] PRIMARY KEY CLUSTERED ([tiID_Justification_RQ] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_JustificationsRQ_IQEE_CategorieJustification__tiIDCategorieJustificationRQ] FOREIGN KEY ([tiID_Categorie_Justification_RQ]) REFERENCES [dbo].[tblIQEE_CategorieJustification] ([tiID_Categorie_Justification_RQ])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_JustificationsRQ_tiIDCategorieJustificationRQ]
    ON [dbo].[tblIQEE_JustificationsRQ]([tiID_Categorie_Justification_RQ] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_JustificationsRQ_cCode]
    ON [dbo].[tblIQEE_JustificationsRQ]([cCode] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identification de la catégorie de justification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'INDEX', @level2name = N'IX_IQEE_JustificationsRQ_tiIDCategorieJustificationRQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de justification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'INDEX', @level2name = N'AK_IQEE_JustificationsRQ_cCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des justifications de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_JustificationsRQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des justifications de RQ sur l''IQÉÉ provenant de l''annexe 3 des NID.  Les justifications de RQ sont des réponses à des transactions de demandes d''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une justification de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'COLUMN', @level2name = N'tiID_Justification_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de la justification.  Ce champ peut être codé en dur dans la programmation.  Il correspond au code de l''annexe 3 des NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'COLUMN', @level2name = N'cCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la justification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie de la justification.  Correspond à la table de référence "tblIQEE_CategorieJustification".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_JustificationsRQ', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Justification_RQ';

