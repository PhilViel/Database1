CREATE TABLE [dbo].[Un_OtherAccountOper] (
    [OtherAccountOperID]     [dbo].[MoID]    IDENTITY (1, 1) NOT NULL,
    [OperID]                 [dbo].[MoID]    NOT NULL,
    [OtherAccountOperAmount] [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_OtherAccountOper] PRIMARY KEY CLUSTERED ([OtherAccountOperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OtherAccountOper_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_OtherAccountOper_OperID]
    ON [dbo].[Un_OtherAccountOper]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui contient les transactions faient dans la compte Gestion Universitas Inc (GUI).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OtherAccountOper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la transaction du compte GUI.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OtherAccountOper', @level2type = N'COLUMN', @level2name = N'OtherAccountOperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) à laquel appartient la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OtherAccountOper', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la transaction.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OtherAccountOper', @level2type = N'COLUMN', @level2name = N'OtherAccountOperAmount';

