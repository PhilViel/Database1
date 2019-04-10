CREATE TABLE [dbo].[Un_Trace] (
    [iTraceID]          INT            IDENTITY (1, 1) NOT NULL,
    [ConnectID]         INT            NOT NULL,
    [iType]             INT            NOT NULL,
    [fDuration]         MONEY          NOT NULL,
    [dtStart]           DATETIME       NOT NULL,
    [dtEnd]             DATETIME       NOT NULL,
    [vcDescription]     VARCHAR (500)  NOT NULL,
    [vcStoredProcedure] VARCHAR (200)  NOT NULL,
    [vcExecutionString] VARCHAR (2000) NOT NULL,
    CONSTRAINT [PK_Un_Trace] PRIMARY KEY CLUSTERED ([iTraceID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Trace_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID])
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les traces gardé par le système des temps d''exécution', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de la trace', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'iTraceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID de connexion de l’usager', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de trace (1 = recherche, 2 = rapport)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'iType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Temps d’exécution de la procédure', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'fDuration';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure du début de l’exécution', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'dtStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure de la fin de l’exécution', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'dtEnd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de l’exécution (en texte)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'vcDescription';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la procédure stockée', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'vcStoredProcedure';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ligne d’exécution (inclus les paramètres)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Trace', @level2type = N'COLUMN', @level2name = N'vcExecutionString';

