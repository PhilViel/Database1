CREATE TABLE [dbo].[CRQ_Version] (
    [VersionID]          INT      NOT NULL,
    [ImplementationDate] DATETIME NULL,
    CONSTRAINT [PK_CRQ_Version] PRIMARY KEY CLUSTERED ([VersionID] ASC) WITH (FILLFACTOR = 90)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Contient les différentes version et leur date d''implentation chez le client.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Version';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de version de la base de données.  Celle avec la date d''implentation la plus élevé avant aujourd''hui est la version courante', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Version', @level2type = N'COLUMN', @level2name = N'VersionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquel la version a été implenté', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Version', @level2type = N'COLUMN', @level2name = N'ImplementationDate';

