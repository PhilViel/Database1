CREATE TABLE [dbo].[Un_Recipient] (
    [iRecipientID] INT NOT NULL,
    CONSTRAINT [PK_Un_Recipient] PRIMARY KEY CLUSTERED ([iRecipientID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Recipient_Mo_Human__iRecipientID] FOREIGN KEY ([iRecipientID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des destinataires', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Recipient';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d’argent', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Recipient', @level2type = N'COLUMN', @level2name = N'iRecipientID';

