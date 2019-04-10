CREATE TABLE [dbo].[AgentBourseDecaissment] (
    [Id]                 INT           IDENTITY (1, 1) NOT NULL,
    [NomPrenomAgent]     VARCHAR (MAX) NOT NULL,
    [IdentifiantReseau]  VARCHAR (MAX) NOT NULL,
    [AccesDemandePaeRin] BIT           NOT NULL,
    [AccesDemandeAri]    BIT           NOT NULL,
    CONSTRAINT [PK_AgentBourseDecaissment] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90)
);

