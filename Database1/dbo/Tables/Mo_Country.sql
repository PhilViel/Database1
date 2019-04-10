CREATE TABLE [dbo].[Mo_Country] (
    [CountryID]     [dbo].[MoCountry]     NOT NULL,
    [CountryName]   [dbo].[MoCompanyName] NOT NULL,
    [CountryTaxPct] [dbo].[MoPctPos]      NOT NULL,
    CONSTRAINT [PK_Mo_Country] PRIMARY KEY CLUSTERED ([CountryID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_Country_CountryName]
    ON [dbo].[Mo_Country]([CountryName] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Country';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de trois caractères désignant ce pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Country', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Le pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Country', @level2type = N'COLUMN', @level2name = N'CountryName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage de taxation de ce pays.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Country', @level2type = N'COLUMN', @level2name = N'CountryTaxPct';

