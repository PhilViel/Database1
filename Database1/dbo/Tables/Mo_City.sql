CREATE TABLE [dbo].[Mo_City] (
    [CityID]    [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [CountryID] [dbo].[MoCountry] NULL,
    [CityName]  [dbo].[MoCity]    NULL,
    [StateID]   INT               NULL,
    [bInactif]  BIT               CONSTRAINT [DF_Mo_City_bInactif] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Mo_City] PRIMARY KEY CLUSTERED ([CityID] ASC),
    CONSTRAINT [FK_Mo_City_Mo_Country__CountryID] FOREIGN KEY ([CountryID]) REFERENCES [dbo].[Mo_Country] ([CountryID]),
    CONSTRAINT [FK_Mo_City_Mo_State_StateID] FOREIGN KEY ([StateID]) REFERENCES [dbo].[Mo_State] ([StateID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_City_CountryID]
    ON [dbo].[Mo_City]([CountryID] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des villes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_City';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_City', @level2type = N'COLUMN', @level2name = N'CityID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du pays (Mo_Country) dont fait partie la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_City', @level2type = N'COLUMN', @level2name = N'CountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la ville.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_City', @level2type = N'COLUMN', @level2name = N'CityName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant de l''état ou de la province', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_City', @level2type = N'COLUMN', @level2name = N'StateID';

