CREATE TABLE [dbo].[CRQ_WorldLang] (
    [WorldLanguageCodeID] VARCHAR (3)  NOT NULL,
    [WorldLanguage]       VARCHAR (75) NULL,
    CONSTRAINT [PK_CRQ_WorldLang] PRIMARY KEY CLUSTERED ([WorldLanguageCodeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Contient les langues du monde avec les codes fournis par le gouvernment.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_WorldLang';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID Unique de trois lettres représentant la langue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_WorldLang', @level2type = N'COLUMN', @level2name = N'WorldLanguageCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'La langue', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_WorldLang', @level2type = N'COLUMN', @level2name = N'WorldLanguage';

