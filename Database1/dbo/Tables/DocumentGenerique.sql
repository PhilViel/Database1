CREATE TABLE [dbo].[DocumentGenerique] (
    [ID]            INT            NOT NULL,
    [TypeChemin]    VARCHAR (15)   NOT NULL,
    [CheminFichier] VARCHAR (2000) NOT NULL,
    CONSTRAINT [PK_DocumentGenerique] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

