CREATE TABLE [dbo].[Un_RepContestUnitMultFactorCfg] (
    [RepContestUnitMultFactorCfgID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepContestCfgID]               [dbo].[MoID]         NOT NULL,
    [StartDate]                     [dbo].[MoGetDate]    NOT NULL,
    [EndDate]                       [dbo].[MoDateoption] NULL,
    [RecruitUnitMultFactor]         [dbo].[MoPctPos]     NOT NULL,
    [NonRecruitUnitMultFactor]      [dbo].[MoPctPos]     NOT NULL,
    CONSTRAINT [PK_Un_RepContestUnitMultFactorCfg] PRIMARY KEY CLUSTERED ([RepContestUnitMultFactorCfgID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepContestUnitMultFactorCfg_Un_RepContestCfg__RepContestCfgID] FOREIGN KEY ([RepContestCfgID]) REFERENCES [dbo].[Un_RepContestCfg] ([RepContestCfgID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des facteurs de multiplications.  Les facteurs permettre de paramétriser encore plus les concours.  On peut les utilisers pour définir un période dans le concours plus avantageuse ou moins avantageuse.  On peut aussi avantager ou désavantager les recruits versus les représentants normaux.  On peut aussi faire les deux en même temps.  Ca fonctionne ainsi on inscrit une période et on met un pourcentage pour les recrues et un pour les représentants non-recrues, alors les nouvelles ventes faites dans cette période seront multiplié par un de ces pourcentages selon si le représentant était recrus ou non lors de la vente.  Pour une vente de 5 nouvelles unités et un pourcentage de recrus 300% et un pourcentage non recrus de 200%, si c''est une recru qui a fait la vente, ce sera compté comme 15 nouvelles ventes(unités), si non ce sera compté comme 10 nouvelles ventes(unités).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du facteur de multiplication de concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'RepContestUnitMultFactorCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du concours (Un_RepContestCfg) auquel appartient ce facteur de multiplication.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'RepContestCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du facteur de multiplication.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin d''en vigueur du facteur de multiplication.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage correspondant au facteur de multiplication des recrus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'RecruitUnitMultFactor';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage correspondant au facteur de multiplication des non recrus.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestUnitMultFactorCfg', @level2type = N'COLUMN', @level2name = N'NonRecruitUnitMultFactor';

