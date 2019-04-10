CREATE TABLE [dbo].[Mo_ReportJoin] (
    [ReportTableName1]    [dbo].[MoDesc]           NOT NULL,
    [ReportTableName2]    [dbo].[MoDesc]           NOT NULL,
    [ReportJoinType]      [dbo].[MoDescoption]     NULL,
    [ReportFieldNames1]   [dbo].[MoLongDescoption] NULL,
    [ReportJoinOperators] [dbo].[MoDescoption]     NULL,
    [ReportFieldNames2]   [dbo].[MoLongDescoption] NULL,
    CONSTRAINT [PK_Mo_ReportJoin] PRIMARY KEY CLUSTERED ([ReportTableName1] ASC, [ReportTableName2] ASC) WITH (FILLFACTOR = 90)
);


GO
GRANT DELETE
    ON OBJECT::[dbo].[Mo_ReportJoin] TO PUBLIC
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[Mo_ReportJoin] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_ReportJoin] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[Mo_ReportJoin] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables utilisé pour le générateur de rapport.  Cette table contient les jointures possibles entres tables.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la première table de la jointure.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportTableName1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la deuxième table de la jointure.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportTableName2';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de jointure.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportJoinType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du champs sur lequel on fait la jointure de la première table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportFieldNames1';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Opérateur lien les deux champs des tables la jointure. (Ex: =, <, >, <>)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportJoinOperators';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du champs sur lequel on fait la jointure de la deuxième table .', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportJoin', @level2type = N'COLUMN', @level2name = N'ReportFieldNames2';

