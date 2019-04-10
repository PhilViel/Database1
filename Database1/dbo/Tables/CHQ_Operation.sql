CREATE TABLE [dbo].[CHQ_Operation] (
    [iOperationID]  INT          IDENTITY (1, 1) NOT NULL,
    [bStatus]       BIT          NULL,
    [iConnectID]    INT          NULL,
    [dtOperation]   DATETIME     NOT NULL,
    [vcDescription] VARCHAR (50) NULL,
    [vcRefType]     VARCHAR (10) NOT NULL,
    [vcAccount]     VARCHAR (50) NULL,
    CONSTRAINT [PK_CHQ_Operation] PRIMARY KEY CLUSTERED ([iOperationID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_CHQ_Operation_vcRefType_dtOperation]
    ON [dbo].[CHQ_Operation]([vcRefType] ASC, [dtOperation] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des opérations pour chèques', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Operation identificateur unique', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'iOperationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Statut de l''opération (0=disponible, 1=annulé)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'bStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique de connexion de l''usager qui fait l''insertion de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'iConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'dtOperation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La convention qui est la source de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Le type d''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'vcRefType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La description du compte comptable.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Operation', @level2type = N'COLUMN', @level2name = N'vcAccount';

