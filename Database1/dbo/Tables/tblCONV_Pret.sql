CREATE TABLE [dbo].[tblCONV_Pret] (
    [iID_Pret]      INT          IDENTITY (1, 1) NOT NULL,
    [vcNumero_Pret] VARCHAR (50) NOT NULL,
    [SubscriberID]  INT          NOT NULL,
    CONSTRAINT [PK_iID_Pret] PRIMARY KEY CLUSTERED ([iID_Pret] ASC),
    CONSTRAINT [FK_tblPret_Un_Subscriber__SubscriberID] FOREIGN KEY ([SubscriberID]) REFERENCES [dbo].[Un_Subscriber] ([SubscriberID])
);


GO
CREATE NONCLUSTERED INDEX [IX_tblCONV_Pret_SubscriberID]
    ON [dbo].[tblCONV_Pret]([SubscriberID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les informations des prêts signés par des souscripteurs au près de prêteur (Ex: La Capitale).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_Pret';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique auto-incrémenté du prêt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_Pret', @level2type = N'COLUMN', @level2name = N'iID_Pret';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant fourni par le prêteur permettant de relier le prêt au souscripteur.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_Pret', @level2type = N'COLUMN', @level2name = N'vcNumero_Pret';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Clé étrangère sur la table Un_Subscriber', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblCONV_Pret', @level2type = N'COLUMN', @level2name = N'SubscriberID';

