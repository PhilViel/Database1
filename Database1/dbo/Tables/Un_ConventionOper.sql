CREATE TABLE [dbo].[Un_ConventionOper] (
    [ConventionOperID]     [dbo].[MoID]         IDENTITY (1, 1) NOT NULL,
    [OperID]               [dbo].[MoID]         NOT NULL,
    [ConventionID]         [dbo].[MoID]         NOT NULL,
    [ConventionOperTypeID] [dbo].[MoOptionCode] NOT NULL,
    [ConventionOperAmount] [dbo].[MoMoney]      NOT NULL,
    CONSTRAINT [PK_Un_ConventionOper] PRIMARY KEY CLUSTERED ([ConventionOperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ConventionOper_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_ConventionOper_Un_ConventionOperType__ConventionOperTypeID] FOREIGN KEY ([ConventionOperTypeID]) REFERENCES [dbo].[Un_ConventionOperType] ([ConventionOperTypeID]),
    CONSTRAINT [FK_Un_ConventionOper_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionOper_ConventionID]
    ON [dbo].[Un_ConventionOper]([ConventionID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionOper_ConventionID_ConventionOperTypeID]
    ON [dbo].[Un_ConventionOper]([ConventionID] ASC, [ConventionOperTypeID] ASC, [ConventionOperID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionOper_ConventionOperTypeID_ConventionID_OperID_ConventionOperAmount]
    ON [dbo].[Un_ConventionOper]([ConventionOperTypeID] ASC, [ConventionID] ASC, [OperID] ASC, [ConventionOperAmount] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionOper_ConventionOperTypeID_OperID_ConventionID_ConventionOperAmount]
    ON [dbo].[Un_ConventionOper]([ConventionOperTypeID] ASC, [OperID] ASC, [ConventionID] ASC, [ConventionOperAmount] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionOper_OperID_ConventionID_TypeID]
    ON [dbo].[Un_ConventionOper]([OperID] ASC, [ConventionID] ASC, [ConventionOperTypeID] ASC);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TUn_ConventionOper

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Suivre les modifications aux enregistrements
															de la table "Un_ConventionOper".						
		2010-10-04		Steve Gouin							Gestion des disable trigger par #DisableTrigger

****************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_ConventionOper] ON [dbo].[Un_ConventionOper] FOR INSERT, UPDATE, DELETE 
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

  IF  (SELECT COUNT(ConventionOperID) 
       FROM INSERTED I
       JOIN Un_Oper O ON (I.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate) > 0
   OR (SELECT COUNT(ConventionOperID) 
       FROM DELETED D
       JOIN Un_Oper O ON (D.OperID = O.OperID)
       WHERE O.OperDate < @LastVerifDate) > 0
  BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Vous ne pouvez pas travailler dans cette période',16,1)
  END
  ELSE
  BEGIN
    UPDATE Un_ConventionOper SET
      ConventionOperAmount = ROUND(ISNULL(i.ConventionOperAmount, 0), 2)
    FROM Un_ConventionOper U, inserted i
    WHERE U.ConventionOperID = i.ConventionOperID

	-------------------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_ConventionOper"
	-------------------------------------------------------------------------------
	DECLARE @iID_Nouveau_Enregistrement INT,
			@iID_Ancien_Enregistrement INT,
			@NbOfRecord int,
			@i int

	DECLARE @Tinserted TABLE (
		Id INT IDENTITY (1,1),  
		ID_Nouveau_Enregistrement INT, 
		ID_Ancien_Enregistrement INT)

	SELECT @NbOfRecord = COUNT(*) FROM inserted

	INSERT INTO @Tinserted (ID_Nouveau_Enregistrement,ID_Ancien_Enregistrement)
		SELECT I.ConventionOperID, D.ConventionOperID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.ConventionOperID = I.ConventionOperID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 3, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END

  END;
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des opérations sur conventions. Des opérations sur conventions sont les transactions financières qu''on retrouve dans l''historique des opérations sur convention.  Ce sont les transactions financières propre à la convention (Ex: Frais disponible, intérêt chargé au client, intérêt sur capital, intérêt sur subvention, etc.).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération sur convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper', @level2type = N'COLUMN', @level2name = N'ConventionOperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération financières (Un_Oper) à laquel elle appartient.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention à laquel elle appartient.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de 3 caractères alphanumérique unique identifiant le type d''opération sur convention (Un_ConventionOperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper', @level2type = N'COLUMN', @level2name = N'ConventionOperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de l''opération sur convention.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionOper', @level2type = N'COLUMN', @level2name = N'ConventionOperAmount';

