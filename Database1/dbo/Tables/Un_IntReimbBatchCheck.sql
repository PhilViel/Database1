CREATE TABLE [dbo].[Un_IntReimbBatchCheck] (
    [UnitID]    INT NOT NULL,
    [ConnectID] INT NOT NULL,
    CONSTRAINT [PK_Un_IntReimbBatchCheck] PRIMARY KEY CLUSTERED ([UnitID] ASC, [ConnectID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table conservant les groupe d''unités cochés par un usager dans l''outil de remboursement intégral par batch.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbBatchCheck';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d’unités', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbBatchCheck', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l’usager qui a coché le groupe d’unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbBatchCheck', @level2type = N'COLUMN', @level2name = N'ConnectID';

