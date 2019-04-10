CREATE TABLE [dbo].[Un_BankFile] (
    [BankFileID]        [dbo].[MoID]   NOT NULL,
    [BankFileStartDate] [dbo].[MoDate] NOT NULL,
    [BankFileEndDate]   [dbo].[MoDate] NOT NULL,
    CONSTRAINT [PK_Un_BankFile] PRIMARY KEY CLUSTERED ([BankFileID] ASC) WITH (FILLFACTOR = 90)
);


GO

CREATE TRIGGER [dbo].[TUn_BankFile] ON [dbo].[Un_BankFile] FOR INSERT, UPDATE 
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

  UPDATE Un_BankFile SET
    BankFileStartDate = dbo.fn_Mo_DateNoTime( i.BankFileStartDate),
    BankFileEndDate = dbo.fn_Mo_DateNoTime( i.BankFileEndDate)
  FROM Un_BankFile U, inserted i
  WHERE U.BankFileID = i.BankFileID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Cette table contient les fichiers bancaires.  Un fichier bancaire est un fichier envoyé à la banque contenant tout les prélèvements automatiques pour une période.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BankFile';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du fichier bancaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BankFile', @level2type = N'COLUMN', @level2name = N'BankFileID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début de la période couverte par le fichier bancaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BankFile', @level2type = N'COLUMN', @level2name = N'BankFileStartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de la période couverte par le fichier bancaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BankFile', @level2type = N'COLUMN', @level2name = N'BankFileEndDate';

