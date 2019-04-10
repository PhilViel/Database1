CREATE TABLE [dbo].[tblIQEE_CategorieJustification] (
    [tiID_Categorie_Justification_RQ] TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode]                          VARCHAR (3)   NOT NULL,
    [vcDescription]                   VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_IQEE_CategorieJustification] PRIMARY KEY CLUSTERED ([tiID_Categorie_Justification_RQ] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_CategorieJustification_vcCode]
    ON [dbo].[tblIQEE_CategorieJustification]([vcCode] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code de catégorie de justification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification', @level2type = N'INDEX', @level2name = N'AK_IQEE_CategorieJustification_vcCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire des catégories de justification de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_CategorieJustification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des catégories des justifications de RQ.  Les catégories des justifications correspondent aux bloc de justification de l''annexe 3 des NID.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une catégorie de justification de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Justification_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de la catégorie de justification.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification', @level2type = N'COLUMN', @level2name = N'vcCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la catégorie de justification.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategorieJustification', @level2type = N'COLUMN', @level2name = N'vcDescription';

