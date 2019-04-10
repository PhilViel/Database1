CREATE TABLE [dbo].[tblGENE_ImpotProvincial] (
    [DateEffective] DATE            NOT NULL,
    [ProvinceID]    INT             NOT NULL,
    [MontantMin]    MONEY           NOT NULL,
    [MontantMax]    MONEY           NOT NULL,
    [Pourcentage]   DECIMAL (10, 4) NOT NULL,
    CONSTRAINT [PK_GENE_ImpotProvincial] PRIMARY KEY CLUSTERED ([DateEffective] ASC, [ProvinceID] ASC, [MontantMax] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_GENE_ImpotProvincial_Mo_State__ProvinceID] FOREIGN KEY ([ProvinceID]) REFERENCES [dbo].[Mo_State] ([StateID])
);

