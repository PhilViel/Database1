CREATE TABLE [dbo].[Un_UnitReductionCotisation] (
    [CotisationID]    [dbo].[MoID] NOT NULL,
    [UnitReductionID] [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Un_UnitReductionCotisation] PRIMARY KEY CLUSTERED ([CotisationID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitReductionCotisation_Un_Cotisation__CotisationID] FOREIGN KEY ([CotisationID]) REFERENCES [dbo].[Un_Cotisation] ([CotisationID]),
    CONSTRAINT [FK_Un_UnitReductionCotisation_Un_UnitReduction__UnitReductionID] FOREIGN KEY ([UnitReductionID]) REFERENCES [dbo].[Un_UnitReduction] ([UnitReductionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitReductionCotisation_UnitReductionID]
    ON [dbo].[Un_UnitReductionCotisation]([UnitReductionID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui fait un lien entre une entrée d''historique de réduction d''unités (Un_UnitReduction) et la cotisation (Un_Cotisation) de l''opération financière qui l''a effectué.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionCotisation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la cotisation (Un_Cotisation).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionCotisation', @level2type = N'COLUMN', @level2name = N'CotisationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée d''historique de réduction d''unité (Un_UnitReduction).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionCotisation', @level2type = N'COLUMN', @level2name = N'UnitReductionID';

