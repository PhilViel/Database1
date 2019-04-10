CREATE TABLE [dbo].[Un_RepTreatment] (
    [RepTreatmentID]   [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [RepTreatmentDate] [dbo].[MoGetDate] NOT NULL,
    [MaxRepRisk]       [dbo].[MoPctPos]  NULL,
    CONSTRAINT [PK_Un_RepTreatment] PRIMARY KEY CLUSTERED ([RepTreatmentID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepTreatment_RepTreatmentDate]
    ON [dbo].[Un_RepTreatment]([RepTreatmentDate] ASC) WITH (FILLFACTOR = 90);


GO

/* -------------------------------------------------------------------------- */
/*                                                                            */
/*                             Insertion des vues                             */
/*                                                                            */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                                                            */
/*                           Insertion des Triggers                           */
/*                                                                            */
/* -------------------------------------------------------------------------- */
CREATE TRIGGER [dbo].[TUn_RepTreatment] ON [dbo].[Un_RepTreatment] FOR INSERT, UPDATE 
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

  UPDATE Un_RepTreatment SET
    RepTreatmentDate = dbo.fn_Mo_DateNoTime( i.RepTreatmentDate)
  FROM Un_RepTreatment U, inserted i
  WHERE U.RepTreatmentID = i.RepTreatmentID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des traitements de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepTreatment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage maximum de risque utilisé dans ce traitement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepTreatment', @level2type = N'COLUMN', @level2name = N'RepTreatmentDate';

