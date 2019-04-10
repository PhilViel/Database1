CREATE TABLE [dbo].[Un_Sector] (
    [iSectorID]                          INT          IDENTITY (1, 1) NOT NULL,
    [vcSector]                           VARCHAR (75) NOT NULL,
    [tiOrderInFirstScholarshipStatistic] TINYINT      CONSTRAINT [DF_Un_Sector_tiOrderInFirstScholarshipStatistic] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_Un_Sector] PRIMARY KEY CLUSTERED ([iSectorID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des secteurs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Sector';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du secteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Sector', @level2type = N'COLUMN', @level2name = N'iSectorID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Secteur', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Sector', @level2type = N'COLUMN', @level2name = N'vcSector';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifie l''emplacement de ce secteur dans le rapport de statistic de bourse section Cegeg.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Sector', @level2type = N'COLUMN', @level2name = N'tiOrderInFirstScholarshipStatistic';

