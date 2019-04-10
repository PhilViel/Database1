CREATE TABLE [dbo].[Mo_Lang] (
    [LangID]              CHAR (3)       NOT NULL,
    [LangName]            [dbo].[MoDesc] NOT NULL,
    [vcLangueRapportSSRS] VARCHAR (10)   NULL,
    CONSTRAINT [PK_Mo_Lang] PRIMARY KEY CLUSTERED ([LangID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des langues.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Lang';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères de la langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Lang', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Lang', @level2type = N'COLUMN', @level2name = N'LangName';

