CREATE TABLE [dbo].[Un_UnitReduction] (
    [UnitReductionID]       [dbo].[MoID]       IDENTITY (1, 1) NOT NULL,
    [UnitID]                [dbo].[MoID]       NOT NULL,
    [ReductionConnectID]    [dbo].[MoID]       NOT NULL,
    [ReductionDate]         [dbo].[MoGetDate]  NOT NULL,
    [UnitQty]               [dbo].[MoMoney]    NOT NULL,
    [FeeSumByUnit]          [dbo].[MoMoney]    NOT NULL,
    [SubscInsurSumByUnit]   [dbo].[MoMoney]    NOT NULL,
    [UnitReductionReasonID] [dbo].[MoIDoption] NULL,
    [NoChequeReasonID]      [dbo].[MoIDoption] NULL,
    CONSTRAINT [PK_Un_UnitReduction] PRIMARY KEY CLUSTERED ([UnitReductionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitReduction_Un_NoChequeReason__NoChequeReasonID] FOREIGN KEY ([NoChequeReasonID]) REFERENCES [dbo].[Un_NoChequeReason] ([NoChequeReasonID]),
    CONSTRAINT [FK_Un_UnitReduction_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID]),
    CONSTRAINT [FK_Un_UnitReduction_Un_UnitReductionReason__UnitReductionReasonID] FOREIGN KEY ([UnitReductionReasonID]) REFERENCES [dbo].[Un_UnitReductionReason] ([UnitReductionReasonID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitReduction_UnitID]
    ON [dbo].[Un_UnitReduction]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_1381020101_1_2_4]
    ON [dbo].[Un_UnitReduction]([ReductionDate], [UnitID], [UnitReductionID]);


GO
CREATE STATISTICS [_dta_stat_1381020101_4_2]
    ON [dbo].[Un_UnitReduction]([ReductionDate], [UnitID]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des entrées d''historique de réduction(résiliation) d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée d''historique de réduction d''unité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'UnitReductionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) auquel appartient l''entrée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a provoqué la création de l''entrée soit en fesant une résiliation ou un transfert OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'ReductionConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquelle a eu lieu la réduction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'ReductionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''unités réduit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'UnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais par unité réduit non remboursé au client.  Utile au commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'FeeSumByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''assurance souscripteur par unité réduit non remboursé au client.  Utile au avis de dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'SubscInsurSumByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la raison de la réduction d''unités (Un_UnitReductionReason). NULL = aucune raison de donnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'UnitReductionReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la raison de ne pas émettre de chèque pour la réduction d''unités (Un_NoChequeReason). NULL = aucune raison de donnée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReduction', @level2type = N'COLUMN', @level2name = N'NoChequeReasonID';

