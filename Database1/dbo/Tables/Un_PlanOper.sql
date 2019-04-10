CREATE TABLE [dbo].[Un_PlanOper] (
    [PlanOperID]     [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [OperID]         [dbo].[MoID]         NOT NULL,
    [PlanID]         [dbo].[MoID]         NOT NULL,
    [PlanOperTypeID] [dbo].[MoOptionCode] NOT NULL,
    [PlanOperAmount] [dbo].[MoMoney]      NOT NULL,
    CONSTRAINT [PK_Un_PlanOper] PRIMARY KEY CLUSTERED ([PlanOperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_PlanOper_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_PlanOper_Un_Plan__PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[Un_Plan] ([PlanID]),
    CONSTRAINT [FK_Un_PlanOper_Un_PlanOperType__PlanOperTypeID] FOREIGN KEY ([PlanOperTypeID]) REFERENCES [dbo].[Un_PlanOperType] ([PlanOperTypeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_PlanOper_OperID]
    ON [dbo].[Un_PlanOper]([OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_PlanOper_PlanID]
    ON [dbo].[Un_PlanOper]([PlanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_PlanOper_PlanOperTypeID]
    ON [dbo].[Un_PlanOper]([PlanOperTypeID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_PlanOper] ON [dbo].[Un_PlanOper] FOR INSERT, UPDATE, DELETE
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

  DECLARE 
  @LastVerifDate MoDate;

  SET @LastVerifDate = (SELECT LastVerifDate + 1 FROM Un_Def);

  IF  (SELECT COUNT(PlanOperID) 
       FROM INSERTED I
       JOIN Un_Oper O ON (I.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate) > 0
   OR (SELECT COUNT(PlanOperID) 
       FROM DELETED D
       JOIN Un_Oper O ON (D.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate) > 0
  BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Vous ne pouvez pas travailler dans cette période',16,1)
  END
  ELSE
  BEGIN
    UPDATE Un_PlanOper SET
      PlanOperAmount = ROUND(ISNULL(i.PlanOperAmount, 0), 2)
    FROM Un_PlanOper U, inserted i
    WHERE U.PlanOperID = i.PlanOperID
  END;
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des opérations sur plans.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération sur plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper', @level2type = N'COLUMN', @level2name = N'PlanOperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération (Un_Oper) dont fait parti l''opération sur plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan (Un_Plan).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine unique de 3 caractàres du type d''opération sur plan (Un_PlanOperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper', @level2type = N'COLUMN', @level2name = N'PlanOperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''opération sur plan.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_PlanOper', @level2type = N'COLUMN', @level2name = N'PlanOperAmount';

