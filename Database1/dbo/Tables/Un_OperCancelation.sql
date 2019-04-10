CREATE TABLE [dbo].[Un_OperCancelation] (
    [OperSourceID] [dbo].[MoID] NOT NULL,
    [OperID]       [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Un_OperCancelation] PRIMARY KEY CLUSTERED ([OperSourceID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_OperCancelation_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_OperCancelation_Un_Oper__OperSourceID] FOREIGN KEY ([OperSourceID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_OperCancelation_OperID]
    ON [dbo].[Un_OperCancelation]([OperID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les annulations financières.  Elle fait le lien entre l''opération annulé et l''opération qui l''annule.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperCancelation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) annulée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperCancelation', @level2type = N'COLUMN', @level2name = N'OperSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) qui fait l''annulation.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_OperCancelation', @level2type = N'COLUMN', @level2name = N'OperID';

