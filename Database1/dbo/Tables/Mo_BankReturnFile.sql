CREATE TABLE [dbo].[Mo_BankReturnFile] (
    [BankReturnFileID]   [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [BankReturnFileName] [dbo].[MoDesc]    NOT NULL,
    [BankReturnFileDate] [dbo].[MoGetDate] NOT NULL,
    CONSTRAINT [PK_Mo_BankReturnFile] PRIMARY KEY CLUSTERED ([BankReturnFileID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_BankReturnFile_BankReturnFileDate]
    ON [dbo].[Mo_BankReturnFile]([BankReturnFileDate] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_BankReturnFile] ON [dbo].[Mo_BankReturnFile] FOR INSERT, UPDATE
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
	
  UPDATE Mo_BankReturnFile SET
    BankReturnFileDate = dbo.fn_Mo_DateNoTime( i.BankReturnFileDate)
  FROM Mo_BankReturnFile M, inserted i
  WHERE M.BankReturnFileID = i.BankReturnFileID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des fichiers de retour d''institutions financières.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier de retour.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnFile', @level2type = N'COLUMN', @level2name = N'BankReturnFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du fichier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnFile', @level2type = N'COLUMN', @level2name = N'BankReturnFileName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquel le fichier a été importé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_BankReturnFile', @level2type = N'COLUMN', @level2name = N'BankReturnFileDate';

