CREATE TABLE [dbo].[Mo_BankType] (
    [BankTypeID]   [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [BankTypeName] [dbo].[MoCompanyName] NOT NULL,
    [BankTypeCode] [dbo].[MoDesc]        NOT NULL,
    CONSTRAINT [PK_Mo_BankType] PRIMARY KEY CLUSTERED ([BankTypeID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des institutions financières.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''institution financière.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankType', @level2type = N'COLUMN', @level2name = N'BankTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de l''institution financière.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankType', @level2type = N'COLUMN', @level2name = N'BankTypeName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de l''institution financière.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankType', @level2type = N'COLUMN', @level2name = N'BankTypeCode';

