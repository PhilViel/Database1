CREATE TABLE [dbo].[tbl_TEMP_Lnnte] (
    [no_tel_interne] NUMERIC (20)  NOT NULL,
    [RepCode]        INT           NULL,
    [date_effective] NVARCHAR (25) NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_TEMP_Lnnte_NoTelInterne]
    ON [dbo].[tbl_TEMP_Lnnte]([no_tel_interne] ASC);

