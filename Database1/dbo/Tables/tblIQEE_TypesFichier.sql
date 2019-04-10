CREATE TABLE [dbo].[tblIQEE_TypesFichier] (
    [tiID_Type_Fichier]     TINYINT       IDENTITY (1, 1) NOT NULL,
    [vcCode_Type_Fichier]   VARCHAR (3)   NOT NULL,
    [vcDescription]         VARCHAR (100) NOT NULL,
    [bRequiere_Approbation] BIT           NOT NULL,
    [bTeleversable_RQ]      BIT           NOT NULL,
    [tiOrdre_Presentation]  TINYINT       NOT NULL,
    CONSTRAINT [PK_IQEE_TypesFichier] PRIMARY KEY CLUSTERED ([tiID_Type_Fichier] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_TypesFichier_vcCodeTypeFichier]
    ON [dbo].[tblIQEE_TypesFichier]([vcCode_Type_Fichier] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code interne des types de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'INDEX', @level2name = N'AK_IQEE_TypesFichier_vcCodeTypeFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index de la clé primaire des types de fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_TypesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des types de fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un type de fichier de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'tiID_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code interne à UniAccès d''un type de fichier.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'vcCode_Type_Fichier';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description d''un type de fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le type de fichier requière ou non une approbation d''un utilisateur avant d''être transmis à RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'bRequiere_Approbation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le type de fichier peuvent être transmis ou non à RQ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'bTeleversable_RQ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation des types de fichier pour les interfaces utilisateurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_TypesFichier', @level2type = N'COLUMN', @level2name = N'tiOrdre_Presentation';

