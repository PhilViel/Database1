CREATE TABLE [dbo].[Un_RepCharge] (
    [RepChargeID]     [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepID]           [dbo].[MoID]         NOT NULL,
    [RepChargeTypeID] [dbo].[MoOptionCode] NOT NULL,
    [RepChargeDesc]   [dbo].[MoLongDesc]   NOT NULL,
    [RepChargeAmount] [dbo].[MoMoney]      NOT NULL,
    [RepTreatmentID]  [dbo].[MoIDoption]   NULL,
    [RepChargeDate]   [dbo].[MoGetDate]    NOT NULL,
    CONSTRAINT [PK_Un_RepCharge] PRIMARY KEY CLUSTERED ([RepChargeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepCharge_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepCharge_Un_RepChargeType__RepChargeTypeID] FOREIGN KEY ([RepChargeTypeID]) REFERENCES [dbo].[Un_RepChargeType] ([RepChargeTypeID]),
    CONSTRAINT [FK_Un_RepCharge_Un_RepTreatment__RepTreatmentID] FOREIGN KEY ([RepTreatmentID]) REFERENCES [dbo].[Un_RepTreatment] ([RepTreatmentID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCharge_RepID]
    ON [dbo].[Un_RepCharge]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCharge_RepChargeTypeID]
    ON [dbo].[Un_RepCharge]([RepChargeTypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCharge_RepTreatmentID]
    ON [dbo].[Un_RepCharge]([RepTreatmentID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCharge_RepTreatmentID_RepChargeID_RepID_RepChargeDate_RepChargeTypeID]
    ON [dbo].[Un_RepCharge]([RepTreatmentID] ASC, [RepChargeID] ASC, [RepID] ASC, [RepChargeDate] ASC, [RepChargeTypeID] ASC)
    INCLUDE([RepChargeAmount]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepCharge_RepChargeTypeID_RepID_RepChargeDate_RepTreatmentID_RepChargeID]
    ON [dbo].[Un_RepCharge]([RepChargeTypeID] ASC, [RepID] ASC, [RepChargeDate] ASC, [RepTreatmentID] ASC, [RepChargeID] ASC)
    INCLUDE([RepChargeAmount]) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [_dta_stat_1405352171_2_6_7]
    ON [dbo].[Un_RepCharge]([RepID], [RepTreatmentID], [RepChargeDate]);


GO
CREATE STATISTICS [_dta_stat_1405352171_7_3_6]
    ON [dbo].[Un_RepCharge]([RepChargeDate], [RepChargeTypeID], [RepTreatmentID]);


GO
CREATE STATISTICS [_dta_stat_1405352171_2_1_7_3]
    ON [dbo].[Un_RepCharge]([RepID], [RepChargeID], [RepChargeDate], [RepChargeTypeID]);


GO
CREATE STATISTICS [_dta_stat_1405352171_2_7_3_6_1]
    ON [dbo].[Un_RepCharge]([RepID], [RepChargeDate], [RepChargeTypeID], [RepTreatmentID], [RepChargeID]);


GO

CREATE TRIGGER [dbo].[TUn_RepCharge] ON [dbo].[Un_RepCharge] FOR INSERT, UPDATE 
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

  UPDATE Un_RepCharge SET
    RepChargeAmount = ROUND(ISNULL(i.RepChargeAmount, 0), 2)
  FROM Un_RepCharge U, inserted i
  WHERE U.RepChargeID = i.RepChargeID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des ajustements et retenus des représentants.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''ajustement ou retenu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepChargeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant à qui appartient l''ajustement ou la retenu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères identifiant de quel type d''ajustement ou de retenu (Un_RepChargeType) il s''agit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepChargeTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Notes écrites par l''usager qui l''a créé.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepChargeDesc';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''ajustement ou la retenu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepChargeAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du traitement de commissions dans lequel l''ajustement ou la retenu a été traité. Null = pas encore traité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepTreatmentID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date à laquel l''ajustement ou la retenu a eu lieu.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepCharge', @level2type = N'COLUMN', @level2name = N'RepChargeDate';

