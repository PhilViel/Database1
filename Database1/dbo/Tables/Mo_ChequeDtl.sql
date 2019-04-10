CREATE TABLE [dbo].[Mo_ChequeDtl] (
    [ChequeDtlID]        [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ChequeID]           [dbo].[MoID]         NOT NULL,
    [ChequeDtlDesc]      [dbo].[MoLongDesc]   NOT NULL,
    [ChequeDtlAmount]    [dbo].[MoMoney]      NOT NULL,
    [ChequeDtlTableName] [dbo].[MoDescoption] NULL,
    [ChequeDtlCodeID]    [dbo].[MoIDoption]   NULL,
    CONSTRAINT [PK_Mo_ChequeDtl] PRIMARY KEY CLUSTERED ([ChequeDtlID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_ChequeDtl_Mo_Cheque__ChequeID] FOREIGN KEY ([ChequeID]) REFERENCES [dbo].[Mo_Cheque] ([ChequeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_ChequeDtl_ChequeID]
    ON [dbo].[Mo_ChequeDtl]([ChequeID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des détails des chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du détail chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl', @level2type = N'COLUMN', @level2name = N'ChequeDtlID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du chèque (Mo_Cheque) auquel appartient le détail.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl', @level2type = N'COLUMN', @level2name = N'ChequeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl', @level2type = N'COLUMN', @level2name = N'ChequeDtlDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de l''objet auquel le détail du chèque est lié. (Ex:Un_Oper, Un_Convention, etc.)  Avec le champ ChequeDtlCodeID, on peut faire un lien unique avec l''objet lié au détail du chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl', @level2type = N'COLUMN', @level2name = N'ChequeDtlTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet auquel le détail du chèque est lié.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeDtl', @level2type = N'COLUMN', @level2name = N'ChequeDtlCodeID';

