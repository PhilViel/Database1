CREATE TABLE [dbo].[tblIQEE_HistoEvenements] (
    [iID_Evenement]           INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Regroupement]     VARCHAR (3)   NOT NULL,
    [vcCode_Evenement]        VARCHAR (10)  NOT NULL,
    [vcDescription_Evenement] VARCHAR (200) NULL,
    [vcCode_Type]             VARCHAR (10)  NOT NULL,
    [vcDescription_Type]      VARCHAR (200) NULL,
    [iOrdre_Presentation]     INT           NOT NULL,
    CONSTRAINT [PK_IQEE_HistoEvenements] PRIMARY KEY CLUSTERED ([iID_Evenement] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_tblIQEE_HistoEvenements_tblIQEE_HistoRegroupementsEvenements] FOREIGN KEY ([vcCode_Regroupement]) REFERENCES [dbo].[tblIQEE_HistoRegroupementsEvenements] ([vcCode_Regroupement_Evenement])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoEvenements_vcCodeEvenement_vcCodeType]
    ON [dbo].[tblIQEE_HistoEvenements]([vcCode_Evenement] ASC, [vcCode_Type] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la combinaison des codes de l''événement et du type.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoEvenements_vcCodeEvenement_vcCodeType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre l''événement et le regroupement d''événements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'CONSTRAINT', @level2name = N'FK_tblIQEE_HistoEvenements_tblIQEE_HistoRegroupementsEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant d''un événement/type.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Les événements sont une combinaison d''un événement de l''IQÉÉ ou d''UniAccès avec un type d''événement.  Cette combinaison ou événement permet la construction et la présentation de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un événement/type.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'iID_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code de regroupement d''événement relié à la table "tblIQEE_HistoRegroupementsEvenements".', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'vcCode_Regroupement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code identifiant l''événement.  Il peut être codé en dur dans la programmation.  La combinaison de l''événement et du type d''événement doit être unique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'vcCode_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description de l''événement pouvant apparaitre à l''historique de l''IQÉÉ.  Si le champ est vide, c''est que la description est déterminée par la programmation ou selon la présentation sélectionnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'vcDescription_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code identifiant le type d''événement.  Il peut être codé en dur dans la programmation.  La combinaison de l''événement et du type d''événement doit être unique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'vcCode_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type d''événement pouvant apparaitre à l''historique de l''IQÉÉ.  Si le champ est vide, c''est que la description est déterminée par la programmation ou par la présentation sélectionnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'vcDescription_Type';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Numéro séquentiel permettant d''ordonner les événements pour l''affichage à l''utilisateur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoEvenements', @level2type = N'COLUMN', @level2name = N'iOrdre_Presentation';

