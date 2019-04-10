CREATE TABLE [dbo].[Un_RepBossHist] (
    [RepBossHistID] [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepID]         [dbo].[MoID]         NOT NULL,
    [BossID]        [dbo].[MoID]         NOT NULL,
    [RepRoleID]     [dbo].[MoOptionCode] NOT NULL,
    [RepBossPct]    [dbo].[MoPctPos]     NOT NULL,
    [StartDate]     [dbo].[MoGetDate]    NOT NULL,
    [EndDate]       [dbo].[MoDateoption] NULL,
    CONSTRAINT [PK_Un_RepBossHist] PRIMARY KEY CLUSTERED ([RepBossHistID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepBossHist_Un_Rep__BossID] FOREIGN KEY ([BossID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepBossHist_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepBossHist_Un_RepRole__RepRoleID] FOREIGN KEY ([RepRoleID]) REFERENCES [dbo].[Un_RepRole] ([RepRoleID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBossHist_BossID]
    ON [dbo].[Un_RepBossHist]([BossID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBossHist_RepID]
    ON [dbo].[Un_RepBossHist]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBossHist_RepRoleID]
    ON [dbo].[Un_RepBossHist]([RepRoleID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepBossHist_RepID_RepRoleID_StartDate_EndDate]
    ON [dbo].[Un_RepBossHist]([RepID] ASC, [RepRoleID] ASC, [StartDate] ASC, [EndDate] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_RepBossHist] ON [dbo].[Un_RepBossHist] FOR INSERT, UPDATE 
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

  UPDATE Un_RepBossHist SET
    StartDate = dbo.fn_Mo_DateNoTime(i.StartDate),
    EndDate = dbo.fn_Mo_DateNoTime(i.EndDate)
  FROM Un_RepBossHist U, inserted i
  WHERE U.RepBossHistID = i.RepBossHistID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des historiques des supérieures du représentant.  Pour chaque représentant, on y retrouve la liste des directeurs et des directeurs des ventes qu''il a eu et qu''il a actuellement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''entrée de l''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'RepBossHistID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) à qui appartient l''entrée d''historique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant supérieure (Un_Rep.RepID).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'BossID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de trois caractères unique du rôle (Un_RepRole) identifiant le rôle qu''occupe ou occupait ce supérieure pour ce représentant (Ex: Directeur, directeur des ventes, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'RepRoleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Pourcentage des commissions de ce rôle que touchait ce supérieure.  Il arrive que de représentant ce partage la direction d''une représentant, un avec 67% des commissions l''autre 33% des commissions.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'RepBossPct';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de ce supérieure pour ce représentant.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de ce supérieure pour ce représentant. Null = c''est qu''il n''y a pas encore de fin de délimité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBossHist', @level2type = N'COLUMN', @level2name = N'EndDate';

