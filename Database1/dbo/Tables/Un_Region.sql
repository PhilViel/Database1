CREATE TABLE [dbo].[Un_Region] (
    [iRegionID] INT          IDENTITY (1, 1) NOT NULL,
    [vcRegion]  VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_Un_Region] PRIMARY KEY CLUSTERED ([iRegionID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des régions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Region';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la région', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Region', @level2type = N'COLUMN', @level2name = N'iRegionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Région', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Region', @level2type = N'COLUMN', @level2name = N'vcRegion';

