CREATE TABLE [dbo].[Un_RepLevelHist] (
    [RepLevelHistID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepID]          [dbo].[MoID]         NOT NULL,
    [RepLevelID]     [dbo].[MoID]         NOT NULL,
    [StartDate]      [dbo].[MoGetDate]    NOT NULL,
    [EndDate]        [dbo].[MoDateoption] NULL,
    CONSTRAINT [PK_Un_RepLevelHist] PRIMARY KEY CLUSTERED ([RepLevelHistID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepLevelHist_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepLevelHist_Un_RepLevel__RepLevelID] FOREIGN KEY ([RepLevelID]) REFERENCES [dbo].[Un_RepLevel] ([RepLevelID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepLevelHist_RepID]
    ON [dbo].[Un_RepLevelHist]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepLevelHist_RepLevelID]
    ON [dbo].[Un_RepLevelHist]([RepLevelID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_ReplevelHist] ON [dbo].[Un_RepLevelHist] FOR INSERT, UPDATE 
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

  UPDATE Un_ReplevelHist SET
    StartDate = dbo.fn_Mo_DateNoTime( i.StartDate),
    EndDate = dbo.fn_Mo_DateNoTime( i.EndDate)
  FROM Un_ReplevelHist U, inserted i
  WHERE U.RepLevelHistID = i.RepLevelHistID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des historiques des niveaux des représentants.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée d''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist', @level2type = N'COLUMN', @level2name = N'RepLevelHistID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) à qui est l''entrée d''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevel).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de ce niveau pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de ce niveau pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelHist', @level2type = N'COLUMN', @level2name = N'EndDate';

