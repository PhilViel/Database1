CREATE TABLE [dbo].[CRQ_Log] (
    [LogID]        INT           IDENTITY (1, 1) NOT NULL,
    [ConnectID]    INT           NOT NULL,
    [LogTableName] VARCHAR (75)  NOT NULL,
    [LogCodeID]    INT           NOT NULL,
    [LogTime]      DATETIME      NOT NULL,
    [LogActionID]  INT           NOT NULL,
    [LogDesc]      VARCHAR (125) NULL,
    [LogText]      TEXT          NULL,
    [LoginName]    VARCHAR (50)  NULL,
    CONSTRAINT [PK_CRQ_Log] PRIMARY KEY CLUSTERED ([LogID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_CRQ_Log_CRQ_LogAction__LogActionID] FOREIGN KEY ([LogActionID]) REFERENCES [dbo].[CRQ_LogAction] ([LogActionID]),
    CONSTRAINT [FK_CRQ_Log_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID])
);


GO
CREATE NONCLUSTERED INDEX [IX_CRQ_Log_LogTableName_LogCodeID]
    ON [dbo].[CRQ_Log]([LogTableName] ASC, [LogCodeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE TRIGGER dbo.TR_CRQ_Log_ins ON dbo.CRQ_Log
	FOR INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	UPDATE L
	   SET LoginName = dbo.GetUserContext()
	  FROM dbo.CRQ_Log L JOIN inserted I ON I.LogID = L.LogID
	 WHERE IsNull(L.LoginName, '') = ''
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des logs', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''usager qui a fait le log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table qui contient l''objet modifier qui a provoqué la création du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet modifier qui a provoqué la création du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure de création du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''action qui a provoqué la création du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogActionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description courte du contenu du log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Log', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'CRQ_Log', @level2type = N'COLUMN', @level2name = N'LogText';

