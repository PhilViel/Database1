CREATE TABLE [dbo].[Un_OperBankFile] (
    [OperID]     [dbo].[MoID] NOT NULL,
    [BankFileID] [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Un_OperBankFile] PRIMARY KEY CLUSTERED ([OperID] ASC, [BankFileID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperBankFile_Un_BankFile__BankFileID] FOREIGN KEY ([BankFileID]) REFERENCES [dbo].[Un_BankFile] ([BankFileID]),
    CONSTRAINT [FK_Un_OperBankFile_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les liens entres les fichiers bancaire de CPA (prélèvement) et les opérations qu''ils contiennent.  Cette table est utilisé uniquement avec les CPA.  Elle est remplis automatiquement lors du traitement des CPAs.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperBankFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperBankFile', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier bancaire (Un_BankFile) dont fait parti l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperBankFile', @level2type = N'COLUMN', @level2name = N'BankFileID';

