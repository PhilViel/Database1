CREATE TABLE [dbo].[Mo_DocumentLang] (
    [DocID]             [dbo].[MoID]         NOT NULL,
    [DocLangID]         CHAR (3)             NOT NULL,
    [DocLangDestDir]    [dbo].[MoDescoption] NULL,
    [DocLangDestName]   [dbo].[MoDescoption] NULL,
    [DocLangSourceName] [dbo].[MoDesc]       NOT NULL,
    CONSTRAINT [PK_Mo_DocumentLang] PRIMARY KEY CLUSTERED ([DocID] ASC, [DocLangID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_DocumentLang_Mo_Document__DocID] FOREIGN KEY ([DocID]) REFERENCES [dbo].[Mo_Document] ([DocID]),
    CONSTRAINT [FK_Mo_DocumentLang_Mo_Lang__DocLangID] FOREIGN KEY ([DocLangID]) REFERENCES [dbo].[Mo_Lang] ([LangID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'UniSQL seulement - Table des emplacements physiques des templates de documents selon la langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du document (Mo_Document) auquel appartient cet emplacement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang', @level2type = N'COLUMN', @level2name = N'DocID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la langue (Mo_Lang.LangID) du template trouvé à cet emplacement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang', @level2type = N'COLUMN', @level2name = N'DocLangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Emplacement physique de sauvegarde automatique des documents fusionnés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang', @level2type = N'COLUMN', @level2name = N'DocLangDestDir';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Inutilisé - Nom du fichier résultat (Remplacé par Mo_Document.DocDynamicName).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang', @level2type = N'COLUMN', @level2name = N'DocLangDestName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Emplacement et nom du template de ce document pour cette langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_DocumentLang', @level2type = N'COLUMN', @level2name = N'DocLangSourceName';

