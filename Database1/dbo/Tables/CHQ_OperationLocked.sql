CREATE TABLE [dbo].[CHQ_OperationLocked] (
    [iOperationLockedID] INT      IDENTITY (1, 1) NOT NULL,
    [iOperationID]       INT      NOT NULL,
    [dtLocked]           DATETIME NOT NULL,
    [iConnectID]         INT      NOT NULL,
    CONSTRAINT [PK_CHQ_OperationLocked] PRIMARY KEY CLUSTERED ([iOperationLockedID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des opérations barrées pour validation de changement de destinataire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationLocked';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la barrure', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationLocked', @level2type = N'COLUMN', @level2name = N'iOperationLockedID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''opération barrée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationLocked', @level2type = N'COLUMN', @level2name = N'iOperationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure ou à laquelle la barrure a été mise.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationLocked', @level2type = N'COLUMN', @level2name = N'dtLocked';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connection de l''usager qui a mis la barrure.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_OperationLocked', @level2type = N'COLUMN', @level2name = N'iConnectID';

