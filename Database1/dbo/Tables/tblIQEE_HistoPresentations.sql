CREATE TABLE [dbo].[tblIQEE_HistoPresentations] (
    [iID_Presentation]           INT            IDENTITY (1, 1) NOT NULL,
    [iID_Structure_Historique]   INT            NOT NULL,
    [vcCode_Type_Info]           VARCHAR (10)   NOT NULL,
    [vcCode_Info]                VARCHAR (20)   NULL,
    [vcNom_Table]                VARCHAR (150)  NULL,
    [vcNom_Champ]                VARCHAR (150)  NULL,
    [vcDescription]              VARCHAR (2000) NULL,
    [vcCommentaires_Utilisateur] VARCHAR (MAX)  NULL,
    [vcCouleur_Fond]             VARCHAR (6)    NULL,
    [vcCouleur_Texte]            VARCHAR (6)    NULL,
    [cAlignement]                CHAR (1)       NULL,
    [bGras]                      BIT            NULL,
    CONSTRAINT [PK_IQEE_HistoPresentations] PRIMARY KEY CLUSTERED ([iID_Presentation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_HistoPresentations_IQEE_HistoStructures__iIDStructureHistorique] FOREIGN KEY ([iID_Structure_Historique]) REFERENCES [dbo].[tblIQEE_HistoStructures] ([iID_Structure_Historique])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoPresentations_iIDStructureHistorique_vcCodeTypeInfo_vcCodeInfo]
    ON [dbo].[tblIQEE_HistoPresentations]([iID_Structure_Historique] ASC, [vcCode_Type_Info] ASC, [vcCode_Info] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoPresentations_iIDStructureHistorique_vcCodeTypeInfo_vcNomTable_vcNomChamp]
    ON [dbo].[tblIQEE_HistoPresentations]([iID_Structure_Historique] ASC, [vcCode_Type_Info] ASC, [vcNom_Table] ASC, [vcNom_Champ] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code d''information spécifique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoPresentations_iIDStructureHistorique_vcCodeTypeInfo_vcCodeInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur les noms de tables et champs pour le détail d''un événement de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoPresentations_iIDStructureHistorique_vcCodeTypeInfo_vcNomTable_vcNomChamp';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre un élément spécifique de présentation et la structure de présentation elle-même.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'CONSTRAINT', @level2name = N'FK_IQEE_HistoPresentations_IQEE_HistoStructures__iIDStructureHistorique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique d''une information de présentation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoPresentations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table permettant de modifier les informations apparaissant à l''historique de l''IQÉÉ selon la présentation choisie par l''utilisateur.  Elle peut servir à modifier la description d''un élément de structurer une info-bulle, de sélectionner une couleur de texte ou de fond, de changer l''alignement de l''information ou de mettre le texte en gras.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''information de présentation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'iID_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la structure de présentation d''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'iID_Structure_Historique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type d''information à traiter.  REG=Regroupement d''événement de l''historique, EVE=Événement de l''historique, TYP=Type d''événement de l''historique, STA=Statut d''événement de l''historique, STC=Statut de convention, DET=Détail d''un événement du résumé des événements, CON[Code d''événement]=Détail d''un événement de la consultation des événements, CAT[Code d''événement]=Nom de catégorie de consultation des événements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcCode_Type_Info';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code d''information unique selon le type d''information pouvant servir à identifier de façon unique l''élément pour lequel la présentation doit être modifié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcCode_Info';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la table contenant le champ de détail d''événement de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcNom_Table';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du champ de la table qui correspond à un élément de détail d''événement de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcNom_Champ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description modifié et spécifique à la présentation choisie par l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires pour l''utilisateur (info-bulle) modifiés et spécifique à la présentation choisie par l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcCommentaires_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de couleur pour pour le fond modifié et spécifique à la présentation choisie par l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcCouleur_Fond';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de couleur pour pour le texte modifié et spécifique à la présentation choisie par l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'vcCouleur_Texte';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Alignement de l''élément de détail pour l''interface utilisateur spécifique selon la présentation choisie par l''utilisateur.  ''G'' = Gauche, ''C'' = Centré, ''D'' = Droite', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'cAlignement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur que le texte doit s''afficher en gras spécifique selon la présentation choisie par l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoPresentations', @level2type = N'COLUMN', @level2name = N'bGras';

