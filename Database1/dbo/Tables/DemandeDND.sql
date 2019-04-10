CREATE TABLE [dbo].[DemandeDND] (
    [ID]            INT           NOT NULL,
    [TraitementDnd] INT           NOT NULL,
    [Info]          VARCHAR (MAX) NULL,
    CONSTRAINT [PK_DemandeDND] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandeDND_Demande__ID] FOREIGN KEY ([ID]) REFERENCES [dbo].[Demande] ([Id])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'RelancerDnDCorrige = 0, ProduireCheque = 1, RenverserOperationFinanciere = 2', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'DemandeDND', @level2type = N'COLUMN', @level2name = N'TraitementDnd';

