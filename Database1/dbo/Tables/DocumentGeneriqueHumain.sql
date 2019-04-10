CREATE TABLE [dbo].[DocumentGeneriqueHumain] (
    [IdDocument] INT NOT NULL,
    [IdHumain]   INT NOT NULL,
    CONSTRAINT [FK_DocumentGeneriqueHumain_DocumentGenerique__IdDocument] FOREIGN KEY ([IdDocument]) REFERENCES [dbo].[DocumentGenerique] ([ID]),
    CONSTRAINT [FK_DocumentGeneriqueHumain_Mo_Human__IdHumain] FOREIGN KEY ([IdHumain]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);

