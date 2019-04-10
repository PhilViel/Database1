CREATE TABLE [dbo].[Mo_Connect] (
    [ConnectID]    [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [UserID]       [dbo].[MoID]         NOT NULL,
    [CodeID]       [dbo].[MoIDoption]   NULL,
    [ConnectStart] [dbo].[MoGetDate]    NOT NULL,
    [ConnectEnd]   [dbo].[MoDateoption] NULL,
    [StationName]  [dbo].[MoDescoption] NULL,
    [IPAddress]    [dbo].[MoDescoption] NULL,
    CONSTRAINT [PK_Mo_Connect] PRIMARY KEY CLUSTERED ([ConnectID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Connect_Mo_User__UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Mo_User] ([UserID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Connect_UserID]
    ON [dbo].[Mo_Connect]([UserID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_Connect] ON [dbo].[Mo_Connect] FOR INSERT, UPDATE
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
	
  UPDATE Mo_Connect SET
    ConnectStart = dbo.fn_Mo_IsDateNull( i.ConnectStart),
    ConnectEnd = dbo.fn_Mo_IsDateNull( i.ConnectEnd)
  FROM Mo_Connect M, inserted i
  WHERE M.ConnectID = i.ConnectID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Connect] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des connexions d''usagers présentes et passées.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la connexion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''usager (Mo_User) qui a fait cette connexion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'UserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Identifiant du code de connexion', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'CodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure du début de la connexion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'ConnectStart';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date et heure de la fin de la connexion.  Null = Connexion en cours ou arrêt anormale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'ConnectEnd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la station de laquel l''usager a fait la connexion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'StationName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Adress IP de la station de laquel l''usager a fait la connexion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Connect', @level2type = N'COLUMN', @level2name = N'IPAddress';

