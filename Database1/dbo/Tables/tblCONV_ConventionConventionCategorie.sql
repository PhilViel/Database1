CREATE TABLE [dbo].[tblCONV_ConventionConventionCategorie] (
    [ConventionConventionCategorieId] INT IDENTITY (1, 1) NOT NULL,
    [ConventionId]                    INT NOT NULL,
    [ConventionCategorieId]           INT NOT NULL,
    CONSTRAINT [PK_CONV_ConventionConventionCategorie] PRIMARY KEY CLUSTERED ([ConventionConventionCategorieId] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du lien convention et catégorie de convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionConventionCategorie', @level2type = N'COLUMN', @level2name = N'ConventionConventionCategorieId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionConventionCategorie', @level2type = N'COLUMN', @level2name = N'ConventionId';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie de convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_ConventionConventionCategorie', @level2type = N'COLUMN', @level2name = N'ConventionCategorieId';

