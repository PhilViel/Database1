CREATE TABLE [dbo].[tblIQEE_HistoSelectionEvenements] (
    [iID_Selection_Evenement]  INT IDENTITY (1, 1) NOT NULL,
    [iID_Structure_Historique] INT NOT NULL,
    [iID_Evenement]            INT NOT NULL,
    [iID_Statut]               INT NULL,
    CONSTRAINT [PK_IQEE_HistoSelectionEvenements] PRIMARY KEY CLUSTERED ([iID_Selection_Evenement] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_IQEE_HistoSelectionEvenements_IQEE_HistoEvenements__iIDEvenement] FOREIGN KEY ([iID_Evenement]) REFERENCES [dbo].[tblIQEE_HistoEvenements] ([iID_Evenement]),
    CONSTRAINT [FK_IQEE_HistoSelectionEvenements_IQEE_HistoStatutsEvenement__iIDStatut] FOREIGN KEY ([iID_Statut]) REFERENCES [dbo].[tblIQEE_HistoStatutsEvenement] ([iID_Statut]),
    CONSTRAINT [FK_IQEE_HistoSelectionEvenements_IQEE_HistoStructures__iIDStructureHistorique] FOREIGN KEY ([iID_Structure_Historique]) REFERENCES [dbo].[tblIQEE_HistoStructures] ([iID_Structure_Historique])
);


GO
CREATE NONCLUSTERED INDEX [IX_IQEE_HistoSelectionEvenements_iIDStructureHistorique_iIDEvenement]
    ON [dbo].[tblIQEE_HistoSelectionEvenements]([iID_Structure_Historique] ASC, [iID_Evenement] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur la structure de sélection d''historique et le lien vers l''événement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'INDEX', @level2name = N'IX_IQEE_HistoSelectionEvenements_iIDStructureHistorique_iIDEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre la sélection d''événement d''une structure de sélection et l''événement sélectionné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'CONSTRAINT', @level2name = N'FK_IQEE_HistoSelectionEvenements_IQEE_HistoEvenements__iIDEvenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre les statuts d''événement sélectionnés pour l''événement sélectionné et le statut lui-même.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'CONSTRAINT', @level2name = N'FK_IQEE_HistoSelectionEvenements_IQEE_HistoStatutsEvenement__iIDStatut';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Lien entre la sélection d''événement et la structure de sélection.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'CONSTRAINT', @level2name = N'FK_IQEE_HistoSelectionEvenements_IQEE_HistoStructures__iIDStructureHistorique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Index sur l''identifiant unique de la sélection des événements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'CONSTRAINT', @level2name = N'PK_IQEE_HistoSelectionEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table définissant la liste des événements et statuts d''événement faisant partie d''une structure de sélection de l''historique de l''IQÉÉ.  Si le statut est absent, tous les statuts de l''événement sont considéré dans la sélection pour l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la sélection d''événement d''une sélection d''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'COLUMN', @level2name = N'iID_Selection_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de la structure de sélection d''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'COLUMN', @level2name = N'iID_Structure_Historique';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique de l''événement qui fait partie de la structure de sélection de l''historique de l''IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'COLUMN', @level2name = N'iID_Evenement';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du statut d''événement de l''événement.  Si le statut est absent, tous les statuts de l''événement sont considéré dans la structure de sélection de l''historique IQÉÉ.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblIQEE_HistoSelectionEvenements', @level2type = N'COLUMN', @level2name = N'iID_Statut';

