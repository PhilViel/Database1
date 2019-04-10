CREATE TABLE [dbo].[FournisseurServiceFinancierJourFerie] (
    [FournisseurServiceFinancierID] INT  NOT NULL,
    [DateFerie]                     DATE NOT NULL,
    CONSTRAINT [PK_FournisseurServiceFinancierJourFerie] PRIMARY KEY CLUSTERED ([FournisseurServiceFinancierID] ASC, [DateFerie] ASC) WITH (FILLFACTOR = 90)
);

