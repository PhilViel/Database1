CREATE TABLE [dbo].[Un_RepLevelBracket] (
    [RepLevelBracketID]     [dbo].[MoID]                  IDENTITY (1, 1) NOT NULL,
    [RepLevelID]            [dbo].[MoID]                  NOT NULL,
    [TargetFeeByUnit]       [dbo].[MoMoney]               NOT NULL,
    [AdvanceByUnit]         [dbo].[MoMoney]               NOT NULL,
    [EffectDate]            [dbo].[MoGetDate]             NOT NULL,
    [TerminationDate]       [dbo].[MoDateoption]          NULL,
    [RepLevelBracketTypeID] [dbo].[UnRepLevelBracketType] NOT NULL,
    [PlanID]                [dbo].[MoID]                  NULL,
    CONSTRAINT [PK_Un_RepLevelBracket] PRIMARY KEY CLUSTERED ([RepLevelBracketID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepLevelBracket_Un_RepLevel__RepLevelID] FOREIGN KEY ([RepLevelID]) REFERENCES [dbo].[Un_RepLevel] ([RepLevelID])
);


GO

CREATE TRIGGER [dbo].[TUn_RepLevelBracket] ON [dbo].[Un_RepLevelBracket] FOR INSERT, UPDATE 
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

  UPDATE Un_RepLevelBracket SET
    TargetFeeByUnit = ROUND(ISNULL(i.TargetFeeByUnit, 0), 2),
    AdvanceByUnit = ROUND(ISNULL(i.AdvanceByUnit, 0), 2),
    EffectDate = dbo.fn_Mo_DateNoTime( i.EffectDate),
    TerminationDate = dbo.fn_Mo_DateNoTime( i.TerminationDate)
  FROM Un_RepLevelBracket U, inserted i
  WHERE U.RepLevelBracketID = i.RepLevelBracketID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des tombés de commissions(Avances, avances couvertes et Commissions de service).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'RepLevelBracketID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevel) auquel s''applique cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de frais par unités à atteindre pour être illigible a cette tombée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'TargetFeeByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Valeur par unités de la tombée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'AdvanceByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'EffectDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'TerminationDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de 3 caractères identifiant de qu''elle type de tombé il s''agit (''COM''=Commission de service, ''ADV''=Avances, ''CAD''=Avances couvertes).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'RepLevelBracketTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Plan pour lequel s''applique la tombée de commissions', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepLevelBracket', @level2type = N'COLUMN', @level2name = N'PlanID';

