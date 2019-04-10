CREATE TABLE [dbo].[Un_AccountMoneyType] (
    [iAccountMoneyTypeID] INT      IDENTITY (1, 1) NOT NULL,
    [iAccountID]          INT      NOT NULL,
    [iMoneyTypeID]        INT      NOT NULL,
    [dtStart]             DATETIME NOT NULL,
    [dtEnd]               DATETIME NULL,
    CONSTRAINT [PK_Un_AccountMoneyType] PRIMARY KEY CLUSTERED ([iAccountMoneyTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_AccountMoneyType_Un_Account__iAccountID] FOREIGN KEY ([iAccountID]) REFERENCES [dbo].[Un_Account] ([iAccountID]),
    CONSTRAINT [FK_Un_AccountMoneyType_Un_MoneyType__iMoneyTypeID] FOREIGN KEY ([iMoneyTypeID]) REFERENCES [dbo].[Un_MoneyType] ([iMoneyTypeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des historiques des comptes compatables des types d''argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du lien type d’argent et compte comptable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType', @level2type = N'COLUMN', @level2name = N'iAccountMoneyTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType', @level2type = N'COLUMN', @level2name = N'iAccountID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d’argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType', @level2type = N'COLUMN', @level2name = N'iMoneyTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début du lien entre ce type d’argent et ce compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType', @level2type = N'COLUMN', @level2name = N'dtStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin du lien entre ce type d’argent et ce compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountMoneyType', @level2type = N'COLUMN', @level2name = N'dtEnd';

