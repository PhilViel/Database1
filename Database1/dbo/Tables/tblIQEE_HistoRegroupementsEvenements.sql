CREATE TABLE [dbo].[tblIQEE_HistoRegroupementsEvenements] (
    [iID_Regroupement_Evenement]    INT          IDENTITY (1, 1) NOT NULL,
    [vcCode_Regroupement_Evenement] VARCHAR (3)  NOT NULL,
    [vcDescription]                 VARCHAR (50) NOT NULL,
    [tCommentaires_Utilisateur]     TEXT         NULL,
    [iOrdre_Presentation]           INT          NOT NULL,
    CONSTRAINT [PK_IQEE_HistoRegroupementsEvenements] PRIMARY KEY CLUSTERED ([iID_Regroupement_Evenement] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoRegroupementsEvenements_vcCodeRegroupementEvenement]
    ON [dbo].[tblIQEE_HistoRegroupementsEvenements]([vcCode_Regroupement_Evenement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de regroupement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoRegroupementsEvenements_vcCodeRegroupementEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur l''identifiant du regroupement d''événements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoRegroupementsEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Liste des regroupements des événements touchant l''IQÉÉ.  Il est utilisé pour regrouper les événements pour l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du regroupement d''événements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'COLUMN', @level2name = N'iID_Regroupement_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code identifiant d''une façon unique le regroupement d''événements.  Il peut être codé en dur dans la programmtion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'COLUMN', @level2name = N'vcCode_Regroupement_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du regroupement d''événements.  Il est affiché dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Commentaires pour les utilisateurs.  Ils sont affichés en info-bulle pour l''utilisateur dans l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'COLUMN', @level2name = N'tCommentaires_Utilisateur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro séquentiel permettant d''ordonner les regroupements d''événements pour l''affichage à l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoRegroupementsEvenements', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';

