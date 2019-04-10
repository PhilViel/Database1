CREATE TABLE [dbo].[TmpMO_Adr] (
    [AdrId] INT           NULL,
    [Phone] VARCHAR (27)  NULL,
    [Email] VARCHAR (250) NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_TmpMO_Adr_AdrId]
    ON [dbo].[TmpMO_Adr]([AdrId] ASC);

