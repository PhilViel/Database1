CREATE TABLE [dbo].[CasParticulierType] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [TypeCasParticulier] VARCHAR (250) NOT NULL,
    [EstActif]           BIT           CONSTRAINT [DF_CasParticulierType_EstActif] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_CasParticulierType] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CasParticulierType_CasParticulierType__ID] FOREIGN KEY ([ID]) REFERENCES [dbo].[CasParticulierType] ([ID])
);

