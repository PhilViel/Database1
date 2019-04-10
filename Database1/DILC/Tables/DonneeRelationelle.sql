CREATE TABLE [DILC].[DonneeRelationelle] (
    [iID_DonneeRelationelle] INT          IDENTITY (1, 1) NOT NULL,
    [vcDonneeRelationelle]   VARCHAR (50) NOT NULL,
    [iID_Project]            INT          NOT NULL,
    [idScheduledImport]      INT          NULL,
    CONSTRAINT [PK_DonneeRelationelle] PRIMARY KEY CLUSTERED ([iID_DonneeRelationelle] ASC),
    CONSTRAINT [FK_DonneeRelationelle_Projet__iIDProject] FOREIGN KEY ([iID_Project]) REFERENCES [DILC].[Projet] ([iID_Project])
);

