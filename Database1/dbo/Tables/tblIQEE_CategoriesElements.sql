CREATE TABLE [dbo].[tblIQEE_CategoriesElements] (
    [tiID_Categorie_Element] TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Categorie]       VARCHAR (3)  NOT NULL,
    [vcDescription]          VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_IQEE_CategoriesElements] PRIMARY KEY CLUSTERED ([tiID_Categorie_Element] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_CategoriesElements_vcCodeCategorie]
    ON [dbo].[tblIQEE_CategoriesElements]([vcCode_Categorie] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de catégorie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements', @level2type = N'INDEX', @level2name = N'IX_IQEE_CategoriesElements_vcCodeCategorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique des catégories d''éléments.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_CategoriesElements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des catégories d''éléments qui sont utilisées pour regrouper les validations qui cause les rejets de l''IQÉÉ afin de faciliter la recherche des validations et rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une catégorie d''éléments.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Element';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique identifiant la catégorie d''éléments qui peux être codé en dur au besoin.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements', @level2type = N'COLUMN', @level2name = N'vcCode_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la catégorie d''éléments.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesElements', @level2type = N'COLUMN', @level2name = N'vcDescription';

