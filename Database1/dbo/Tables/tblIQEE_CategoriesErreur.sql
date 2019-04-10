CREATE TABLE [dbo].[tblIQEE_CategoriesErreur] (
    [tiID_Categorie_Erreur] TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Categorie]      VARCHAR (3)  NOT NULL,
    [bCategorie_Erreur_RQ]  BIT          NOT NULL,
    [vcDescription]         VARCHAR (50) NOT NULL,
    [vcResponsable]         VARCHAR (50) NULL,
    [tiOrdre_Presentation]  TINYINT      NOT NULL,
    CONSTRAINT [PK_IQEE_CategoriesErreur] PRIMARY KEY CLUSTERED ([tiID_Categorie_Erreur] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_CategoriesErreur_vcCodeCategorie]
    ON [dbo].[tblIQEE_CategoriesErreur]([vcCode_Categorie] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code interne à UniAccès des catégories des types d''''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'INDEX', @level2name = N'AK_IQEE_CategoriesErreur_vcCodeCategorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des catégories des types d''''erreur de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_CategoriesErreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Catégories des types d''erreur.  Les catégories sont de 2 type soit les catégories pour les erreurs de RQ et les catégories pour les rejets interne à GUI.  Elles permettent de catégoriser les erreurs et rejets à traiter selon les responsabilités de la correction des erreurs ou rejets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique des catégories des types d''''erreur de RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'tiID_Categorie_Erreur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne à UniAccès de la catégorie de types d''''erreur.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'vcCode_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la catégorie d''erreur est reliée au erreurs de RQ.  Si elle ne l''est pas, c''est que la catégorie d''erreur s''applique au rejets interne de GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'bCategorie_Erreur_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la catégorie des types d''erreur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Responsable de la correction des types d''erreur de la catégorie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'vcResponsable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des catégories d''erreur dans les listes déroulantes des interfaces utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_CategoriesErreur', @level2type = N'COLUMN', @level2name = N'tiOrdre_Presentation';

