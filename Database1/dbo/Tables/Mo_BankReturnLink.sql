CREATE TABLE [dbo].[Mo_BankReturnLink] (
    [BankReturnCodeID]       [dbo].[MoID]       NOT NULL,
    [BankReturnFileID]       [dbo].[MoIDoption] NULL,
    [BankReturnSourceCodeID] [dbo].[MoID]       NOT NULL,
    [BankReturnTypeID]       VARCHAR (4)        NOT NULL,
    CONSTRAINT [PK_Mo_BankReturnLink] PRIMARY KEY CLUSTERED ([BankReturnCodeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_BankReturnLink_Mo_BankReturnFile__BankReturnFileID] FOREIGN KEY ([BankReturnFileID]) REFERENCES [dbo].[Mo_BankReturnFile] ([BankReturnFileID]),
    CONSTRAINT [FK_Mo_BankReturnLink_Mo_BankReturnType__BankReturnTypeID] FOREIGN KEY ([BankReturnTypeID]) REFERENCES [dbo].[Mo_BankReturnType] ([BankReturnTypeID]),
    CONSTRAINT [FK_Mo_BankReturnLink_Un_Oper__BankReturnCodeID] FOREIGN KEY ([BankReturnCodeID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Mo_BankReturnLink_Un_Oper__BankReturnSourceCodeID] FOREIGN KEY ([BankReturnSourceCodeID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_BankReturnLink_BankReturnFileID]
    ON [dbo].[Mo_BankReturnLink]([BankReturnFileID] ASC)
    INCLUDE([BankReturnSourceCodeID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_BankReturnLink_BankReturnSourceCodeID]
    ON [dbo].[Mo_BankReturnLink]([BankReturnSourceCodeID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liens entre les NSF et les opérations (CPA, CHQ) retournés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnLink';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) de type NSF qui fait l''écriture renversant l''opération retourné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnLink', @level2type = N'COLUMN', @level2name = N'BankReturnCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier de retour (Mo_BankReturnFile).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnLink', @level2type = N'COLUMN', @level2name = N'BankReturnFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) qui est revenue NSF.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnLink', @level2type = N'COLUMN', @level2name = N'BankReturnSourceCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type de retour (Mo_BankReturnType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnLink', @level2type = N'COLUMN', @level2name = N'BankReturnTypeID';

