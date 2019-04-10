CREATE TABLE [dbo].[Un_RepContestPriceCfg] (
    [RepContestPriceCfgID] [dbo].[MoID]    IDENTITY (1, 1) NOT NULL,
    [RepContestCfgID]      [dbo].[MoID]    NOT NULL,
    [ContestPriceName]     [dbo].[MoDesc]  NOT NULL,
    [MinUnitQty]           [dbo].[MoMoney] NOT NULL,
    [SectionColor]         [dbo].[MoID]    NOT NULL,
    CONSTRAINT [PK_Un_RepContestPriceCfg] PRIMARY KEY CLUSTERED ([RepContestPriceCfgID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepContestPriceCfg_Un_RepContestCfg__RepContestCfgID] FOREIGN KEY ([RepContestCfgID]) REFERENCES [dbo].[Un_RepContestCfg] ([RepContestCfgID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des prix des concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du prix de concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg', @level2type = N'COLUMN', @level2name = N'RepContestPriceCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du concours (Un_RepContestCfg) auquel appartient le prix.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg', @level2type = N'COLUMN', @level2name = N'RepContestCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du prix.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg', @level2type = N'COLUMN', @level2name = N'ContestPriceName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre minimum de nouvelles ventes (Unités) faites pendant la durée du concours pour mériter ce prix.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg', @level2type = N'COLUMN', @level2name = N'MinUnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Couleur utilisée pour identifier les représentants qui ont gagner ce prix dans les rapports de concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestPriceCfg', @level2type = N'COLUMN', @level2name = N'SectionColor';

