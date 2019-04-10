CREATE TABLE [dbo].[DemandePaeProgrammeEtudeDuree] (
    [ID]                          INT           NOT NULL,
    [ProgrammeEtudeDureeFrancais] VARCHAR (500) NULL,
    [ProgrammeEtudeDureeAnglais]  VARCHAR (500) NULL,
    CONSTRAINT [PK_DemandePaeProgrammeEtudeDuree] PRIMARY KEY CLUSTERED ([ID] ASC)
);

