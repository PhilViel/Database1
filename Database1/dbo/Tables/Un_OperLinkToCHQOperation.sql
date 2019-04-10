CREATE TABLE [dbo].[Un_OperLinkToCHQOperation] (
    [iOperLinkToCHQOperationID] INT IDENTITY (1, 1) NOT NULL,
    [OperID]                    INT NOT NULL,
    [iOperationID]              INT NOT NULL,
    CONSTRAINT [PK_Un_OperLinkToCHQOperation] PRIMARY KEY CLUSTERED ([iOperLinkToCHQOperationID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperLinkToCHQOperation_CHQ_Operation__iOperationID] FOREIGN KEY ([iOperationID]) REFERENCES [dbo].[CHQ_Operation] ([iOperationID]),
    CONSTRAINT [FK_Un_OperLinkToCHQOperation_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_OperLinkToCHQOperation_OperID]
    ON [dbo].[Un_OperLinkToCHQOperation]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_OperLinkToCHQOperation_iOperationID]
    ON [dbo].[Un_OperLinkToCHQOperation]([iOperationID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liens entre les opérations du système de convention (Un_Oper) et les opérations du module des chèques (CHQ_Operation).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperLinkToCHQOperation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID du lien entre une opération du système de convention (Un_Oper) et une opération du module des chèques (CHQ_Operation).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperLinkToCHQOperation', @level2type = N'COLUMN', @level2name = N'iOperLinkToCHQOperationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’opération du système de convention (Un_Oper)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperLinkToCHQOperation', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l’opération du module des chèques (CHQ_Operation).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperLinkToCHQOperation', @level2type = N'COLUMN', @level2name = N'iOperationID';

