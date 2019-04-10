CREATE TABLE [dbo].[tblGENE_TypeTelephone] (
    [iID_TypeTelephone] INT          NOT NULL,
    [vcCode]            VARCHAR (5)  NOT NULL,
    [vcDescription]     VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_GENE_TypeTelephone] PRIMARY KEY CLUSTERED ([iID_TypeTelephone] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table contenant les types de téléphone', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeTelephone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant unique du type de téléphone', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeTelephone', @level2type = N'COLUMN', @level2name = N'iID_TypeTelephone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code du type de téléphone', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeTelephone', @level2type = N'COLUMN', @level2name = N'vcCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Description du type de téléphone', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'tblGENE_TypeTelephone', @level2type = N'COLUMN', @level2name = N'vcDescription';

