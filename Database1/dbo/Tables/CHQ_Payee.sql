CREATE TABLE [dbo].[CHQ_Payee] (
    [iPayeeID] INT NOT NULL,
    CONSTRAINT [PK_CHQ_Payee] PRIMARY KEY CLUSTERED ([iPayeeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_Payee_Mo_Human__iPayeeID] FOREIGN KEY ([iPayeeID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'La table des destinataires de chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Payee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'ID unique du destinataire du chèque', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_Payee', @level2type = N'COLUMN', @level2name = N'iPayeeID';

