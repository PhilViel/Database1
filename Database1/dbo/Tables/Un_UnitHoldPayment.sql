CREATE TABLE [dbo].[Un_UnitHoldPayment] (
    [UnitHoldPaymentID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [UnitID]            [dbo].[MoID]         NOT NULL,
    [StartDate]         [dbo].[MoGetDate]    NOT NULL,
    [EndDate]           [dbo].[MoDateoption] NULL,
    [Reason]            [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Un_UnitHoldPayment] PRIMARY KEY CLUSTERED ([UnitHoldPaymentID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitHoldPayment_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des arrêts de paiement sur groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''arrêt de paiement sur groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment', @level2type = N'COLUMN', @level2name = N'UnitHoldPaymentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) sur lequel est l''arrêt de paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de l''arrêt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de l''arrêt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs text ou les usagers peuvent inscrire la raison de l''arrêt de paiement sur groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitHoldPayment', @level2type = N'COLUMN', @level2name = N'Reason';

