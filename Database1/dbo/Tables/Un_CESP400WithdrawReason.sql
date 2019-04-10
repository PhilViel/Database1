CREATE TABLE [dbo].[Un_CESP400WithdrawReason] (
    [tiCESP400WithdrawReasonID]  TINYINT       NOT NULL,
    [vcCESP400WithdrawReason]    VARCHAR (200) NOT NULL,
    [bIsCESP400WithdrawalReason] BIT           CONSTRAINT [DF_Un_CESP400WithdrawReason_bIsCESP400WithdrawalReason] DEFAULT (0) NOT NULL,
    [vcRightCode]                VARCHAR (75)  NULL,
    [bIsBECWithdrawReason]       BIT           CONSTRAINT [DF_Un_CESP400WithdrawReason_bIsBECWithdrawReason] DEFAULT ((0)) NOT NULL,
    [bRaisonPCEE]                BIT           CONSTRAINT [DF_Un_CESP400WithdrawReason_bRaisonPCEE] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_Un_CESP400WithdrawReason] PRIMARY KEY CLUSTERED ([tiCESP400WithdrawReasonID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des raisons de remboursement de transactions 400', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la raison de remboursement de subventions (400)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'tiCESP400WithdrawReasonID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Raison du remboursement de subvention (400)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'vcCESP400WithdrawReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Vrai s''il s''agit d''une raison de retrait de cotisation excédentaire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'bIsCESP400WithdrawalReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code du droit pour afficher la raison', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'vcRightCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Vrai s''il s''agit d''une raison de remboursement du BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'bIsBECWithdrawReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Indique si la raison du remboursement est liée au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP400WithdrawReason', @level2type = N'COLUMN', @level2name = N'bRaisonPCEE';

