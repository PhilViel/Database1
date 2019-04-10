CREATE TABLE [dbo].[tblIQEE_StatutsFichier] (
    [tiID_Statut_Fichier]  TINYINT      IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut]        VARCHAR (3)  NOT NULL,
    [vcDescription]        VARCHAR (30) NOT NULL,
    [tiID_Type_Fichier]    TINYINT      NOT NULL,
    [tiOrdre_Presentation] TINYINT      NOT NULL,
    CONSTRAINT [PK_IQEE_StatutsFichier] PRIMARY KEY CLUSTERED ([tiID_Statut_Fichier] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_StatutsFichier_IQEE_TypesFichier__tiIDTypeFichier] FOREIGN KEY ([tiID_Type_Fichier]) REFERENCES [dbo].[tblIQEE_TypesFichier] ([tiID_Type_Fichier])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_StatutsFichier_vcCodeStatut]
    ON [dbo].[tblIQEE_StatutsFichier]([vcCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code interne à UniAccès des statuts des fichiers.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'INDEX', @level2name = N'AK_IQEE_StatutsFichier_vcCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des statuts des fichiers de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_StatutsFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des statuts des fichiers de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'COLUMN', @level2name = N'tiID_Statut_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne à UniAccès du statut de fichier.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant du type de fichier IQÉÉ applicable au statut.  Il y a 1 seul fichier applicable par statut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'COLUMN', @level2name = N'tiID_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des statuts de fichier pour l''interface utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_StatutsFichier', @level2type = N'COLUMN', @level2name = N'tiOrdre_Presentation';

