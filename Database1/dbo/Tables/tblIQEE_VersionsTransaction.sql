CREATE TABLE [dbo].[tblIQEE_VersionsTransaction] (
    [tiID_Version_Transaction] TINYINT      IDENTITY (1, 1) NOT NULL,
    [tiCode_Version]           TINYINT      NOT NULL,
    [vcDescription]            VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_IQEE_VersionsTransaction] PRIMARY KEY CLUSTERED ([tiID_Version_Transaction] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_VersionsTransaction_tiCodeVersion]
    ON [dbo].[tblIQEE_VersionsTransaction]([tiCode_Version] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de version.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction', @level2type = N'INDEX', @level2name = N'AK_IQEE_VersionsTransaction_tiCodeVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique des versions de transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_VersionsTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des versions de transaction.  Le but de cette table est principalement d''avoir une description pour l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une version de transaction de l''IQÉÉ.  Il n''est pas utilisé dans les tables des transactions parce que cette table a été créée après la création des tables des transactions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction', @level2type = N'COLUMN', @level2name = N'tiID_Version_Transaction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de la version qui correspond aux valeurs des champs "Code de version de la transaction" des NID de l''IQÉÉ.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction', @level2type = N'COLUMN', @level2name = N'tiCode_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du code de la version.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_VersionsTransaction', @level2type = N'COLUMN', @level2name = N'vcDescription';

