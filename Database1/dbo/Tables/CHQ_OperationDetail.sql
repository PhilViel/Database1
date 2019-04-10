CREATE TABLE [dbo].[CHQ_OperationDetail] (
    [iOperationDetailID] INT             IDENTITY (1, 1) NOT NULL,
    [iOperationID]       INT             NOT NULL,
    [fAmount]            DECIMAL (18, 4) NOT NULL,
    [vcAccount]          VARCHAR (50)    NULL,
    [vcDescription]      VARCHAR (50)    NULL,
    CONSTRAINT [PK_CHQ_OperationDetail] PRIMARY KEY CLUSTERED ([iOperationDetailID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_OperationDetail_CHQ_Operation__iOperationID] FOREIGN KEY ([iOperationID]) REFERENCES [dbo].[CHQ_Operation] ([iOperationID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_OperationDetail_iOperationID]
    ON [dbo].[CHQ_OperationDetail]([iOperationID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table du détail des opérations pour chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du détail de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail', @level2type = N'COLUMN', @level2name = N'iOperationDetailID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail', @level2type = N'COLUMN', @level2name = N'iOperationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le montant du détail de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail', @level2type = N'COLUMN', @level2name = N'fAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le numéro de compte comptable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail', @level2type = N'COLUMN', @level2name = N'vcAccount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Compte comptable', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationDetail', @level2type = N'COLUMN', @level2name = N'vcDescription';

