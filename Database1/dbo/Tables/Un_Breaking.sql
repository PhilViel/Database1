CREATE TABLE [dbo].[Un_Breaking] (
    [BreakingID]                    [dbo].[MoID]           IDENTITY (1, 1) NOT NULL,
    [ConventionID]                  [dbo].[MoID]           NOT NULL,
    [BreakingTypeID]                [dbo].[UnBreakingType] NOT NULL,
    [BreakingStartDate]             [dbo].[MoGetDate]      NOT NULL,
    [BreakingEndDate]               [dbo].[MoDateoption]   NULL,
    [BreakingReason]                [dbo].[MoDescoption]   NULL,
    [iID_Utilisateur_Creation]      INT                    NULL,
    [dtDate_Creation_Operation]     DATETIME               NULL,
    [iID_Utilisateur_Modification]  INT                    NULL,
    [dtDate_Modification_Operation] DATETIME               NULL,
    CONSTRAINT [PK_Un_Breaking] PRIMARY KEY CLUSTERED ([BreakingID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Breaking_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Breaking_ConventionID]
    ON [dbo].[Un_Breaking]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Breaking_BreakingTypeID_BreakingStartDate]
    ON [dbo].[Un_Breaking]([BreakingTypeID] ASC, [BreakingStartDate] ASC)
    INCLUDE([ConventionID], [BreakingEndDate]) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_Breaking] ON [dbo].[Un_Breaking] FOR INSERT, UPDATE 
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
	
  UPDATE Un_Breaking SET
    BreakingStartDate = dbo.fn_Mo_DateNoTime(i.BreakingStartDate),
    BreakingEndDate = dbo.fn_Mo_DateNoTime(i.BreakingEndDate)
  FROM Un_Breaking U, inserted i
  WHERE U.BreakingID = i.BreakingID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des arrêts et suspensions de paiements sur convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''arrêt ou la suspension paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'BreakingID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention (Un_Convention) à laquel appartient l''arrêt ou la suspension de paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Trois lettre identifiant s''il s''agit d''une arrêt de paiement ou d''une suspension (STP = Arrêt, SUS = Suspension, RES = Résiliation, RNA = Résiliation sans NAS).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'BreakingTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de début de la période ou l''arrêt ou la suspension paiement est en vigueur. (Inclusivement)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'BreakingStartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de la période ou l''arrêt ou la suspension paiement est en vigueur. (Inclusivement)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'BreakingEndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs text permettant d''inscrire un commentaire sur la raison de l''arrêt ou la suspension de paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'BreakingReason';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utlisateur à l''origine de la création de l''arrêt de paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Creation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de création de l''arrêt de paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'dtDate_Creation_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifiant de l''utlisateur à l''origine de la modification de l''arrêt de paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'iID_Utilisateur_Modification';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Date de modification de l''arrêt de paiement', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Breaking', @level2type = N'COLUMN', @level2name = N'dtDate_Modification_Operation';

