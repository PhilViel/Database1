CREATE TABLE [dbo].[DemandePaeProgrammeNumeroAnnee] (
    [ID]                           INT           NOT NULL,
    [ProgrammeNumeroAnneeFrancais] VARCHAR (500) NULL,
    [ProgrammeNumeroAnneeAnglais]  VARCHAR (500) NULL,
    CONSTRAINT [PK_DemandePaeProgrammeNumeroAnnee] PRIMARY KEY CLUSTERED ([ID] ASC)
);

