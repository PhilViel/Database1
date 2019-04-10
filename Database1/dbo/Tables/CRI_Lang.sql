CREATE TABLE [dbo].[CRI_Lang] (
    [iLangID]    INT          IDENTITY (1, 1) NOT NULL,
    [cLangCode]  CHAR (3)     NOT NULL,
    [vcLangName] VARCHAR (75) NOT NULL
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des langues pour le CRI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Lang';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Lang', @level2type = N'COLUMN', @level2name = N'iLangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de 3 caractères désignant la langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Lang', @level2type = N'COLUMN', @level2name = N'cLangCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La langue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRI_Lang', @level2type = N'COLUMN', @level2name = N'vcLangName';

