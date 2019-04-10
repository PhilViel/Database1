CREATE TABLE [dbo].[Un_TFR] (
    [OperID]      INT NOT NULL,
    [bSendToPCEE] BIT NOT NULL,
    CONSTRAINT [PK_Un_TFR] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_TFR_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des Transferts de frais (TFR)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFR';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de l''option', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFR', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Indique si le TFR doit etre envoye au PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_TFR', @level2type = N'COLUMN', @level2name = N'bSendToPCEE';

