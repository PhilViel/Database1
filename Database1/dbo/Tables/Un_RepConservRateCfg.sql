CREATE TABLE [dbo].[Un_RepConservRateCfg] (
    [RepConservRateCfgID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [MinConservRate]      [dbo].[MoPctPos]     NOT NULL,
    [MaxConservRate]      [dbo].[MoPctPos]     NOT NULL,
    [RateOnBonus]         [dbo].[MoPctPos]     NOT NULL,
    [StartDate]           [dbo].[MoGetDate]    NOT NULL,
    [EndDate]             [dbo].[MoDateoption] NULL,
    [RepRoleID]           [dbo].[MoOptionCode] NOT NULL,
    CONSTRAINT [PK_Un_RepConservRateCfg] PRIMARY KEY CLUSTERED ([RepConservRateCfgID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepConservRateCfg_Un_RepRole__RepRoleID] FOREIGN KEY ([RepRoleID]) REFERENCES [dbo].[Un_RepRole] ([RepRoleID])
);


GO

CREATE TRIGGER [dbo].[TUn_RepConservRateCfg] ON [dbo].[Un_RepConservRateCfg] FOR INSERT, UPDATE 
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

  UPDATE Un_RepConservRateCfg SET
    StartDate = dbo.fn_Mo_DateNoTime( i.StartDate),
    EndDate = dbo.fn_Mo_DateNoTime( i.EndDate)
  FROM Un_RepConservRateCfg U, inserted i
  WHERE U.RepConservRateCfgID = i.RepConservRateCfgID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des bonis de conservations (Boni annuel).  Cette table s''occuppe de la configuration des pourcentages de conservation.  Ces bonis sont calculés selon le nombre de vente et le pourcentage de conservation.  La parti nombre de ventes est configurer dans la table Un_RepConservBonusCfg.  Le boni annuel est calculé ainsi : Le montant de commission de l''année * le pourcentage (ConservBonusRate) correspondant de la table Un_RepConservBonusCfg * le pourcentage (RateOnBonus) correspondant de cette table.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'RepConservRateCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Minimum de l''interval en pourcentage de conservation de ce pourcentage (RateOnBonus).  Si le pourcentage de conservation du représentant pour ce rôle (RepRoleID) pour cette année est entre ce nombre et le pourcentage maximum (MaxConservRate) et que la configuration était celle active lors de la date de fin de la période couverte par le traitement des bonis annuels alors, c''est ce pourcentage qu''on doit utiliser dans la formule pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'MinConservRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Maximum de l''interval en pourcentage de conservation de cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'MaxConservRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage à utiliser dans la formule de calcul du boni annuel.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'RateOnBonus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entré en vigueur de la configuration.  Pour qu''une configuration soit utilisé lors du traitement, il faut que la date du traitement soit entre date et la date de fin de vigueur (EndDate) inclusivement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères du rôle du représentant (Un_RepRole) a qui s''applique cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepConservRateCfg', @level2type = N'COLUMN', @level2name = N'RepRoleID';

