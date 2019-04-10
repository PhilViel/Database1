CREATE TABLE [dbo].[CHQ_NewRecipientsForCheckCanceled] (
    [iRecipientID] INT NOT NULL,
    CONSTRAINT [PK_CHQ_NewRecipientsForCheckCanceled] PRIMARY KEY CLUSTERED ([iRecipientID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CHQ_NewRecipientsForCheckCanceled_Mo_Human__iRecipientID] FOREIGN KEY ([iRecipientID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des destinatires disponibles pour les chèques annulés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_NewRecipientsForCheckCanceled';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du destinataire', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CHQ_NewRecipientsForCheckCanceled', @level2type = N'COLUMN', @level2name = N'iRecipientID';

