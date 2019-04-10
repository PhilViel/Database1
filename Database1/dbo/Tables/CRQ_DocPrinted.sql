CREATE TABLE [dbo].[CRQ_DocPrinted] (
    [DocPrintedID]      INT      IDENTITY (1, 1) NOT NULL,
    [DocID]             INT      NOT NULL,
    [DocPrintConnectID] INT      NULL,
    [DocPrintTime]      DATETIME NULL,
    CONSTRAINT [PK_CRQ_DocPrinted] PRIMARY KEY CLUSTERED ([DocPrintedID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_DocPrinted_CRQ_Doc__DocID] FOREIGN KEY ([DocID]) REFERENCES [dbo].[CRQ_Doc] ([DocID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient l''historique des impressions de documents.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocPrinted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocPrinted', @level2type = N'COLUMN', @level2name = N'DocPrintedID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du document (CRQ_Doc).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocPrinted', @level2type = N'COLUMN', @level2name = N'DocID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect.ConnectID) qui a fait l''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocPrinted', @level2type = N'COLUMN', @level2name = N'DocPrintConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure à laquel a eu lieu l''impression.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocPrinted', @level2type = N'COLUMN', @level2name = N'DocPrintTime';

