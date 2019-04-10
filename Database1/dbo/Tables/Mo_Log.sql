CREATE TABLE [dbo].[Mo_Log] (
    [LogID]        [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ConnectID]    [dbo].[MoID]         NOT NULL,
    [LogTime]      [dbo].[MoGetDate]    NOT NULL,
    [LogTableName] [dbo].[MoDesc]       NOT NULL,
    [LogCodeID]    [dbo].[MoIDoption]   NULL,
    [LogActionID]  [dbo].[MoLogaction]  NOT NULL,
    [LogText]      [dbo].[MoTextoption] NULL,
    [LoginName]    VARCHAR (50)         NULL,
    CONSTRAINT [PK_Mo_Log] PRIMARY KEY CLUSTERED ([LogID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Log_Mo_Connect__ConnectID] FOREIGN KEY ([ConnectID]) REFERENCES [dbo].[Mo_Connect] ([ConnectID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Log_LogTableName_LogCodeID_LogTime]
    ON [dbo].[Mo_Log]([LogTableName] ASC, [LogCodeID] ASC, [LogTime] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_Log] ON [dbo].[Mo_Log] FOR INSERT, UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger

	-- Si la table #DisableTrigger est présente, il se pourrait que le trigger
	-- ne soit pas à exécuter
	IF object_id('tempdb..#DisableTrigger') is not null 
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	-- *** FIN AVERTISSEMENT *** 

	IF UPDATE(LogTime)	
		UPDATE Mo_Log SET LogTime = dbo.fn_Mo_IsDateNull( i.LogTime)
		FROM Mo_Log M, inserted i
		WHERE M.LogID = i.LogID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
CREATE TRIGGER [dbo].[TR_Mo_Log_ins] ON [dbo].[Mo_Log]
	FOR INSERT
AS BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	UPDATE L
	   SET LoginName = dbo.GetUserContext()
	  FROM dbo.Mo_Log L JOIN inserted I ON I.LogID = L.LogID
	 WHERE L.LoginName IS NULL
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Log] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des logs.  Les logs sont des traces qu''on conserve d''ajout, modification ou suppression d''enregistrement dans des tables.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du log.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion (Mo_Connect) de l''usager qui a fait l''ajout, la modification ou la suppression qui a créé le log.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date heure de la création du log.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la table sur laquel a eu lieu l''ajout, la modification ou la suppression qui a créé le log.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''objet contenu dans la table. (Ex: si TableName=''TUn_Convention'' alors ce champs correspondra au ConventionID de l''enregistrement affecté.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogCodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Un caractère dégnignant l''opération effectué sur l''enregistrement (''I''=Insertion, ''U''=Modification, ''D''=Suppression).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogActionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de ce qui a été effectué.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Log', @level2type = N'COLUMN', @level2name = N'LogText';

