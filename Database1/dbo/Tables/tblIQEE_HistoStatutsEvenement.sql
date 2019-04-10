CREATE TABLE [dbo].[tblIQEE_HistoStatutsEvenement] (
    [iID_Statut]    INT           IDENTITY (1, 1) NOT NULL,
    [vcCode_Statut] VARCHAR (20)  NOT NULL,
    [vcDescription] VARCHAR (200) NULL,
    CONSTRAINT [PK_IQEE_HistoStatutsEvenement] PRIMARY KEY CLUSTERED ([iID_Statut] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_IQEE_HistoStatutsEvenement_vcCodeStatut]
    ON [dbo].[tblIQEE_HistoStatutsEvenement]([vcCode_Statut] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index unique sur le code de statut d''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement', @level2type = N'INDEX', @level2name = N'AK_IQEE_HistoStatutsEvenement_vcCodeStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique du statut d''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoStatutsEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant tous les statuts chronologique et les statuts à jour des événements de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique d''un statut d''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement', @level2type = N'COLUMN', @level2name = N'iID_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code unique identifiant un statut d''événement.  Ce code peut être codé en dur dans la programmation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement', @level2type = N'COLUMN', @level2name = N'vcCode_Statut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du statut d''événement pouvant apparaitre à l''historique de l''IQÉÉ.  Si le champ est vide, c''est que la description est déterminée par la programmation ou par la présentation sélectionnée pour l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoStatutsEvenement', @level2type = N'COLUMN', @level2name = N'vcDescription';

