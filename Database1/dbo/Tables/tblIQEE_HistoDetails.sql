CREATE TABLE [dbo].[tblIQEE_HistoDetails] (
    [iID_Detail]                    INT            IDENTITY (1, 1) NOT NULL,
    [bResume]                       BIT            NULL,
    [vcCode_Evenement]              VARCHAR (10)   NULL,
    [vcNom_Table]                   VARCHAR (150)  NOT NULL,
    [vcNom_Champ]                   VARCHAR (150)  NOT NULL,
    [vcDescription]                 VARCHAR (2000) NOT NULL,
    [tCommentaires_Utilisateur]     TEXT           NULL,
    [cAlignement]                   CHAR (1)       NULL,
    [vcNom_Categorie]               VARCHAR (200)  NULL,
    [iOrdre_Presentation_Categorie] INT            NULL,
    [iOrdre_Presentation_Champ]     INT            NULL,
    CONSTRAINT [PK_IQEE_HistoDetails] PRIMARY KEY CLUSTERED ([iID_Detail] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoDetails_vcCodeEvenement]
    ON [dbo].[tblIQEE_HistoDetails]([vcCode_Evenement] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoDetails_vcNomTable_vcNomChamp]
    ON [dbo].[tblIQEE_HistoDetails]([vcNom_Table] ASC, [vcNom_Champ] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur le code d''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoDetails_vcCodeEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur la localisation du détail d''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoDetails_vcNomTable_vcNomChamp';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la clé primaire des détails des événements de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoDetails';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des détails de l''historique de l''IQÉÉ permet de donner une description abrégée aux éléments de détail des événements de l''historique de l''IQÉÉ et d''emmagasiner les informations servant à la  présentation des informations à l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du détail d''un événement de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'iID_Detail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indicateur si le détail est pour le résumé de l''événement de l''historique ou pour le détail de l''événement lors de la consultation complète de l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'bResume';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code d''événement servant à donner une description au détail de l''événement lors de la consultation complète de l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'vcCode_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la table contenant le champ de détail d''événement de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'vcNom_Table';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom du champ de la table qui correspond à un élément de détail d''événement de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'vcNom_Champ';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du détail d''événement de l''historique pouvant apparaitre à l''historique de l''IQÉÉ.  Si le champ est vide, c''est que la description est déterminée par la programmation ou selon la présentation sélectionnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires sur le détail pouvant servir à la compréhension de l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'tCommentaires_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Alignement de l''élément de détail pour l''interface utilisateur.  ''G'' = Gauche, ''C'' = Centré, ''D'' = Droite', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'cAlignement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Nom de la catégorie servant à regrouper les informations de détail lors de la consultation complète de l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'vcNom_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre d''affichage pour l''interface utilisateur des noms de catégorie lors de la consultation complète de l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation_Categorie';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Ordre d''affichage pour l''interface utilisateur des détails d''information d''une catégorie lors de la consultation complète de l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoDetails', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation_Champ';

