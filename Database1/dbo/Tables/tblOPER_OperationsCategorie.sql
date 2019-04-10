CREATE TABLE [dbo].[tblOPER_OperationsCategorie] (
    [iID_Operation_Categorie]  INT      IDENTITY (1, 1) NOT NULL,
    [iID_Categorie_Oper]       INT      NOT NULL,
    [cID_Type_Oper]            CHAR (3) NULL,
    [cID_Type_Oper_Plan]       CHAR (3) NULL,
    [cID_Type_Oper_Convention] CHAR (3) NULL,
    CONSTRAINT [PK_OPER_OperationsCategorie] PRIMARY KEY CLUSTERED ([iID_Operation_Categorie] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_OPER_OperationsCategorie_OPER_CategoriesOperation__iIDCategorieOper] FOREIGN KEY ([iID_Categorie_Oper]) REFERENCES [dbo].[tblOPER_CategoriesOperation] ([iID_Categorie_Oper]) ON DELETE CASCADE
);


GO
CREATE NONCLUSTERED INDEX [IX_OPER_OperationsCategorie_iIDCategorieOper]
    ON [dbo].[tblOPER_OperationsCategorie]([iID_Categorie_Oper] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index par catégorie d''opérations permettant d''accéder rapidement aux types d''opérations d''une catégorie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'INDEX', @level2name = N'IX_OPER_OperationsCategorie_iIDCategorieOper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des opérations des catégories.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'CONSTRAINT', @level2name = N'PK_OPER_OperationsCategorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des opérations d''une catégorie.  Un type d''opération peut être dans plus d''une catégorie.  Les combinaisons sont possible dans les types d''opérations selon le choix de l''analyste.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type d''opération d''une catégorie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'COLUMN', @level2name = N'iID_Operation_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la catégorie (tblOPER_CategoriesOperation) à laquelle appartient le type d''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'COLUMN', @level2name = N'iID_Categorie_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''opération (Un_OperType) faisant parti d''une catégorie d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'COLUMN', @level2name = N'cID_Type_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''opération sur un régime (Un_PlanOperType) faisant parti d''une catégorie d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'COLUMN', @level2name = N'cID_Type_Oper_Plan';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type d''opération sur une convention (Un_ConventionOperType) faisant parti d''une catégorie d''opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblOPER_OperationsCategorie', @level2type = N'COLUMN', @level2name = N'cID_Type_Oper_Convention';

