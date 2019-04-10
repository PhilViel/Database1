CREATE TABLE [dbo].[Un_RepBusinessBonusCfg] (
    [RepBusinessBonusCfgID]   [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [BusinessBonusByUnit]     [dbo].[MoMoney]      NOT NULL,
    [StartDate]               [dbo].[MoGetDate]    NOT NULL,
    [EndDate]                 [dbo].[MoDateoption] NULL,
    [BusinessBonusNbrOfYears] [dbo].[MoID]         NULL,
    [RepRoleID]               [dbo].[MoOptionCode] NOT NULL,
    [InsurTypeID]             [dbo].[UnInsurType]  NOT NULL,
    CONSTRAINT [PK_Un_RepBusinessBonusCfg] PRIMARY KEY CLUSTERED ([RepBusinessBonusCfgID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_RepBusinessBonusCfg_Un_RepRole__RepRoleID] FOREIGN KEY ([RepRoleID]) REFERENCES [dbo].[Un_RepRole] ([RepRoleID])
);


GO

CREATE TRIGGER [dbo].[TUn_RepBusinessBonusCfg] ON [dbo].[Un_RepBusinessBonusCfg] FOR INSERT, UPDATE 
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

  UPDATE Un_RepBusinessBonusCfg SET
    BusinessBonusByUnit = ROUND(ISNULL(i.BusinessBonusByUnit, 0), 2),
    StartDate = dbo.fn_Mo_DateNoTime( i.StartDate),
    EndDate = dbo.fn_Mo_DateNoTime( i.EndDate)
  FROM Un_RepBusinessBonusCfg U, inserted i
  WHERE U.RepBusinessBonusCfgID = i.RepBusinessBonusCfgID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table de configuration des bonis d''affaires.  Permet de déterminer les montants de bonis d''affaire que doivent toucher les représentants et leurs supérieures par unité selon le type d''assurance, et le rôle du représentant.  Les bonis d''affaires sont donnés à chaque fois que l''équivalent d''une année de cotisation a été encaissé jusqu''à concurrence du nombre total d''année bonifié (BusinessBonusNbrYears).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'RepBusinessBonusCfgID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de boni par unité, par année de bonis.  Le maximum de bonis pour un unité vendu qui n''est pas résilié correspond à ce montant * par le champs BusinessBonusNbrOfYears.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'BusinessBonusByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'StartDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin de vigueur de cette configuration.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'EndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de bonis touchés pour une ventes. (1 boni par année)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'BusinessBonusNbrOfYears';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de trois caractères unique du rôle (Un_RepRole) sur lequel la configuration s''applique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'RepRoleID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaine de trois caractères identifiant pour quel type d''assurance vendu cette configuration s''applique (''ISB''=Assurance souscripteur, ''IB5''=Assurance bénéficiaire avec indemnité 5 000$, ''IB1''=Assurance bénéficiaire avec indemnité 10 000$, ''IB2''=Assurance bénéficiaire avec indemnité 20 000$).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_RepBusinessBonusCfg', @level2type = N'COLUMN', @level2name = N'InsurTypeID';

