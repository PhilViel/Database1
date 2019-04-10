CREATE TABLE [dbo].[Mo_Firm] (
    [FirmID]        [dbo].[MoID]         NOT NULL,
    [MonthlyTarget] [dbo].[MoMoney]      NOT NULL,
    [FirmStatusID]  [dbo].[MoFirmStatus] NOT NULL,
    CONSTRAINT [PK_Mo_Firm] PRIMARY KEY CLUSTERED ([FirmID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_Firm_Mo_Company__FirmID] FOREIGN KEY ([FirmID]) REFERENCES [dbo].[Mo_Company] ([CompanyID])
);


GO

CREATE TRIGGER [dbo].[TMo_Firm] ON [dbo].[Mo_Firm] FOR INSERT, UPDATE
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
	
  UPDATE Mo_Firm SET
    MonthlyTarget = ROUND(ISNULL(i.MonthlyTarget, 0), 2)
  FROM Mo_Firm M, inserted i
  WHERE M.FirmID = i.FirmID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des firmes.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Firm';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la firme.  Correspond à un ID unique de compagnie (Mo_Company).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Firm', @level2type = N'COLUMN', @level2name = N'FirmID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chiffre d''affaire budjetté par mois.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Firm', @level2type = N'COLUMN', @level2name = N'MonthlyTarget';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Status de la firme. (''A''=Active, ''I''=Inactive)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Firm', @level2type = N'COLUMN', @level2name = N'FirmStatusID';

