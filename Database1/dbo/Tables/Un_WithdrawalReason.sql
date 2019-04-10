CREATE TABLE [dbo].[Un_WithdrawalReason] (
    [OperID]                    [dbo].[MoID]               NOT NULL,
    [WithdrawalReasonID]        [dbo].[UnWithdrawalReason] NOT NULL,
    [tiCESP400WithdrawReasonID] TINYINT                    CONSTRAINT [DF_Un_WithdrawalReason_tiCESP400WithdrawReasonID] DEFAULT (1) NOT NULL,
    CONSTRAINT [PK_Un_WithdrawalReason] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_WithdrawalReason_Un_CESP400WithdrawReason__tiCESP400WithdrawReasonID] FOREIGN KEY ([tiCESP400WithdrawReasonID]) REFERENCES [dbo].[Un_CESP400WithdrawReason] ([tiCESP400WithdrawReasonID]),
    CONSTRAINT [FK_Un_WithdrawalReason_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raisons de retrait de cotisation excédentaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_WithdrawalReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’opération de retrait', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_WithdrawalReason', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison du retrait (1 = Montant versé en trop (Décès), 2 = Montant versé en trop (Délégation de solde), 3 = Prélèvement automatique versé en trop (CPA), 4 = Correction d’un dépôt dans une mauvaise convention, 5 = Changement de mode de dépôt, 6 = Autres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_WithdrawalReason', @level2type = N'COLUMN', @level2name = N'WithdrawalReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison de remboursement de subventions (400)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_WithdrawalReason', @level2type = N'COLUMN', @level2name = N'tiCESP400WithdrawReasonID';

