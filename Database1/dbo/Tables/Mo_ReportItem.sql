CREATE TABLE [dbo].[Mo_ReportItem] (
    [ReportItemID]       [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [ReportFolderID]     [dbo].[MoID]         NOT NULL,
    [ReportItemName]     [dbo].[MoDesc]       NOT NULL,
    [ReportItemSize]     [dbo].[MoIDoption]   NULL,
    [ReportItemType]     [dbo].[MoID]         NOT NULL,
    [ReportItemModified] [dbo].[MoDateoption] NULL,
    [ReportItemDeleted]  [dbo].[MoDateoption] NULL,
    [ReportItemTemplate] IMAGE                NULL,
    CONSTRAINT [PK_Mo_ReportItem] PRIMARY KEY CLUSTERED ([ReportItemID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_ReportItem_ReportFolderID_ReportItemType_ReportItemName]
    ON [dbo].[Mo_ReportItem]([ReportFolderID] ASC, [ReportItemType] ASC, [ReportItemName] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_ReportItem] ON [dbo].[Mo_ReportItem] FOR INSERT, UPDATE
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
	
  UPDATE Mo_ReportItem SET
    ReportItemModified = dbo.fn_Mo_DateNoTime( i.ReportItemModified),
    ReportItemDeleted = dbo.fn_Mo_DateNoTime( i.ReportItemModified)
  FROM Mo_ReportItem M, inserted i
  WHERE M.ReportItemID = i.ReportItemID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT DELETE
    ON OBJECT::[dbo].[Mo_ReportItem] TO PUBLIC
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[Mo_ReportItem] TO PUBLIC
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_ReportItem] TO PUBLIC
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[Mo_ReportItem] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables utilisé pour le générateur de rapport.  Cette table contient les rapports créés par les usagers dans le générateur de rapport.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du rapport.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du ficher (Mo_ReportFolder) auquel appartient ce rapport.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportFolderID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom du rapport donné par l''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Grosseur du rapport.  Utilité inconnu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemSize';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Type de rapport.  (Différents types inconnus)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la dernière modification du rapport', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemModified';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de la suppression du rapport', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemDeleted';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Template du rapport programmé par l''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_ReportItem', @level2type = N'COLUMN', @level2name = N'ReportItemTemplate';

