CREATE TABLE [dbo].[Mo_Document] (
    [DocID]                [dbo].[MoID]              IDENTITY (1, 1) NOT NULL,
    [DocName]              [dbo].[MoCompanyName]     NOT NULL,
    [DocDesc]              [dbo].[MoDescoption]      NULL,
    [DocSeparator]         [dbo].[MoSeparatorOption] NULL,
    [DocSourceID]          [dbo].[MoID]              NOT NULL,
    [DocDynamicName]       [dbo].[MoLongDescoption]  NULL,
    [DocPrintDestination]  [dbo].[MoDesc]            NOT NULL,
    [DocPrinter]           [dbo].[MoDescoption]      NULL,
    [DocConfirmBeforeSave] [dbo].[MoBitTrue]         NOT NULL,
    [DocEditor]            [dbo].[MoDescoption]      NULL,
    [DocIsExtract]         [dbo].[MoBitFalse]        NOT NULL,
    [DocSubjectVisibility] [dbo].[MoCountry]         NULL,
    CONSTRAINT [PK_Mo_Document] PRIMARY KEY CLUSTERED ([DocID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Document_Mo_DocumentSource__DocSourceID] FOREIGN KEY ([DocSourceID]) REFERENCES [dbo].[Mo_DocumentSource] ([DocSourceID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Document_DocSourceID]
    ON [dbo].[Mo_Document]([DocSourceID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'UniSQL seulement - Table des documents.  Le module de document permet les fusions Word automatique de documents.  Cette table contient tout les documents que l''on peut fusionner.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du document. C''est ce nom qui apparaît dans les menus de l''application UniSQL.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description du document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Séparateur de document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocSeparator';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la source de données de ce document (Mo_DocumentSource).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom dynamique des fichiers Word de ce document.  Avec ce nom on crée le nom par défaut du document.  Les noms entre crochet sont remplacés par des valeurs de champs de la requête.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocDynamicName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Destination par défaut du document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocPrintDestination';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Imprimante par défaut utilisé pour ce document.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocPrinter';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant s''il faut demander une confirmation à l''usager avant la sauvegarde (=0:non, <>0:oui).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocConfirmBeforeSave';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l''éditeur de document à utiliser pour faire la fusion, par défaut Word.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocEditor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur True/False indiquant si le document a été extrait', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocIsExtract';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur liée à la visibilité du sujet du document', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Document', @level2type = N'COLUMN', @level2name = N'DocSubjectVisibility';

