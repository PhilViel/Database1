CREATE TABLE [dbo].[Un_CESP] (
    [iCESPID]            INT         IDENTITY (1, 1) NOT NULL,
    [ConventionID]       INT         NOT NULL,
    [OperID]             INT         NOT NULL,
    [CotisationID]       INT         NULL,
    [OperSourceID]       INT         NULL,
    [fCESG]              MONEY       NOT NULL,
    [fACESG]             MONEY       NOT NULL,
    [fCLB]               MONEY       NOT NULL,
    [fCLBFee]            MONEY       NOT NULL,
    [fPG]                MONEY       NOT NULL,
    [vcPGProv]           VARCHAR (2) NULL,
    [fCotisationGranted] MONEY       NOT NULL,
    CONSTRAINT [PK_Un_CESP] PRIMARY KEY CLUSTERED ([iCESPID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_CESP_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID]),
    CONSTRAINT [FK_Un_CESP_Un_Cotisation__CotisationID] FOREIGN KEY ([CotisationID]) REFERENCES [dbo].[Un_Cotisation] ([CotisationID]),
    CONSTRAINT [FK_Un_CESP_Un_Oper__OperID] FOREIGN KEY ([OperID]) REFERENCES [dbo].[Un_Oper] ([OperID]),
    CONSTRAINT [FK_Un_CESP_Un_Oper__OperSourceID] FOREIGN KEY ([OperSourceID]) REFERENCES [dbo].[Un_Oper] ([OperID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP_ConventionID_fCESG_fACESG_fCLB_fPG]
    ON [dbo].[Un_CESP]([ConventionID] ASC, [fCESG] ASC, [fACESG] ASC, [fCLB] ASC, [fPG] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP_CotisationID]
    ON [dbo].[Un_CESP]([CotisationID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP_OperSourceID]
    ON [dbo].[Un_CESP]([OperSourceID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Un_CESP_OperID_ConventionID_iCESPID]
    ON [dbo].[Un_CESP]([OperID] ASC, [ConventionID] ASC, [iCESPID] ASC);


GO
/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc.
Nom                 :	TUn_CESP
Description         :	Trigger empêchant de modifier les données antérieure ou en date de la date de blocage
Valeurs de retours  :	N/A
Note                :	ADX0002426	BR		2007-05-24	Bruno Lapointe		Création
											2009-09-04	Éric Deshaies		Suivre les modifications aux enregistrements
																			de la table "Un_CESP".
											2010-10-01	Steve Gouin			Gestion #DisableTrigger
																			
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TUn_CESP] ON [dbo].[Un_CESP] FOR INSERT, UPDATE, DELETE 
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
		@LastVerifDate DATETIME

	SELECT @LastVerifDate = LastVerifDate + 1 
	FROM Un_Def

	IF EXISTS ( -- Ajout
			SELECT I.iCESPID
			FROM INSERTED I
			JOIN Un_Oper O ON I.OperID = O.OperID
			LEFT JOIN DELETED D ON D.OperID = O.OperID
			WHERE O.OperDate < @LastVerifDate
				AND D.iCESPID IS NULL
			)
   OR EXISTS ( -- Suppression et modification
			SELECT D.iCESPID
			FROM DELETED D
			JOIN Un_Oper O ON D.OperID = O.OperID
			WHERE O.OperDate < @LastVerifDate
			)
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('Vous ne pouvez pas travailler dans cette période',16,1)
	END
	ELSE IF EXISTS(
			SELECT iCESPID
			FROM INSERTED 
			WHERE OperSourceID IS NULL
			)		
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('Vous ne pouvez pas insérer un valeur null comme OperSourceID',16,1)
	END
	ELSE
	BEGIN 
		UPDATE Un_CESP
		SET
			fCESG = ROUND(i.fCESG, 2),
			fACESG = ROUND(i.fACESG, 2),
			fCLB = ROUND(i.fCLB, 2),
			fCLBFee = ROUND(i.fCLBFee, 2),
			fPG = ROUND(i.fPG, 2),
			fCotisationGranted = ROUND(i.fCotisationGranted, 2)
		FROM Un_CESP CE
		JOIN Inserted i ON CE.iCESPID = i.iCESPID

		---------------------------------------------------------------------
		-- Suivre les modifications aux enregistrements de la table "Un_CESP"
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
			SELECT I.iCESPID, D.iCESPID
			FROM Inserted I
				 LEFT JOIN Deleted D ON D.iCESPID = I.iCESPID

		SET @i = 1

		WHILE @i <= @NbOfRecord
		BEGIN
			SELECT 
				@iID_Nouveau_Enregistrement = ID_Nouveau_Enregistrement, 
				@iID_Ancien_Enregistrement = ID_Ancien_Enregistrement 
			FROM @Tinserted 
			WHERE id = @i

			-- Ajouter la modification dans le suivi des modifications
			EXECUTE psGENE_AjouterSuiviModification 6, @iID_Nouveau_Enregistrement, @iID_Ancien_Enregistrement

			SET @i = @i + 1
		END

	END
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des entrées et sorties d''argent du PCEE (SCEE, SCEE+ et BEC). Il s''agit d''une réflétant la réalité comptable du PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique d''un enregistrement de montant PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'iCESPID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique dde la convention affecté par ces varaitions de PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération comptable qui a inscrit des entrées ou sorties d''argent du PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'OperID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique d''une cotisation (Un_Cotisation)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'CotisationID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''opération qui a fait le mouvement de cotisation qui a provoqué des entrées ou sorties d''argent du PCEE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'OperSourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'SCEE reçue (+), versée (-) ou remboursée (-)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fCESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'SCEE+ reçue (+), versée (-) ou remboursée (-)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fACESG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'BEC reçu (+), versé (-) ou remboursé (-)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fCLB';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Frais reçu pour la gestion du BEC', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fCLBFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Subvention provinciale reçue (+), versée (-) ou remboursée (-)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fPG';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Province d''où provient la subvention provinciale', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'vcPGProv';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Montant de cotisation subventionné', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_CESP', @level2type = N'COLUMN', @level2name = N'fCotisationGranted';

