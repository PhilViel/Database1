CREATE TABLE [dbo].[Un_ExternalTransfert] (
    [CotisationID]               [dbo].[MoID]         NOT NULL,
    [ExternalPlanID]             [dbo].[MoID]         NOT NULL,
    [ExternalContractID]         [dbo].[MoDescoption] NULL,
    [ExternalContractDate]       [dbo].[MoDateoption] NULL,
    [FullTransfert]              [dbo].[MoBitTrue]    NOT NULL,
    [UnassistedCapitalAmount]    [dbo].[MoMoney]      NOT NULL,
    [AssistedCapitalAmount]      [dbo].[MoMoney]      NOT NULL,
    [GovernmentGrantOldAmount]   [dbo].[MoMoney]      NOT NULL,
    [TotalAssetAmountTransfered] [dbo].[MoMoney]      NOT NULL,
    CONSTRAINT [PK_Un_ExternalTransfert] PRIMARY KEY CLUSTERED ([CotisationID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ExternalTransfert_Un_Cotisation__CotisationID] FOREIGN KEY ([CotisationID]) REFERENCES [dbo].[Un_Cotisation] ([CotisationID]),
    CONSTRAINT [FK_Un_ExternalTransfert_Un_ExternalPlan__ExternalPlanID] FOREIGN KEY ([ExternalPlanID]) REFERENCES [dbo].[Un_ExternalPlan] ([ExternalPlanID])
);


GO

CREATE TRIGGER [dbo].[TUn_ExternalTransfert] ON [dbo].[Un_ExternalTransfert] FOR INSERT, UPDATE 
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

  UPDATE Un_ExternalTransfert SET
    ExternalContractDate = dbo.fn_Mo_DateNoTime(i.ExternalContractDate),
    UnassistedCapitalAmount = ROUND(ISNULL(i.UnassistedCapitalAmount, 0), 2),
    AssistedCapitalAmount = ROUND(ISNULL(i.AssistedCapitalAmount, 0), 2),
    GovernmentGrantOldAmount = ROUND(ISNULL(i.GovernmentGrantOldAmount, 0), 2),
    TotalAssetAmountTransfered = ROUND(ISNULL(i.TotalAssetAmountTransfered, 0), 2)
  FROM Un_ExternalTransfert U, inserted i
  WHERE U.CotisationID = i.CotisationID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les informations spécifiques aux transferts externes (IN et OUT).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du l''enregistrement de cotisation (Un_Cotisation) correspondant au transfert IN ou OUT.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'CotisationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan externe (Un_ExternalPlan).  Si c''est un transfert IN, alors c''est le plan de la convention d''ou provient les fonds.  Si c''est un transfert OUT, c''est le plan de la convention qui va reçevoir les fonds.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'ExternalPlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro du contrat externe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'ExternalContractID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur du contrat externe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'ExternalContractDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean disant si la totalité des fonds du contrat de provenance sont transférés.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'FullTransfert';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de capital transféré qui n''est pas subventionné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'UnassistedCapitalAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de capital transféré qui est subventionné.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'AssistedCapitalAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Ancien montant de subventions.  C''est le montant données par la SCÉÉ qui ne comprend pas les pertes dues aux mauvais investissements.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'GovernmentGrantOldAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant total transféré.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ExternalTransfert', @level2type = N'COLUMN', @level2name = N'TotalAssetAmountTransfered';

