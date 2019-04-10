CREATE TABLE [dbo].[Un_RepCommission] (
    [RepCommissionID]      [dbo].[MoID]    IDENTITY (1, 1) NOT NULL,
    [RepID]                [dbo].[MoID]    NOT NULL,
    [UnitID]               [dbo].[MoID]    NOT NULL,
    [RepTreatmentID]       [dbo].[MoID]    NOT NULL,
    [RepLevelID]           [dbo].[MoID]    NOT NULL,
    [UnitQty]              [dbo].[MoMoney] NOT NULL,
    [RepPct]               [dbo].[MoMoney] NOT NULL,
    [TotalFee]             [dbo].[MoMoney] NOT NULL,
    [AdvanceAmount]        [dbo].[MoMoney] NOT NULL,
    [CoveredAdvanceAmount] [dbo].[MoMoney] NOT NULL,
    [CommissionAmount]     [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_RepCommission] PRIMARY KEY CLUSTERED ([RepCommissionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepCommission_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepCommission_Un_RepLevel__RepLevelID] FOREIGN KEY ([RepLevelID]) REFERENCES [dbo].[Un_RepLevel] ([RepLevelID]),
    CONSTRAINT [FK_Un_RepCommission_Un_RepTreatment__RepTreatmentID] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID]),
    CONSTRAINT [FK_Un_RepCommission_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCommission_RepID]
    ON [dbo].[Un_RepCommission]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCommission_UnitID]
    ON [dbo].[Un_RepCommission]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCommission_RepTreatmentID]
    ON [dbo].[Un_RepCommission]([RepTreatmentID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCommission_RepLevelID]
    ON [dbo].[Un_RepCommission]([RepLevelID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des commissions.  Les commissions sont des montants d''argent versés aux représentants pour les ventes d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'RepCommissionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) qui reçoit la commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) pour lequel le représentant reçoit la commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commission (Un_RepTreatment) dans lequel le représentant a reçu la commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevel) que le représentant avait lors de la ventes du groupe d''unités.  Permet aussi de connaître le rôle du représentant dans cette vente.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre d''unités qu''avait le groupe d''unités lors du paiement de commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'UnitQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de commission touché par le représentant pour son rôle.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'RepPct';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant total des frais du groupe d''unités lors du calcul de la commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'TotalFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''avance versée dans cette commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'AdvanceAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''avance couverte par cette commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'CoveredAdvanceAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de commissions de service de cette commission.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCommission', @level2type = N'COLUMN', @level2name = N'CommissionAmount';

