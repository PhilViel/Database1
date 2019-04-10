CREATE TABLE [dbo].[Un_ConventionYearQualif] (
    [ConventionYearQualifID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ConventionID]           [dbo].[MoID]         NOT NULL,
    [ConnectID]              [dbo].[MoID]         NOT NULL,
    [EffectDate]             [dbo].[MoGetDate]    NOT NULL,
    [TerminatedDate]         [dbo].[MoDateoption] NULL,
    [YearQualif]             [dbo].[MoID]         NOT NULL,
    CONSTRAINT [PK_Un_ConventionYearQualif] PRIMARY KEY CLUSTERED ([ConventionYearQualifID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ConventionYearQualif_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID]),
    CONSTRAINT [FK_Un_ConventionYearQualif_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionYearQualif_ConventionID]
    ON [dbo].[Un_ConventionYearQualif]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table d''historique des années de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''historique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'ConventionYearQualifID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion du l''usager qui a provoqué le changement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de l''année de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'EffectDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de terminaison de l''année de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'TerminatedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année de qualification', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionYearQualif', @level2type = N'COLUMN', @level2name = N'YearQualif';

