CREATE TABLE [dbo].[tblOPER_CategoriesOperation] (
    [iID_Categorie_Oper] INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Categorie]   VARCHAR (100) NOT NULL,
    [vcDescription]      TEXT          NOT NULL,
    CONSTRAINT [PK_OPER_CategoriesOperation] PRIMARY KEY CLUSTERED ([iID_Categorie_Oper] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_OPER_CategoriesOperation_vcCodeCategorie]
    ON [dbo].[tblOPER_CategoriesOperation]([vcCode_Categorie] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de catégorie d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation', @level2type = N'INDEX', @level2name = N'AK_OPER_CategoriesOperation_vcCodeCategorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire des catégories d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation', @level2type = N'CONSTRAINT', @level2name = N'PK_OPER_CategoriesOperation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Catégorie d''opérations servant à regrouper les types d''opérations et transactions afin de ne pas coder en dur les codes et de faciliter la modification des services.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une catégorie d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation', @level2type = N'COLUMN', @level2name = N'iID_Categorie_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code d''une catégorie d''opération identifiant de façon unique à l''interne d''UniAccès une catégorie.  Ce code est codé en dur dans les services.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation', @level2type = N'COLUMN', @level2name = N'vcCode_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la catégorie d''opérations qui explique à l''analyste la raison de l''existance de la catégorie et son utilisation dans l''application UniAccès.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_CategoriesOperation', @level2type = N'COLUMN', @level2name = N'vcDescription';

