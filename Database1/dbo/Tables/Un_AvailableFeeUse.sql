CREATE TABLE [dbo].[Un_AvailableFeeUse] (
    [iAvailableFeeUseID] INT   IDENTITY (1, 1) NOT NULL,
    [UnitReductionID]    INT   NOT NULL,
    [OperID]             INT   NOT NULL,
    [fUnitQtyUse]        MONEY NOT NULL,
    CONSTRAINT [PK_Un_AvailableFeeUse] PRIMARY KEY CLUSTERED ([iAvailableFeeUseID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_AvailableFeeUse_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_AvailableFeeUse_Un_UnitReduction__UnitReductionID] FOREIGN KEY ([UnitReductionID]) REFERENCES [dbo].[Un_UnitReduction] ([UnitReductionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_AvailableFeeUse_OperID]
    ON [dbo].[Un_AvailableFeeUse]([OperID] ASC)
    INCLUDE([iAvailableFeeUseID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_AvailableFeeUse_UnitReductionID]
    ON [dbo].[Un_AvailableFeeUse]([UnitReductionID] ASC)
    INCLUDE([fUnitQtyUse]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des frais disponibles utilisés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeUse';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’enregistrement d''un frais disponible utilisé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeUse', @level2type = N'COLUMN', @level2name = N'iAvailableFeeUseID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique d''une réduciton d''unité', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeUse', @level2type = N'COLUMN', @level2name = N'UnitReductionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique d''un opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeUse', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant relatif a la quantité d''unités utilisés', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AvailableFeeUse', @level2type = N'COLUMN', @level2name = N'fUnitQtyUse';

