CREATE TABLE [dbo].[Un_UnitReductionRepException] (
    [RepExceptionID]  [dbo].[MoID] NOT NULL,
    [UnitReductionID] [dbo].[MoID] NOT NULL,
    CONSTRAINT [PK_Un_UnitReductionRepException] PRIMARY KEY CLUSTERED ([RepExceptionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_UnitReductionRepException_Un_RepException__RepExceptionID] FOREIGN KEY ([RepExceptionID]) REFERENCES [dbo].[Un_RepException] ([RepExceptionID]),
    CONSTRAINT [FK_Un_UnitReductionRepException_Un_UnitReduction__UnitReductionID] FOREIGN KEY ([UnitReductionID]) REFERENCES [dbo].[Un_UnitReduction] ([UnitReductionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_UnitReductionRepException_UnitReductionID]
    ON [dbo].[Un_UnitReductionRepException]([UnitReductionID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_UnitReductionRepException] ON [dbo].[Un_UnitReductionRepException] FOR DELETE
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

  DELETE 
  FROM Un_RepException
  WHERE RepExceptionID IN (SELECT RepExceptionID 
                           FROM DELETED) 
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table qui fait le lien entre l''historique de réduction d''unités et les exceptions sur commissions qu''il a généré.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionRepException';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''exception de commission (Un_RepException).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionRepException', @level2type = N'COLUMN', @level2name = N'RepExceptionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée d''historique de réduction d''unité (Un_UnitReduction).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_UnitReductionRepException', @level2type = N'COLUMN', @level2name = N'UnitReductionID';

