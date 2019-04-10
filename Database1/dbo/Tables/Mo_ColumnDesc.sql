CREATE TABLE [dbo].[Mo_ColumnDesc] (
    [TableName]  [dbo].[MoDesc] NOT NULL,
    [ColumnName] [dbo].[MoDesc] NOT NULL,
    [ColumnDesc] [dbo].[MoDesc] NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des descriptions colonnes des tables.  C''est pour les logs, afin d''avoir une description du champs plus lisible que le nom du champs lui-même.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ColumnDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table à laquelle appartient la colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ColumnDesc', @level2type = N'COLUMN', @level2name = N'TableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la colonne.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ColumnDesc', @level2type = N'COLUMN', @level2name = N'ColumnName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de la colonne plus compréhensible pour l''usager que le nom du champs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ColumnDesc', @level2type = N'COLUMN', @level2name = N'ColumnDesc';

