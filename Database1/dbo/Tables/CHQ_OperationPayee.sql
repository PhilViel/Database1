CREATE TABLE [dbo].[CHQ_OperationPayee] (
    [iOperationPayeeID]    INT           IDENTITY (1, 1) NOT NULL,
    [iPayeeID]             INT           NOT NULL,
    [iOperationID]         INT           NOT NULL,
    [iPayeeChangeAccepted] INT           NOT NULL,
    [dtCreated]            DATETIME      NULL,
    [vcReason]             VARCHAR (255) NULL,
    CONSTRAINT [PK_CHQ_OperationPayee] PRIMARY KEY CLUSTERED ([iOperationPayeeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_OperationPayee_CHQ_Operation__iOperationID] FOREIGN KEY ([iOperationID]) REFERENCES [dbo].[CHQ_Operation] ([iOperationID]),
    CONSTRAINT [FK_CHQ_OperationPayee_CHQ_Payee__iPayeeID] FOREIGN KEY ([iPayeeID]) REFERENCES [dbo].[CHQ_Payee] ([iPayeeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_OperationPayee_iPayeeID]
    ON [dbo].[CHQ_OperationPayee]([iPayeeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_OperationPayee_iOperationID]
    ON [dbo].[CHQ_OperationPayee]([iOperationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_CHQ_OperationPayee_iPayeeID_iOperationID_dtCreated]
    ON [dbo].[CHQ_OperationPayee]([iPayeeID] ASC, [iOperationID] ASC, [dtCreated] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des destinataires d''opérations pour chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''enregistrement d''opération-destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'iOperationPayeeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'iPayeeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'iOperationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de proposition de changement de destinataire (0=Proposé, 1=Accepté, 2=Refusé)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'iPayeeChangeAccepted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'dtCreated';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La raison de refus de changement de destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationPayee', @level2type = N'COLUMN', @level2name = N'vcReason';

