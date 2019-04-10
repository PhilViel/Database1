CREATE TABLE [dbo].[CHQ_CheckHistory] (
    [iCheckHistoryID] INT           IDENTITY (1, 1) NOT NULL,
    [iCheckID]        INT           NOT NULL,
    [iCheckStatusID]  INT           NOT NULL,
    [dtHistory]       DATETIME      CONSTRAINT [DF_CHQ_CheckHistory_dtHistory] DEFAULT (getdate()) NOT NULL,
    [iConnectID]      INT           NOT NULL,
    [vcReason]        VARCHAR (100) NULL,
    CONSTRAINT [PK_CHQ_CheckHistory] PRIMARY KEY CLUSTERED ([iCheckHistoryID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_CheckHistory_CHQ_Check__iCheckID] FOREIGN KEY ([iCheckID]) REFERENCES [dbo].[CHQ_Check] ([iCheckID]),
    CONSTRAINT [FK_CHQ_CheckHistory_CHQ_CheckStatus__iCheckStatusID] FOREIGN KEY ([iCheckStatusID]) REFERENCES [dbo].[CHQ_CheckStatus] ([iCheckStatusID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_CheckHistory_iCheckID]
    ON [dbo].[CHQ_CheckHistory]([iCheckID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table de l''historique de chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de l''historique de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'iCheckHistoryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'iCheckID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID du statut de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'iCheckStatusID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date d''insertion d''historique de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'dtHistory';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID de connexion de l''usager qui fait l''insertion de l''historique de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'iConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La raison pour laquelle le chèque a été annulé', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_CheckHistory', @level2type = N'COLUMN', @level2name = N'vcReason';

