CREATE TABLE [dbo].[Un_BenefInsur] (
    [BenefInsurID]        [dbo].[MoID]        IDENTITY (1, 1) NOT NULL,
    [BenefInsurDate]      [dbo].[MoGetDate]   NOT NULL,
    [BenefInsurFaceValue] [dbo].[MoMoney]     NOT NULL,
    [BenefInsurPmtByYear] [dbo].[MoPmtByYear] NOT NULL,
    [BenefInsurRate]      [dbo].[MoMoney]     NOT NULL,
    CONSTRAINT [PK_Un_BenefInsur] PRIMARY KEY CLUSTERED ([BenefInsurID] ASC) WITH (FILLFACTOR = 90)
);


GO

CREATE TRIGGER [dbo].[TUn_BenefInsur] ON [dbo].[Un_BenefInsur] FOR INSERT, UPDATE 
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
	
  UPDATE Un_BenefInsur SET
    BenefInsurDate = dbo.fn_Mo_DateNoTime( i.BenefInsurDate),
    BenefInsurFaceValue = ROUND(ISNULL(i.BenefInsurFaceValue, 0), 2),
    BenefInsurRate = ROUND(ISNULL(i.BenefInsurRate, 0), 2)
  FROM Un_BenefInsur U, inserted i
  WHERE U.BenefInsurID = i.BenefInsurID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des modalités de paiement d''assurance bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la modalité de paiement d''assurance bénéficiaire.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur', @level2type = N'COLUMN', @level2name = N'BenefInsurID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entré en vigueur de la modalité.  Elle est en vigueur jusqu''à ce qu''une configuration avec une date plus récente mais qui n''est pas dans le futur la remplace.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur', @level2type = N'COLUMN', @level2name = N'BenefInsurDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''indemnité de l''assurance.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur', @level2type = N'COLUMN', @level2name = N'BenefInsurFaceValue';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de dépôts par année.  Il doit correspondre avec le nombre de dépôt par année de la modalité de paiement du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur', @level2type = N'COLUMN', @level2name = N'BenefInsurPmtByYear';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de la prime d''assurance par dépôt.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_BenefInsur', @level2type = N'COLUMN', @level2name = N'BenefInsurRate';

