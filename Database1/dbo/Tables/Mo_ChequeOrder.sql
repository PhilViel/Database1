CREATE TABLE [dbo].[Mo_ChequeOrder] (
    [ChequeOrderID]   [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ChequeOrderDesc] [dbo].[MoDescoption] NULL,
    [ChequeOrderDate] [dbo].[MoGetDate]    NOT NULL,
    CONSTRAINT [PK_Mo_ChequeOrder] PRIMARY KEY CLUSTERED ([ChequeOrderID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_ChequeOrder_ChequeOrderDate]
    ON [dbo].[Mo_ChequeOrder]([ChequeOrderDate] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_ChequeOrder] ON [dbo].[Mo_ChequeOrder] FOR INSERT, UPDATE
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
	
  UPDATE Mo_ChequeOrder SET
    ChequeOrderDate = dbo.fn_Mo_DateNoTime( i.ChequeOrderDate)
  FROM Mo_ChequeOrder M, inserted i
  WHERE M.ChequeOrderID = i.ChequeOrderID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des liasses de chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeOrder';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la liasse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeOrder', @level2type = N'COLUMN', @level2name = N'ChequeOrderID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Description de la liasse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeOrder', @level2type = N'COLUMN', @level2name = N'ChequeOrderDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de la liasse.  Après que cette date est dépassé par la date de blocage la liasse n''apparâit plus lors de la commande des chèques.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ChequeOrder', @level2type = N'COLUMN', @level2name = N'ChequeOrderDate';

