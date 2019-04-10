CREATE TABLE [dbo].[Un_OperAccountInfo] (
    [OperID]      [dbo].[MoID]   NOT NULL,
    [BankID]      [dbo].[MoID]   NOT NULL,
    [TransitNo]   [dbo].[MoDesc] NOT NULL,
    [AccountName] [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Un_OperAccountInfo] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperAccountInfo_Mo_Bank__BankID] FOREIGN KEY ([BankID]) REFERENCES [dbo].[Mo_Bank] ([BankID]),
    CONSTRAINT [FK_Un_OperAccountInfo_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_OperAccountInfo_BankID]
    ON [dbo].[Un_OperAccountInfo]([BankID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les comptes bancaires affecté par l''opération.  Cette table est utilisé uniquement avec les CPA (Prélèvement automatique).  Elle est remplis automatiquement.  On copie le compte bancaire de la convention (Un_ConventionAccount) lors du traitement des CPAs.  De cette façon si le compte de la convention on garde tout de même un historique de dans qu''elles comptes les CPAs ont été prélevés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperAccountInfo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperAccountInfo', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la succursales (Mo_Bank) à laquel appartient le compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperAccountInfo', @level2type = N'COLUMN', @level2name = N'BankID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro du compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperAccountInfo', @level2type = N'COLUMN', @level2name = N'TransitNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du compte. Généralement le nom du souscripteur suivit d''une virgule, une espace et du prénom.  Le tout en majuscule et sans accents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperAccountInfo', @level2type = N'COLUMN', @level2name = N'AccountName';

