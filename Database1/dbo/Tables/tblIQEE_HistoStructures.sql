CREATE TABLE [dbo].[tblIQEE_HistoStructures] (
    [iID_Structure_Historique] INT           IDENTITY (1, 1) NOT NULL,
    [cType_Structure]          CHAR (1)      NOT NULL,
    [vcCode_Structure]         VARCHAR (3)   NOT NULL,
    [vcDescription]            VARCHAR (200) NOT NULL,
    [vcCode_Droit]             VARCHAR (75)  NULL,
    [iOrdre_Presentation]      INT           NOT NULL,
    [bUtilise_Statut_IQEE]     BIT           NOT NULL,
    CONSTRAINT [PK_IQEE_HistoStructures] PRIMARY KEY CLUSTERED ([iID_Structure_Historique] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoStructures_cTypeStructure_vcCodeStructure]
    ON [dbo].[tblIQEE_HistoStructures]([cType_Structure] ASC, [vcCode_Structure] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur les codes de la structure de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoStructures_cTypeStructure_vcCodeStructure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique de la structure de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoStructures';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des structures de sélection, de présentation et de tri servant à l''historique de l''IQÉÉ.  Le contenu de l''historique est fonction de la sélection choisie.  Le contenu de la grille de l''historique est fonction de la présentation choisi.  Le tri dans la grille de l''historique est fonction du tri sélectionné.  Chacune de ces structures peut être relié à un droit afin de contrôler les choix des utilisateurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''une structure de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'iID_Structure_Historique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type de la structure de l''historique de l''IQÉÉ.  S=Sélection, P=Présentation, T=Tri', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'cType_Structure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de la structure de l''historique de l''IQÉÉ.  Il peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'vcCode_Structure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de la structure de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du droit d''utilisateur qui est lié à la structure de l''historique IQÉÉ.  Si l''utilisateur ne possède pas ce droit, cette option de l''historique n''est pas disponible à l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'vcCode_Droit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation de la structure à l''interface de l''historique IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la structure de sélection ou de présentation utilisera le statut IQÉÉ de la convention.  Si c''est le cas, les sélections pertinentes à la détermination du statut IQÉÉ de la convention seront calculées avant d''être supprimées et ce, même si elles ne font pas partie de la sélection choisie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructures', @level2type = N'COLUMN', @level2name = N'bUtilise_Statut_IQEE';

