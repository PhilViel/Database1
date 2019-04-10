CREATE TABLE [dbo].[tblREPR_FormationsPeriodesUFC] (
    [iID_PeriodeUFC]    INT      IDENTITY (1, 1) NOT NULL,
    [dtDate_Debut]      DATETIME NOT NULL,
    [dtDate_Fin]        DATETIME NOT NULL,
    [iID_TypeFormation] INT      NULL,
    CONSTRAINT [PK_REPR_FormationsPeriodesUFC] PRIMARY KEY CLUSTERED ([iID_PeriodeUFC] ASC) WITH (FILLFACTOR = 90)
);

