CREATE TABLE [dbo].[Un_ConventionAccount] (
    [ConventionID] [dbo].[MoID]   NOT NULL,
    [BankID]       [dbo].[MoID]   NOT NULL,
    [TransitNo]    [dbo].[MoDesc] NOT NULL,
    [AccountName]  [dbo].[MoDesc] NOT NULL,
    CONSTRAINT [PK_Un_ConventionAccount] PRIMARY KEY CLUSTERED ([ConventionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Un_ConventionAccount_Mo_Bank__BankID] FOREIGN KEY ([BankID]) REFERENCES [dbo].[Mo_Bank] ([BankID]),
    CONSTRAINT [FK_Un_ConventionAccount_Un_Convention__ConventionID] FOREIGN KEY ([ConventionID]) REFERENCES [dbo].[Un_Convention] ([ConventionID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Un_ConventionAccount_BankID]
    ON [dbo].[Un_ConventionAccount]([BankID] ASC) WITH (FILLFACTOR = 90);


GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: Un_ConventionAccount
But					: Journaliser les infos bancaires dans CRQ_Log lors d'un changement sur le record							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-08-04			Steve Picard			Création du service			
		2016-04-11			Donald Huppé			Inscrit le nom du compte (AccountName) en majuscule et sans accent
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_Un_ConventionAccount_Upd] ON [dbo].[Un_ConventionAccount] AFTER UPDATE
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Today date = GetDate()

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	
	--	Bloque le trigger des DELETEs
	INSERT INTO #DisableTrigger VALUES(OBJECT_NAME(@@PROCID))	

	UPDATE Un_ConventionAccount SET AccountName = UPPER(dbo.fn_Mo_FormatStringWithoutAccent(i.AccountName))
	FROM Un_ConventionAccount M, inserted i
	WHERE M.ConventionID = i.ConventionID

	DECLARE @Now Datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'U')

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
		SELECT
			2, 'Un_Convention', New.ConventionID, @Now, @ActionID, 
			LogDesc = 'Compte bancaire de convention : ' + (Select ConventionNo From dbo.Un_Convention Where ConventionID = New.ConventionID), 
			LogText = 
				CASE WHEN Old.BankID = New.BankID THEN ''
					 ELSE 'BankID' + @RecSep + LTrim(Str(Old.BankID)) 
										 + @RecSep + LTrim(Str(New.BankID)) 
										 + @RecSep + ISNULL((Select T.BankTypeCode+'-'+B.BankTransit FROM dbo.Mo_Bank B JOIN dbo.Mo_BankType T ON T.BankTypeID = B.BankTypeID Where BankID = Old.BankID), '')
										 + @RecSep + ISNULL((Select T.BankTypeCode+'-'+B.BankTransit FROM dbo.Mo_Bank B JOIN dbo.Mo_BankType T ON T.BankTypeID = B.BankTypeID Where BankID = New.BankID), '')
										 + @RecSep +  @CrLf
				END +
				CASE WHEN Old.TransitNo = New.TransitNo THEN ''
					 ELSE 'TransitNo' + @RecSep + Old.TransitNo + @RecSep + New.TransitNo
									  + @RecSep +  @CrLf
				END +
				CASE WHEN Old.AccountName = New.AccountName THEN ''
					 ELSE 'AccountName' + @RecSep + Old.AccountName + @RecSep + UPPER(dbo.fn_Mo_FormatStringWithoutAccent(New.AccountName))
										+ @RecSep +  @CrLf
				END +
				''
		FROM	inserted New
				JOIN deleted Old ON Old.ConventionID = New.ConventionID
		WHERE	Old.BankID <> New.BankID
				OR Old.TransitNo <> New.TransitNo
				OR Old.AccountName <> New.AccountName

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = OBJECT_NAME(@@PROCID)

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service		: Un_ConventionAccount
But					: Journaliser les infos bancaires dans CRQ_Log lors d'un changement sur le record							

Historique des modifications:
		Date				Programmeur				Description										
		------------		-----------------------	-----------------------------------------	
		2015-08-04			Steve Picard			Création du service			
		2016-04-11			Donald Huppé			Inscrit le nom du compte (AccountName) en majuscule et sans accent
*********************************************************************************************************************/
CREATE TRIGGER [dbo].[TR_Un_ConventionAccount_Ins] ON [dbo].[Un_ConventionAccount] AFTER INSERT
AS
BEGIN
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Start'
	DECLARE @Today date = GetDate()

	-- *** AVERTISSEMENT *** Ce script doit toujours figurer en tête de trigger
	IF object_id('tempdb..#DisableTrigger') is null 
		CREATE TABLE #DisableTrigger (vcTriggerName varchar(250))
	ELSE
	BEGIN
		-- Le trigger doit être retrouvé dans la table pour être ignoré
		IF EXISTS (SELECT 1 FROM #DisableTrigger WHERE OBJECT_NAME(@@PROCID) like vcTriggerName)
		BEGIN
			-- Ne pas faire le trigger
			EXEC dbo.TT_PrintDebugMsg @@ProcID, 'Trigger Ignored'
			RETURN
		END
	END
	
	--	Bloque le trigger des DELETEs
	INSERT INTO #DisableTrigger VALUES(OBJECT_NAME(@@PROCID))	

	UPDATE Un_ConventionAccount SET AccountName = UPPER(dbo.fn_Mo_FormatStringWithoutAccent(i.AccountName))
	FROM Un_ConventionAccount M, inserted i
	WHERE M.ConventionID = i.ConventionID

	DECLARE @Now Datetime = GetDate()
		,	@RecSep CHAR(1) = CHAR(30)
		,	@CrLf CHAR(2) = CHAR(13) + CHAR(10)
		,	@ActionID int = (SELECT LogActionID FROM CRQ_LogAction WHERE LogActionShortName = 'I')

	-- Insère un log de l'objet inséré.
	INSERT INTO CRQ_Log (ConnectID, LogTableName, LogCodeID, LogTime, LogActionID, LogDesc, LogText)
		SELECT
			2, 'Un_Convention', New.ConventionID, @Now, @ActionID, 
			LogDesc = 'Compte bancaire de convention : ' + (Select ConventionNo From dbo.Un_Convention Where ConventionID = New.ConventionID), 
			LogText = 
				'BankID' + @RecSep + LTrim(Str(New.BankID)) 
						 + @RecSep + ISNULL((Select T.BankTypeCode+'-'+B.BankTransit FROM dbo.Mo_Bank B JOIN dbo.Mo_BankType T ON T.BankTypeID = B.BankTypeID Where BankID = New.BankID), '')
						 + @RecSep +  @CrLf +
				'TransitNo' + @RecSep + New.TransitNo
							+ @RecSep +  @CrLf +
				'AccountName' + @RecSep + UPPER(dbo.fn_Mo_FormatStringWithoutAccent(New.AccountName))
							  + @RecSep +  @CrLf +
				''
		FROM	inserted New

	IF OBJECT_ID('tempDB..#DisableTrigger') IS NOT NULL
        DELETE FROM #DisableTrigger WHERE vcTriggerName = OBJECT_NAME(@@PROCID)

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des comptes bancaires des conventions.  Un compte bancaire contient l''information nécessaire au prélèvement automatique : Numéro de compte, nom du compte, transit, numéro de banque.  Le compte bancaire est obligatoire pour les conventions avec mode de prélèvement dépôt automatique.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionAccount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la convention (Un_Convention) à laquel appartient le compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionAccount', @level2type = N'COLUMN', @level2name = N'ConventionID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la succursales financières (Mo_Bank) du compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionAccount', @level2type = N'COLUMN', @level2name = N'BankID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro du compte.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionAccount', @level2type = N'COLUMN', @level2name = N'TransitNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'C''est le nom du compte. Par défaut, c''est le nom du souscripteur en majuscule et sans accent.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Un_ConventionAccount', @level2type = N'COLUMN', @level2name = N'AccountName';

