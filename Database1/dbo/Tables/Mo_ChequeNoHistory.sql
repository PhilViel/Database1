CREATE TABLE [dbo].[Mo_ChequeNoHistory] (
    [ChequeNoHistoryID]   [dbo].[MoID]   IDENTITY (1, 1) NOT NULL,
    [ChequeID]            [dbo].[MoID]   NOT NULL,
    [ChequeNoHistoryDate] [dbo].[MoDate] NOT NULL,
    [ChequeNo]            [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Mo_ChequeNoHistory] PRIMARY KEY CLUSTERED ([ChequeNoHistoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_ChequeNoHistory_Mo_Cheque__ChequeID] FOREIGN KEY ([ChequeID]) REFERENCES [dbo].[Mo_Cheque] ([ChequeID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant l''historique des numérés des chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeNoHistory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''enregistrement d''historique de numéro de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeNoHistory', @level2type = N'COLUMN', @level2name = N'ChequeNoHistoryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du chèque (Mo_Cheque) auquel l''enregistrement d''historique de numéro de chèque appartient.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeNoHistory', @level2type = N'COLUMN', @level2name = N'ChequeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du numéro.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeNoHistory', @level2type = N'COLUMN', @level2name = N'ChequeNoHistoryDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de chèque.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeNoHistory', @level2type = N'COLUMN', @level2name = N'ChequeNo';

