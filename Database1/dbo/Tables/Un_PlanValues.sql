CREATE TABLE [dbo].[Un_PlanValues] (
    [PlanID]                 [dbo].[MoID]    NOT NULL,
    [ScholarshipYear]        [dbo].[MoID]    NOT NULL,
    [ScholarshipNo]          [dbo].[MoOrder] NOT NULL,
    [EligibleUnit]           [dbo].[MoMoney] NOT NULL,
    [PlanValue]              [dbo].[MoMoney] NOT NULL,
    [UnitValue]              [dbo].[MoMoney] NOT NULL,
    [Rest]                   [dbo].[MoMoney] NOT NULL,
    [ScholarshipGrantAmount] [dbo].[MoMoney] NOT NULL,
    [CollectiveGrantAmount]  [dbo].[MoMoney] NOT NULL,
    CONSTRAINT [PK_Un_PlanValues] PRIMARY KEY CLUSTERED ([PlanID] ASC, [ScholarshipYear] ASC, [ScholarshipNo] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_PlanValues_Un_Plan__PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[Un_Plan] ([PlanID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Un_PlanValues_PlanID_ScholarshipYear_ScholarshipNo]
    ON [dbo].[Un_PlanValues]([PlanID] ASC, [ScholarshipYear] ASC, [ScholarshipNo] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_PlanValues] ON [dbo].[Un_PlanValues] FOR INSERT, UPDATE 
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

  UPDATE Un_PlanValues SET
    EligibleUnit = ROUND(ISNULL(i.EligibleUnit, 0), 2),
    PlanValue = ROUND(ISNULL(i.PlanValue, 0), 2),
    UnitValue = ROUND(ISNULL(i.UnitValue, 0), 2),
    Rest = ROUND(ISNULL(i.Rest, 0), 2),
    ScholarshipGrantAmount = ROUND(ISNULL(i.ScholarshipGrantAmount, 0), 2),
    CollectiveGrantAmount = ROUND(ISNULL(i.CollectiveGrantAmount, 0), 2)
  FROM Un_PlanValues U, inserted i
  WHERE (U.PlanID = i.PlanID)
    AND (U.ScholarshipYear = i.ScholarshipYear)
    AND (U.ScholarshipNo = i.ScholarshipNo)
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
 END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Table des valeurs des bourses par plan, année de bourse et numéro de bourse (Matrice des valeurs unitaires).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan (Un_Plan).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Année de la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'ScholarshipYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de la bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'ScholarshipNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'N''est plus utilisé - Nombre d''unités illigibles aux bourses.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'EligibleUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'N''est plus utilisé - Valeur total disponible en bourse.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'PlanValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur en bourse d''une unité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'UnitValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'N''est plus utilisé - Valeur non distribué à cause des dixièmes de cents après la division du PlanValue par le EligibleUnit.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'Rest';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'N''est plus utilisé - Total des intérêts provenant des unités illigibles.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'ScholarshipGrantAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'N''est plus utilisé - Total des intérêts provenant des résiliations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanValues', @level2type = N'COLUMN', @level2name = N'CollectiveGrantAmount';

