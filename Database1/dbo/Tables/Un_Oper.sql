CREATE TABLE [dbo].[Un_Oper] (
    [OperID]               [dbo].[MoID]      IDENTITY (1, 1) NOT NULL,
    [OperTypeID]           CHAR (3)          NOT NULL,
    [OperDate]             [dbo].[MoGetDate] NOT NULL,
    [ConnectID]            [dbo].[MoID]      CONSTRAINT [DF_Un_Oper_ConnectID] DEFAULT ((2)) NOT NULL,
    [dtSequence_Operation] DATETIME          CONSTRAINT [DF_Un_Oper_dtSequenceOperation] DEFAULT (getdate()) NOT NULL,
    [LoginName]            VARCHAR (50)      NULL,
    CONSTRAINT [PK_Un_Oper] PRIMARY KEY CLUSTERED ([OperID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_Oper_Un_OperType__OperTypeID] FOREIGN KEY ([OperTypeID]) REFERENCES [dbo].[Un_OperType] ([OperTypeID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_OperDate_OperTypeID_OperID]
    ON [dbo].[Un_Oper]([OperDate] ASC, [OperTypeID] ASC, [OperID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_OperID]
    ON [dbo].[Un_Oper]([OperID] ASC)
    INCLUDE([OperTypeID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_OperTypeID_OperDate_OperID]
    ON [dbo].[Un_Oper]([OperTypeID] ASC, [OperDate] ASC, [OperID] ASC)
    INCLUDE([ConnectID], [dtSequence_Operation]);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_OperDate_OperTypeID]
    ON [dbo].[Un_Oper]([OperDate] DESC, [OperTypeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_OperDate]
    ON [dbo].[Un_Oper]([OperDate] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_Oper_dtSequenceOperation]
    ON [dbo].[Un_Oper]([dtSequence_Operation] ASC) WITH (FILLFACTOR = 90);


GO
CREATE STATISTICS [stat_Un_Oper_IQEE_1]
    ON [dbo].[Un_Oper]([OperTypeID], [OperID]);


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas Inc.
Nom                 :	TUn_Oper_dtFirstDeposit
Description         :	Trigger qui calcul le champs calcul‚ dtFirstDeposit de la table Un_Unit
Note                :	ADX0001206	IA	2006-11-06	Bruno Lapointe		Cr‚ation
										2010-10-01	Steve Gouin			Gestion du #DisableTrigger
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Oper_dtFirstDeposit] ON [dbo].[Un_Oper] FOR UPDATE
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

	-- Calcul le champ dtFirstDeposit lors de l'insertion
	IF EXISTS (
		SELECT DISTINCT 
			U.UnitID
		FROM DELETED D
		JOIN Un_Cotisation Ct ON Ct.OperID = D.OperID
		JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
		JOIN INSERTED I ON I.OperID = D.OperID
		WHERE D.OperTypeID NOT IN ('BEC')
			AND D.OperDate = U.dtFirstDeposit
			AND U.dtFirstDeposit > '1998-01-30' -- On ne gŠre pas la suppression de cotisation ant‚rieure … cette date.
			AND D.OperDate <> I.OperDate -- La date d'op‚ration a chang‚.
		) 
	BEGIN
		DECLARE @tdtFirstDeposit TABLE (
			UnitID INTEGER PRIMARY KEY )

		INSERT INTO @tdtFirstDeposit
			SELECT DISTINCT 
				U.UnitID
			FROM DELETED D
			JOIN Un_Cotisation Ct ON Ct.OperID = D.OperID
			JOIN dbo.Un_Unit U ON U.UnitID = Ct.UnitID
			JOIN INSERTED I ON I.OperID = D.OperID
			WHERE D.OperTypeID NOT IN ('BEC')
				AND D.OperDate = U.dtFirstDeposit
				AND U.dtFirstDeposit > '1998-01-30' -- On ne gŠre pas la suppression de cotisation ant‚rieure … cette date.
				AND D.OperDate <> I.OperDate -- La date d'op‚ration a chang‚.

		-- Remet … null le champ dtFirstDeposit quand il s'agit de seul d‚p“t 
		UPDATE dbo.Un_Unit 
		SET dtFirstDeposit = V.dtFirstDeposit
		FROM dbo.Un_Unit U
		JOIN (
			SELECT 
				F.UnitID,
				dtFirstDeposit = dbo.fn_Mo_DateNoTime(MIN(ISNULL(I.OperDate,O.OperDate)))
			FROM @tdtFirstDeposit F
			JOIN Un_Cotisation Ct ON Ct.UnitID = F.UnitID
			JOIN Un_Oper O ON O.OperID = Ct.OperID
			LEFT JOIN INSERTED I ON I.OperID = O.OperID
			WHERE O.OperTypeID NOT IN ('BEC')
			GROUP BY F.UnitID
			) V ON V.UnitID = U.UnitID
		WHERE U.dtFirstDeposit IS NOT NULL
	END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: TUn_Oper

Historique des modifications:
		Date			Programmeur							Description									Référence
		------------	----------------------------------	-----------------------------------------	------------
		2009-09-04		Éric Deshaies						Suivre les modifications aux enregistrements
															de la table "Un_Oper".						
		2010-02-09		Jean-François Gauthier				Ajout de l'insertion dans le champ dtSequence_Operation
		2010-10-01		Steve Gouin							Gestion du #DisableTrigger
		2011-11-07		Éric Deshaies						Remplacement de l'insertion dans le champ
															"dtSequence_Operation" par une valeur par
															défaut dans le champ.
****************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_Oper] ON [dbo].[Un_Oper] FOR INSERT, UPDATE, DELETE
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
	@LastVerifDate				MoDate

  SET @LastVerifDate = (SELECT LastVerifDate + 1 FROM Un_Def);

  IF (SELECT COUNT(OperID) 
       FROM INSERTED 
       WHERE OperDate < @LastVerifDate) > 0
  OR (SELECT COUNT(OperID) 
       FROM DELETED 
       WHERE OperDate < @LastVerifDate) > 0
  BEGIN
    ROLLBACK TRANSACTION;
    RAISERROR('Vous ne pouvez pas travailler dans cette période',16,1)
  END
  ELSE
  BEGIN
    UPDATE Un_Oper
	SET OperDate = dbo.fn_Mo_DateNoTime(i.OperDate)
    FROM Un_Oper U, inserted i
    WHERE U.OperID = i.OperID
  
	---------------------------------------------------------------------
	-- Suivre les modifications aux enregistrements de la table "Un_Oper"
	---------------------------------------------------------------------
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
		SELECT I.OperID, D.OperID
		FROM Inserted I
			 LEFT JOIN Deleted D ON D.OperID = I.OperID

	SET @i = 1

	WHILE @i <= @NbOfRecord
	BEGIN
		SELECT 
			@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
			@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
		FROM @Tinserted 
		WHERE id = @i

		-- Ajouter la modification dans le suivi des modifications
		EXECUTE psGENE_AjouterSuiviModification 1, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

		SET @i = @i + 1
	END
  END

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table contenant les opérations.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du type d''opération (Un_OperType).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'OperTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'OperDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de connexion de l''usager (Mo_Connect) qui a créé l''opération.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'ConnectID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Cette date permet l’ordonnancement chronologique des opérations afin de maintenir un système transactionnel qui n''existait pas jusqu''à la création de cette date.  C''est la date/heure au moment de la création de l''opération.  La date d''opération peut changer parce qu''elle est sélectionnée par l''utilisateur.  Même principe pour la date d''effectivité des cotisations.  

Cette date permet entre autre de déterminer le solde d''un compte à un moment précis, juste avant ou après une opération.  La date de séquence des opérations ne devrait donc jamais être modifiée.  La seule exception à cette règle devrait être des opérations faites manuellement et virtuellement par le département des finances et reproduite dans la base de données ultérieurement.  Un exemple de ça serait le développement de l’IQÉÉ.   L’IQÉÉ a été sortie manuellement par des chèques faits dans Great Plains.  Il a fallut faire des opérations dans le passé.  La date de séquence des opérations peut alors être modifiée.  Il n’est cependant pas nécessaire de modifier la date d’opération.

Aussi, étant donné que les heures des opérations ne sont plus disponibles pour les opérations faites avant février 2010, l’informatique pourrait changer manuellement la date d’ordre d’opération pour réordonnancer 2 opérations ayant eu lieu dans la même journée.  Voir dossier fonctionnel du projet de l''ajout de cette date dans VSS.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'dtSequence_Operation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Login de l''utilisateur ayant effectué l''insertion.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_Oper', @level2type = N'COLUMN', @level2name = N'LoginName';

