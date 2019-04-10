CREATE TABLE [dbo].[DemandeAri] (
    [Id]               INT          NOT NULL,
    [IdConvention]     INT          NOT NULL,
    [NumeroConvention] VARCHAR (15) NULL,
    CONSTRAINT [PK_DemandeAri] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_DemandeAri_Demande__Id] FOREIGN KEY ([Id]) REFERENCES [dbo].[Demande] ([Id]),
    CONSTRAINT [FK_DemandeAri_Un_Convention__IdConvention] FOREIGN KEY ([IdConvention]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);

