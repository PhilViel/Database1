CREATE TABLE [dbo].[Mo_ReportTable] (
    [ReportTableName]  [dbo].[MoDesc] NOT NULL,
    [ReportTableAlias] [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Mo_ReportTable] PRIMARY KEY CLUSTERED ([ReportTableName] ASC) WITH (FILLFACTOR = 90)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[Mo_ReportTable] TO PUBLIC
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[Mo_ReportTable] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_ReportTable] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[Mo_ReportTable] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables utilisé pour le générateur de rapport.  Cette table contient la liste des tables disponibles.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportTable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportTable', @level2type = N'COLUMN', @level2name = N'ReportTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table é l''affichage.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportTable', @level2type = N'COLUMN', @level2name = N'ReportTableAlias';

