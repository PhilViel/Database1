CREATE TABLE [dbo].[Mo_DocumentSource] (
    [DocSourceID]        [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [DocSourceClassName] [dbo].[MoCompanyName] NOT NULL,
    [DocSourceProcName]  [dbo].[MoCompanyName] NOT NULL,
    [DocSourceDesc]      [dbo].[MoDescoption]  NULL,
    [DocSourceType]      [dbo].[MoDescoption]  NULL,
    CONSTRAINT [PK_Mo_DocumentSource] PRIMARY KEY CLUSTERED ([DocSourceID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'UniSQL seulement - Table des sources de données des documents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la source de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource', @level2type = N'COLUMN', @level2name = N'DocSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table contenant l''objet sur lequel on trouvera le menu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource', @level2type = N'COLUMN', @level2name = N'DocSourceClassName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la procédure stockée (si DocSourceType = dbDatabase) ou de la fonction delphi (si DocSourceType = dbFunction) qui retourne les données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource', @level2type = N'COLUMN', @level2name = N'DocSourceProcName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de la source.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource', @level2type = N'COLUMN', @level2name = N'DocSourceDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nous dis si la procédure (DocSourceProcName) est une procédure Delphi(dbFunction) ou SQL(dbDatabase).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentSource', @level2type = N'COLUMN', @level2name = N'DocSourceType';

