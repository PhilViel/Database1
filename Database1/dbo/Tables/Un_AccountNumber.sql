CREATE TABLE [dbo].[Un_AccountNumber] (
    [iAccountNumberID] INT          IDENTITY (1, 1) NOT NULL,
    [iAccountID]       INT          NOT NULL,
    [dtStart]          DATETIME     NOT NULL,
    [dtEnd]            DATETIME     NULL,
    [vcAccountNumber]  VARCHAR (75) NOT NULL,
    CONSTRAINT [PK_Un_AccountNumber] PRIMARY KEY CLUSTERED ([iAccountNumberID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_AccountNumber_Un_Account__iAccountID] FOREIGN KEY ([iAccountID]) REFERENCES [dbo].[Un_Account] ([iAccountID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des numéros de comptes compatables', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du numéro de compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountNumber', @level2type = N'COLUMN', @level2name = N'iAccountNumberID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountNumber', @level2type = N'COLUMN', @level2name = N'iAccountID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur du numéro de compte', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountNumber', @level2type = N'COLUMN', @level2name = N'dtStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_AccountNumber', @level2type = N'COLUMN', @level2name = N'vcAccountNumber';

