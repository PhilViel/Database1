CREATE TABLE [DILC].[Projet] (
    [iID_Project]       INT          NOT NULL,
    [vcProject]         VARCHAR (50) NOT NULL,
    [idScheduledImport] INT          NOT NULL,
    [idScheduledExport] INT          NOT NULL,
    [bActivated]        BIT          CONSTRAINT [DF_Projet_bActivated] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Projet] PRIMARY KEY CLUSTERED ([iID_Project] ASC)
);

