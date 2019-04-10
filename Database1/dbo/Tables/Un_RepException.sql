CREATE TABLE [dbo].[Un_RepException] (
    [RepExceptionID]     [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [RepID]              [dbo].[MoID]         NOT NULL,
    [UnitID]             [dbo].[MoID]         NOT NULL,
    [RepLevelID]         [dbo].[MoID]         NOT NULL,
    [RepExceptionTypeID] [dbo].[MoOptionCode] NOT NULL,
    [RepExceptionDate]   [dbo].[MoGetDate]    NOT NULL,
    [RepExceptionAmount] [dbo].[MoMoney]      NOT NULL,
    CONSTRAINT [PK_Un_RepException] PRIMARY KEY CLUSTERED ([RepExceptionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepException_Un_Rep__RepID] FOREIGN KEY ([RepID]) REFERENCES [dbo].[Un_Rep] ([RepID]),
    CONSTRAINT [FK_Un_RepException_Un_RepExceptionType__RepExceptionTypeID] FOREIGN KEY ([RepExceptionTypeID]) REFERENCES [dbo].[Un_RepExceptionType] ([RepExceptionTypeID]),
    CONSTRAINT [FK_Un_RepException_Un_RepLevel__RepLevelID] FOREIGN KEY ([RepLevelID]) REFERENCES [dbo].[Un_RepLevel] ([RepLevelID]),
    CONSTRAINT [FK_Un_RepException_Un_Unit__UnitID] FOREIGN KEY ([UnitID]) REFERENCES [dbo].[Un_Unit] ([UnitID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepException_RepID]
    ON [dbo].[Un_RepException]([RepID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepException_UnitID]
    ON [dbo].[Un_RepException]([UnitID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepException_RepLevelID]
    ON [dbo].[Un_RepException]([RepLevelID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_RepException_RepExceptionTypeID]
    ON [dbo].[Un_RepException]([RepExceptionTypeID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TUn_RepException] ON [dbo].[Un_RepException] FOR INSERT, UPDATE
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

  UPDATE Un_RepException SET
    RepExceptionDate = dbo.fn_Mo_DateNoTime(i.RepExceptionDate)
  FROM Un_RepException U, inserted i
  WHERE U.RepExceptionID = i.RepExceptionID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des exceptions sur commissions.  Les exceptions permettres d''ajuster le montant de commissions (Avances, avances couvertes et commissions de service) à recevoir.  Des exceptions sont créées automatiquement, par exemple, lors de résiliation pour que les représentants conservent le montant dont ils avaient droit sur les unités résiliés.  Lors de transfert de frais des exceptions sont créées automatiquement pour que les représentants ne touchent pas de commissions sur les frais transférés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepExceptionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du représentant (Un_Rep) affecté par l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du groupe d''unités (Un_Unit) sur lequel l''exception a été créée.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'UnitID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du niveau (Un_RepLevel) du représentant lors de la vente du groupe d''unités.  Sert aussi à connaître le rôle affecté par l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepLevelID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne unique de 3 caractères (Un_RepExceptionType) donnant le type de l''exception.  Permet aussi de connaître si l''exception affecte les avances ou les avances couvertes ou les commissions de service.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepExceptionTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepExceptionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''exception.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepException', @level2type = N'COLUMN', @level2name = N'RepExceptionAmount';

