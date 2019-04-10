CREATE TABLE [dbo].[tblREPR_Formations] (
    [iID_Formation]      INT           IDENTITY (1, 1) NOT NULL,
    [iID_FormationUFC]   INT           NOT NULL,
    [iID_PeriodeUFC]     INT           NOT NULL,
    [dtDate_Debut]       DATETIME      NOT NULL,
    [dtDate_Fin]         DATETIME      NOT NULL,
    [vcLieu_Formation]   VARCHAR (100) NULL,
    [vcFormateur]        VARCHAR (50)  NULL,
    [bFormation_EnLigne] BIT           NOT NULL,
    [vcDescription]      VARCHAR (250) NULL,
    CONSTRAINT [PK_REPR_Formations] PRIMARY KEY CLUSTERED ([iID_Formation] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_REPR_Formations_REPR_FormationsPeriodesUFC__iIDPeriodeUFC] FOREIGN KEY ([iID_PeriodeUFC]) REFERENCES [dbo].[tblREPR_FormationsPeriodesUFC] ([iID_PeriodeUFC]),
    CONSTRAINT [FK_REPR_Formations_REPR_FormationsUFC__iIDFormationUFC] FOREIGN KEY ([iID_FormationUFC]) REFERENCES [dbo].[tblREPR_FormationsUFC] ([iID_FormationUFC])
);

