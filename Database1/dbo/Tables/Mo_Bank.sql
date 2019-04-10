CREATE TABLE [dbo].[Mo_Bank] (
    [BankID]      [dbo].[MoID]   NOT NULL,
    [BankTypeID]  [dbo].[MoID]   NOT NULL,
    [BankTransit] [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Mo_Bank] PRIMARY KEY CLUSTERED ([BankID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Bank_Mo_BankType__BankTypeID] FOREIGN KEY ([BankTypeID]) REFERENCES [dbo].[Mo_BankType] ([BankTypeID]),
    CONSTRAINT [FK_Mo_Bank_Mo_Company__BankID] FOREIGN KEY ([BankID]) REFERENCES [dbo].[Mo_Company] ([CompanyID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Bank_BankTypeID]
    ON [dbo].[Mo_Bank]([BankTypeID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des succursales d''institutions financières.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Bank';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la succursale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Bank', @level2type = N'COLUMN', @level2name = N'BankID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''institution financière (Mo_BankType) à laquel appartient la succursale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Bank', @level2type = N'COLUMN', @level2name = N'BankTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Transit de la succursale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Bank', @level2type = N'COLUMN', @level2name = N'BankTransit';

