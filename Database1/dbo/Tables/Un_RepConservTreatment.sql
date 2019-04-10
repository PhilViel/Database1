CREATE TABLE [dbo].[Un_RepConservTreatment] (
    [RepConservTreatmentID] [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [PeriodStart]           [dbo].[MoDate] NOT NULL,
    [PeriodEnd]             [dbo].[MoDate] NOT NULL,
    CONSTRAINT [PK_Un_RepConservTreatment] PRIMARY KEY CLUSTERED ([RepConservTreatmentID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des traitements de boni annuel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservTreatment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservTreatment', @level2type = N'COLUMN', @level2name = N'RepConservTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début de la période couverte par le traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservTreatment', @level2type = N'COLUMN', @level2name = N'PeriodStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de la période couverte par le traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservTreatment', @level2type = N'COLUMN', @level2name = N'PeriodEnd';

