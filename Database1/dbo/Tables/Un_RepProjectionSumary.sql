CREATE TABLE [dbo].[Un_RepProjectionSumary] (
    [RepProjectionDate]    [dbo].[MoDate]       NOT NULL,
    [RepID]                [dbo].[MoID]         NOT NULL,
    [RepName]              [dbo].[MoDesc]       NOT NULL,
    [RepCode]              [dbo].[MoDescoption] NULL,
    [PeriodCommBonus]      [dbo].[MoMoney]      NOT NULL,
    [YearCommBonus]        [dbo].[MoMoney]      NOT NULL,
    [PeriodCoveredAdvance] [dbo].[MoMoney]      NOT NULL,
    [YearCoveredAdvance]   [dbo].[MoMoney]      NOT NULL,
    [AVSAmount]            [dbo].[MoMoney]      NOT NULL,
    [AVRAmount]            [dbo].[MoMoney]      NOT NULL,
    [AdvanceSolde]         [dbo].[MoMoney]      NOT NULL,
    [AVSAmountSolde]       [dbo].[MoMoney]      NOT NULL,
    [AVRAmountSolde]       [dbo].[MoMoney]      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepProjectionSumary_RepProjectionDate_RepID]
    ON [dbo].[Un_RepProjectionSumary]([RepProjectionDate] ASC, [RepID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de sommaire du rapport des projections.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la projection. Permet aussi d''identifier à qu''elle projection l''enregistrement appartient', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'RepProjectionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) auquel appartient cette projection de commission', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du représentant suivi d''une virgule, d''un espace et de son prénom.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'RepName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'RepCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des commissions et bonis d''affaire de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'PeriodCommBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des commissions et bonis d''affaire de la période (RepProjectionDate) et de toute les périodes précédentes de l''année pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'YearCommBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des avances couvertes de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'PeriodCoveredAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des avances couvertes de la période (RepProjectionDate) et de toute les périodes précédentes de l''année pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'YearCoveredAdvance';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des avances spéciales de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'AVSAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Somme des avances sur résiliation de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'AVRAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Solde projeté des avances non couverte à la fin de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'AdvanceSolde';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Solde projeté des avances spéciales à la fin de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'AVSAmountSolde';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Solde projeté des avances sur résiliations à la fin de la période (RepProjectionDate) pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepProjectionSumary', @level2type = N'COLUMN', @level2name = N'AVRAmountSolde';

