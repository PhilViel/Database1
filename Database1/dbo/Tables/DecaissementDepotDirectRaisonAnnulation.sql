CREATE TABLE [dbo].[DecaissementDepotDirectRaisonAnnulation] (
    [IDRaisonAnnulation] INT           IDENTITY (1, 1) NOT NULL,
    [DescriptionRaison]  VARCHAR (150) NULL,
    CONSTRAINT [PK_DecaissementDepotDirectRaisonAnnulation] PRIMARY KEY CLUSTERED ([IDRaisonAnnulation] ASC) WITH (FILLFACTOR = 90)
);

