CREATE TABLE [dbo].[Un_TIO] (
    [iTIOID]     INT IDENTITY (1, 1) NOT NULL,
    [iOUTOperID] INT NOT NULL,
    [iTINOperID] INT NOT NULL,
    [iTFROperID] INT NULL,
    CONSTRAINT [PK_Un_TIO] PRIMARY KEY CLUSTERED ([iTIOID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_TIO_Un_Oper__iOUTOperID] FOREIGN KEY ([iOUTOperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_TIO_Un_Oper__iTFROperID] FOREIGN KEY ([iTFROperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_TIO_Un_Oper__iTINOperID] FOREIGN KEY ([iTINOperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des transferts internes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIO';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’enregistrement de transfert interne TIO', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIO', @level2type = N'COLUMN', @level2name = N'iTIOID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’opération OUT', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIO', @level2type = N'COLUMN', @level2name = N'iOUTOperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’opération TIN', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIO', @level2type = N'COLUMN', @level2name = N'iTINOperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l’opération TFR', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TIO', @level2type = N'COLUMN', @level2name = N'iTFROperID';

