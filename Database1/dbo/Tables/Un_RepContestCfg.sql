CREATE TABLE [dbo].[Un_RepContestCfg] (
    [RepContestCfgID] [dbo].[MoID]             IDENTITY (1, 1) NOT NULL,
    [StartDate]       [dbo].[MoGetDate]        NOT NULL,
    [EndDate]         [dbo].[MoDateoption]     NULL,
    [ContestName]     [dbo].[MoDesc]           NOT NULL,
    [RepContestType]  [dbo].[UnRepContestType] NOT NULL,
    CONSTRAINT [PK_Un_RepContestCfg] PRIMARY KEY CLUSTERED ([RepContestCfgID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg', @level2type = N'COLUMN', @level2name = N'RepContestCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début du concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin du concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du concours.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg', @level2type = N'COLUMN', @level2name = N'ContestName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ce champ identifie le type de concours dont il s’agit (''CBP'':Concours Club du président, ''REC'':Concours des recrues, ''DIR'':Concours des directeurs, ''OTH'':Autres concours).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepContestCfg', @level2type = N'COLUMN', @level2name = N'RepContestType';

