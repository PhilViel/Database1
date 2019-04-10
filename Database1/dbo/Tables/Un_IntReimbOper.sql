CREATE TABLE [dbo].[Un_IntReimbOper] (
    [IntReimbID] [dbo].[MoID] NOT NULL,
    [OperID]     [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Un_IntReimbOper] PRIMARY KEY CLUSTERED ([IntReimbID] ASC, [OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_IntReimbOper_Un_IntReimb__IntReimbID] FOREIGN KEY ([IntReimbID]) REFERENCES [dbo].[Un_IntReimb] ([IntReimbID]),
    CONSTRAINT [FK_Un_IntReimbOper_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_IntReimbOper_OperID]
    ON [dbo].[Un_IntReimbOper]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de lien entre les remboursements intégraux (Un_IntReimb) et leurs opérations (Un_Oper).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbOper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du remboursement intégral', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbOper', @level2type = N'COLUMN', @level2name = N'IntReimbID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_IntReimbOper', @level2type = N'COLUMN', @level2name = N'OperID';

