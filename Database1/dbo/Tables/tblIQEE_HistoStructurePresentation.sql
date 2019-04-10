CREATE TABLE [dbo].[tblIQEE_HistoStructurePresentation] (
    [iID_Structure_Presentation] INT           IDENTITY (1, 1) NOT NULL,
    [iID_Structure_Historique]   INT           NOT NULL,
    [cCode_Structure]            CHAR (1)      NOT NULL,
    [iNiveau]                    INT           NOT NULL,
    [bOuverture_Niveau]          BIT           NOT NULL,
    [vcNom_Colonne]              VARCHAR (150) NOT NULL,
    [bID_Niveau]                 BIT           NOT NULL,
    [bID_Niveau_Precedent]       BIT           NOT NULL,
    [bAfficher]                  BIT           NOT NULL,
    [vcTitre_Colonne]            VARCHAR (200) NULL,
    [vcType_Donnee]              VARCHAR (50)  NULL,
    [cAlignement]                CHAR (1)      NULL,
    [iLargeur_Colonne]           INT           NULL,
    [bAfficher_Total]            BIT           NULL,
    [vcTitre_Total]              VARCHAR (100) NULL,
    [iOrdre_Presentation]        INT           NULL,
    CONSTRAINT [PK_IQEE_HistoStructurePresentation] PRIMARY KEY CLUSTERED ([iID_Structure_Presentation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_HistoStructurePresentation_IQEE_HistoStructures__iIDStructureHistorique] FOREIGN KEY ([iID_Structure_Historique]) REFERENCES [dbo].[tblIQEE_HistoStructures] ([iID_Structure_Historique])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoStructurePresentation_iIDStructureHistorique_cCodeStructure]
    ON [dbo].[tblIQEE_HistoStructurePresentation]([iID_Structure_Historique] ASC, [cCode_Structure] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la structure de présentation et le code de structure.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoStructurePresentation_iIDStructureHistorique_cCodeStructure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre la structure de présentation de la description des éléments de la structure vers la structure de présentation elle-même.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'CONSTRAINT', @level2name = N'FK_IQEE_HistoStructurePresentation_IQEE_HistoStructures__iIDStructureHistorique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique du champ de la structure de présentation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoStructurePresentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des informations de structure par pré
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un champ de la structure de présentation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'iID_Structure_Presentation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de structure de présentation de l''historique de l''IQÉÉ du champ décrit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'iID_Structure_Historique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de structure pour la structure de présentation de l''historique de l''IQÉÉ permettant de décrire plus d''une structure de présentation par présentation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'cCode_Structure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro du niveau hiérarchique de la grille du champ décrit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'iNiveau';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si tous les nœuds du niveau hiérarchique de la grille doivent être ouverts ou non par défaut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'bOuverture_Niveau';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la colonne de données du tableau de données selon le niveau hiérarchique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'vcNom_Colonne';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la colonne de données constitue une clé primaire identifiant de façon unique un enregistrement du tableau de données.  Il peut y avoir plus d’une colonne de données pour constituer une clé primaire du tableau de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'bID_Niveau';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la colonne de données fait le lien avec la colonne portant le même nom dans le niveau précédent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'bID_Niveau_Precedent';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si la colonne de données doit être affichée dans la grille de données ou sinon, la donnée est présente dans la grille de données mais la colonne est non visible.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'bAfficher';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Titre de la colonne lorsque la colonne de données doit être affichée dans la grille de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'vcTitre_Colonne';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le type de la donnée indique à l’unité de tâche le format d’affichage de la donnée dans la grille.  Exemples: DATE, DATETIME,
DATETIMECOMPLET, MONEY, etc...
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'vcType_Donnee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Alignement des données dans la colonne de la grille. « G »-Gauche, « C »-Centre, « D »-Droite.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'cAlignement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La largeur de la colonne de données exprimée en pixel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'iLargeur_Colonne';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur s’il doit y avoir un total des données qui s’affiche dans le bas du niveau de la colonne de la grille.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'bAfficher_Total';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Texte servant à mettre un texte de titre à une ligne de totaux.
Il est possible que qu’il y ait un titre de total sans qu’il y ait un total pour la colonne.
Autrement dit, ce titre fait aussi office de texte de bas de niveau.
', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'vcTitre_Total';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre de présentation du champ à l''interface de l''historique IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStructurePresentation', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';

