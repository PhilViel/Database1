CREATE TABLE [dbo].[CRQ_DocLink] (
    [DocLinkID]   INT NOT NULL,
    [DocLinkType] INT NOT NULL,
    [DocID]       INT NOT NULL,
    CONSTRAINT [PK_CRQ_DocLink] PRIMARY KEY CLUSTERED ([DocLinkID] ASC, [DocLinkType] ASC, [DocID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_DocLink_CRQ_Doc__DocID] FOREIGN KEY ([DocID]) REFERENCES [dbo].[CRQ_Doc] ([DocID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CRQ_DocLink_DocLinkType]
    ON [dbo].[CRQ_DocLink]([DocLinkType] ASC)
    INCLUDE([DocID]) WITH (FILLFACTOR = 90);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Elle contient les liens entres des tables de l''aplication client et les documents.  C''est lien permettre d''afficher des historiques de document sur différent objets.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocLink';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la table de l''application client.  Avec le DocLinkType on peut connaître auquel enregistrement de la table client on fait référence.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocLink', @level2type = N'COLUMN', @level2name = N'DocLinkID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID permettant de connaître à quel table de l''application client on fait référence. (Ex: 1 = TUn_Convention)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocLink', @level2type = N'COLUMN', @level2name = N'DocLinkType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du document (CRQ_Doc).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_DocLink', @level2type = N'COLUMN', @level2name = N'DocID';

