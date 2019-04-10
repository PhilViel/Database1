CREATE TABLE [dbo].[CHQ_CheckOperationDetail] (
    [iCheckOperationDetailID] INT IDENTITY (1, 1) NOT NULL,
    [iOperationDetailID]      INT NOT NULL,
    [iCheckID]                INT NOT NULL,
    CONSTRAINT [PK_CHQ_CheckOperationDetail] PRIMARY KEY CLUSTERED ([iCheckOperationDetailID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_CheckOperationDetail_CHQ_Check__iCheckID] FOREIGN KEY ([iCheckID]) REFERENCES [dbo].[CHQ_Check] ([iCheckID]),
    CONSTRAINT [FK_CHQ_CheckOperationDetail_CHQ_OperationDetail__iOperationDetailID] FOREIGN KEY ([iOperationDetailID]) REFERENCES [dbo].[CHQ_OperationDetail] ([iOperationDetailID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_CheckOperationDetail_iOperationDetailID]
    ON [dbo].[CHQ_CheckOperationDetail]([iOperationDetailID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_CheckOperationDetail_iCheckID]
    ON [dbo].[CHQ_CheckOperationDetail]([iCheckID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des opérations proposés pour chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckOperationDetail';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de chèque - détail d''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckOperationDetail', @level2type = N'COLUMN', @level2name = N'iCheckOperationDetailID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du détail d''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckOperationDetail', @level2type = N'COLUMN', @level2name = N'iOperationDetailID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckOperationDetail', @level2type = N'COLUMN', @level2name = N'iCheckID';

