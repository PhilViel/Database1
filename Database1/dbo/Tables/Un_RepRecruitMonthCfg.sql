CREATE TABLE [dbo].[Un_RepRecruitMonthCfg] (
    [RepRecruitMonthCfgID] [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [Effectdate]           [dbo].[MoDate] NOT NULL,
    [Months]               [dbo].[MoID]   NOT NULL,
    CONSTRAINT [PK_Un_RepRecruitMonthCfg] PRIMARY KEY CLUSTERED ([RepRecruitMonthCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration de nombre de mois pendant lesquelles un nouveau représentant est considéré comme une recrue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRecruitMonthCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement de configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRecruitMonthCfg', @level2type = N'COLUMN', @level2name = N'RepRecruitMonthCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.  Pour connaître la configuration qui s''applique a un représentant, on doit prendre l''enregistrement dont cette date est la plus élevé dans ceux dont cette date est plus petite ou égale à la date de début d''affaire (Un_Rep.BusinessStart) du représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRecruitMonthCfg', @level2type = N'COLUMN', @level2name = N'Effectdate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de mois à partir de la date de début d''affaire (Un_Rep.BusinessStart) durant lesquelles le reprsentant est une recrue.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepRecruitMonthCfg', @level2type = N'COLUMN', @level2name = N'Months';

