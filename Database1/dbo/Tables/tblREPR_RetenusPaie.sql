CREATE TABLE [dbo].[tblREPR_RetenusPaie] (
    [RepCode] VARCHAR (75) NOT NULL,
    [Type]    VARCHAR (20) NOT NULL,
    [Montant] MONEY        NULL,
    CONSTRAINT [PK_REPR_RetenusPaie] PRIMARY KEY CLUSTERED ([RepCode] ASC, [Type] ASC) WITH (FILLFACTOR = 90)
);

