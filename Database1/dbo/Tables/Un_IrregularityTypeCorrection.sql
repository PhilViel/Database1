CREATE TABLE [dbo].[Un_IrregularityTypeCorrection] (
    [IrregularityTypeCorrectionID] [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [IrregularityTypeID]           [dbo].[MoID]      NOT NULL,
    [CorrectingStoredProcedure]    [dbo].[MoDesc]    NOT NULL,
    [CorrectingDate]               [dbo].[MoGetDate] NOT NULL,
    [CorrectingCount]              [dbo].[MoID]      NOT NULL,
    CONSTRAINT [PK_Un_IrregularityTypeCorrection] PRIMARY KEY CLUSTERED ([IrregularityTypeCorrectionID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant l''historique de correction automatique des anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''historique de correction d''anomalies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection', @level2type = N'COLUMN', @level2name = N'IrregularityTypeCorrectionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''anomalies (Un_IrregularityType) sur laquel la correction automatique a été fait.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection', @level2type = N'COLUMN', @level2name = N'IrregularityTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la procédure stockée qui a fait la correction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection', @level2type = N'COLUMN', @level2name = N'CorrectingStoredProcedure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquel la correction automatique a été fait.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection', @level2type = N'COLUMN', @level2name = N'CorrectingDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''anomalies corrigées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IrregularityTypeCorrection', @level2type = N'COLUMN', @level2name = N'CorrectingCount';

