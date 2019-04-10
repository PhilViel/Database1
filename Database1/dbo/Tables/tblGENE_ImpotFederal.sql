CREATE TABLE [dbo].[tblGENE_ImpotFederal] (
    [DateEffective] DATE            NOT NULL,
    [ProvinceID]    INT             NOT NULL,
    [MontantMin]    MONEY           NOT NULL,
    [MontantMax]    MONEY           NOT NULL,
    [Pourcentage]   DECIMAL (10, 4) NOT NULL,
    CONSTRAINT [PK_GENE_ImpotFederal] PRIMARY KEY CLUSTERED ([DateEffective] ASC, [ProvinceID] ASC, [MontantMax] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_ImpotFederal_Mo_State__ProvinceID] FOREIGN KEY ([ProvinceID]) REFERENCES [dbo].[Mo_State] ([StateID])
);

