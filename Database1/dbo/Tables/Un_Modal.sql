CREATE TABLE [dbo].[Un_Modal] (
    [ModalID]                 [dbo].[MoID]        IDENTITY (1, 1) NOT NULL,
    [PlanID]                  [dbo].[MoID]        NOT NULL,
    [ModalDate]               [dbo].[MoGetDate]   NOT NULL,
    [PmtByYearID]             [dbo].[MoPmtByYear] NOT NULL,
    [PmtQty]                  [dbo].[MoID]        NOT NULL,
    [BenefAgeOnBegining]      [dbo].[MoID]        NOT NULL,
    [PmtRate]                 [dbo].[MoPctPos]    NOT NULL,
    [SubscriberInsuranceRate] [dbo].[MoPctPos]    NOT NULL,
    [FeeByUnit]               [dbo].[MoMoney]     NOT NULL,
    [FeeSplitByUnit]          [dbo].[MoMoney]     NOT NULL,
    [FeeRefundable]           [dbo].[MoBitFalse]  NOT NULL,
    [BusinessBonusToPay]      [dbo].[MoBitTrue]   NOT NULL,
    [dtEndDate]               DATE                NULL,
    CONSTRAINT [PK_Un_Modal] PRIMARY KEY CLUSTERED ([ModalID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Modal_Un_Plan__PlanID] FOREIGN KEY ([PlanID]) REFERENCES [dbo].[Un_Plan] ([PlanID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Un_Modal_ModalDate_PlanID_PmtByYearID_PmtQty_BenefAgeOnBegining]
    ON [dbo].[Un_Modal]([ModalDate] ASC, [PlanID] ASC, [PmtByYearID] ASC, [PmtQty] ASC, [BenefAgeOnBegining] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Modal_PlanID]
    ON [dbo].[Un_Modal]([PlanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Modal_ModalID]
    ON [dbo].[Un_Modal]([ModalID] ASC)
    INCLUDE([PmtQty], [PmtRate]) WITH (FILLFACTOR = 90);


GO
/****************************************************************************************************
Copyrights (c) 2003 Compurangers.inc
Nom                 :	TUn_Modal_State
Description         :	Calcul les ‚tats du groupe d'unit‚s et de sa convention et les mettent … jour,  ce lors de 
								modification de modalit‚ de paiement.
Valeurs de retours  :	N/A
Note                :						2004-06-11	Bruno Lapointe		Cr‚ation Point 10.23.02
								ADX0000694	IA	2005-06-03	Bruno Lapointe		Renommer la proc‚dure 
																							TT_UN_ConventionAndUnitStateForUnit
								ADX0001095	BR	2005-12-15	Bruno Lapointe		Correction mise … jour d'‚tat suite … Deadlock.
												2010-10-01	Steve Gouin			Gestion #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER dbo.TUn_Modal_State ON dbo.Un_Modal AFTER UPDATE
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

	-- V‚rifie si il y a des modifications
	IF EXISTS(
		SELECT DISTINCT
			U.UnitID
		FROM INSERTED I
		JOIN dbo.Un_Unit U ON U.ModalID = I.ModalID
		)
	BEGIN
		DECLARE
			@iSPID INTEGER
	
		SET @iSPID = @@SPID
	
		DECLARE 
			@UnitID INTEGER,
			@UnitIDs VARCHAR(8000)
	
		-- Cr‚e une chaŒne de caractŠre avec tout les groupes d'unit‚s affect‚s
		DECLARE UnitIDs CURSOR FOR
			SELECT DISTINCT
				U.UnitID
			FROM INSERTED I
			JOIN dbo.Un_Unit U ON U.ModalID = I.ModalID
	
		OPEN UnitIDs
	
		FETCH NEXT FROM UnitIDs
		INTO
			@UnitID
	
		SET @UnitIDs = ''
	
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SET @UnitIDs = @UnitIDs + CAST(@UnitID AS VARCHAR(30)) + ','
		
			FETCH NEXT FROM UnitIDs
			INTO
				@UnitID
		END
	
		CLOSE UnitIDs
		DEALLOCATE UnitIDs
	
		-- Appelle la proc‚dure qui met … jour les ‚tats des groupes d'unit‚s et des conventions
		EXECUTE TT_UN_ConventionAndUnitStateForUnit @UnitIDs 
	END -- Fin ajout et modificiation
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO

CREATE TRIGGER [dbo].[TUn_Modal] ON [dbo].[Un_Modal] FOR INSERT, UPDATE 
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

  UPDATE Un_Modal SET
    ModalDate = dbo.fn_Mo_DateNoTime(i.ModalDate),
    FeeByUnit = ROUND(ISNULL(i.FeeByUnit, 0), 2),
    FeeSplitByUnit = ROUND(ISNULL(i.FeeSplitByUnit, 0), 2)
  FROM Un_Modal U, inserted i
  WHERE U.ModalID = i.ModalID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les modalités de paiement des groupes d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la modalité de paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'ModalID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du plan (Un_Plan) auquel appartient la modalité de paiement.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'PlanID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entrée en vigueur de la modalité.  Pour connaître les modalités disponibles pour un groupe d''unités, il faut prendre les modalités dont le plan correspond à celui de la convention, l''age du bénéficiaire à la date de vigueur correspond et dont cette date est la plus élevé mais qui ne dépasse pas la date de vigueur de ce dernier.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'ModalDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de paiement par année. Sert aussi à déterminer le mode de dépôt.  Si (1=Annuel, 2=Semi-annuel, 4=Trimestriel, 12=Mensuel, si 1 et que PmtQty = 1 alors c''est unique).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'PmtByYearID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre de paiement total à faire pour le groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'PmtQty';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Age du bénéficiaire à la date d''entrée en vigueur du groupe d''unités.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'BenefAgeOnBegining';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''épargne et de frais par dépôt pour une unité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'PmtRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant d''assurance souscripteur par dépôt pour une unité.  Le montant s''applique uniquement si le groupe d''unité a de l''assurance (Un_Unit.WantSubscriberInsurance <> 0)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'SubscriberInsuranceRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de frais à payer par unité.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'FeeByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Quand le montant de frais cotisé par unité dépasse ce montant les cotisations sont divisé 50% en épargne et 50% en frais.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'FeeSplitByUnit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean qui indique si les frais sont remboursables. (0 = Non et <>0 = Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'FeeRefundable';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Champs boolean qui indique si des bonis d''affaire doivent être versée pour la vente d''assurance souscripteur pour cette modalité. (0=Non, <> 0= Oui)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Modal', @level2type = N'COLUMN', @level2name = N'BusinessBonusToPay';

