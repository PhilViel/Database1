CREATE TABLE [dbo].[tblCONV_ConventionCategorie] (
    [ConventionCategoreId] INT           IDENTITY (1, 1) NOT NULL,
    [CategorieCode]        CHAR (3)      NOT NULL,
    [CategorieDescription] VARCHAR (100) NULL,
    CONSTRAINT [PK_CONV_ConventionCategorie] PRIMARY KEY CLUSTERED ([ConventionCategoreId] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie de convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionCategorie', @level2type = N'COLUMN', @level2name = N'ConventionCategoreId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique de trois lettres de la catégorie de convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionCategorie', @level2type = N'COLUMN', @level2name = N'CategorieCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la catégorie de convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionCategorie', @level2type = N'COLUMN', @level2name = N'CategorieDescription';

