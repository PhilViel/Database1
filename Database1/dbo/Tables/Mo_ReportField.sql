CREATE TABLE [dbo].[Mo_ReportField] (
    [ReportTableName]       [dbo].[MoDesc]       NOT NULL,
    [ReportFieldName]       [dbo].[MoDesc]       NOT NULL,
    [ReportFieldAlias]      [dbo].[MoDescoption] NULL,
    [ReportFieldDataType]   [dbo].[MoDescoption] NULL,
    [ReportFieldSelectable] [dbo].[MoCharoption] NULL,
    [ReportFieldSearchable] [dbo].[MoCharoption] NULL,
    [ReportFieldSortable]   [dbo].[MoCharoption] NULL,
    [ReportFieldAutosearch] [dbo].[MoCharoption] NULL,
    [ReportFieldMandatory]  [dbo].[MoCharoption] NULL,
    CONSTRAINT [PK_Mo_ReportField] PRIMARY KEY CLUSTERED ([ReportTableName] ASC, [ReportFieldName] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_ReportField_ReportTableName_ReportFieldAlias]
    ON [dbo].[Mo_ReportField]([ReportTableName] ASC, [ReportFieldAlias] ASC) WITH (FILLFACTOR = 90);


GO
GRANT DELETE
    ON OBJECT::[dbo].[Mo_ReportField] TO PUBLIC
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[Mo_ReportField] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_ReportField] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[Mo_ReportField] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables utilisé pour le générateur de rapport.  Cette table contient les colonnes de table disponibles pour le générateur rapport.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table qui contient la colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la colonne à l''affichage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldAlias';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de données contenues dans la colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldDataType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant l''on peut faire des recherches sur cette colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldSelectable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean indiquant l''on peut faire des tris sur cette colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldSortable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ autorecherche', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldAutosearch';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champ obligatoire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportField', @level2type = N'COLUMN', @level2name = N'ReportFieldMandatory';

