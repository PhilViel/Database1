CREATE TABLE [dbo].[CRQ_ColumnDesc] (
    [TableName]  VARCHAR (75) NOT NULL,
    [ColumnName] VARCHAR (75) NOT NULL,
    [LangID]     CHAR (3)     NOT NULL,
    [ColumnDesc] VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_CRQ_ColumnDesc] PRIMARY KEY CLUSTERED ([TableName] ASC, [ColumnName] ASC, [LangID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les descriptions des colonnes dans différentes langues', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_ColumnDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant la colonne', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_ColumnDesc', @level2type = N'COLUMN', @level2name = N'TableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Colonne', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_ColumnDesc', @level2type = N'COLUMN', @level2name = N'ColumnName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Langue de la description', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_ColumnDesc', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de la colonne', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_ColumnDesc', @level2type = N'COLUMN', @level2name = N'ColumnDesc';

