CREATE TABLE [dbo].[tblLNNTE_tracage] (
    [tel]       NUMERIC (20)  NOT NULL,
    [date]      DATETIME2 (7) NULL,
    [matricule] INT           NULL,
    [DateMAJ]   DATETIME      NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_LNNTE_tracage_tel_matricule_date]
    ON [dbo].[tblLNNTE_tracage]([tel] ASC, [matricule] ASC, [date] ASC) WITH (FILLFACTOR = 90);

