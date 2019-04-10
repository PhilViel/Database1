CREATE TABLE [dbo].[Mo_User] (
    [UserID]          [dbo].[MoID]         NOT NULL,
    [LoginNameID]     [dbo].[MoLoginName]  NOT NULL,
    [PassWordID]      [dbo].[MoLoginName]  NOT NULL,
    [CodeID]          [dbo].[MoIDoption]   NULL,
    [PassWordDate]    [dbo].[MoDate]       NOT NULL,
    [TerminatedDate]  [dbo].[MoDateoption] NULL,
    [PassWordEndDate] [dbo].[MoDate]       NULL,
    CONSTRAINT [PK_Mo_User] PRIMARY KEY CLUSTERED ([UserID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Mo_User_Mo_Human__UserID] FOREIGN KEY ([UserID]) REFERENCES [dbo].[Mo_Human] ([HumanID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [AK_Mo_User_LoginNameID]
    ON [dbo].[Mo_User]([LoginNameID] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER dbo.TR_MoUser_Ins ON dbo.Mo_User FOR INSERT
AS BEGIN

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
	
	------------------------------------
	-- TRIGGER D'AJOUT TABLE Mo_User
	------------------------------------

	/* Ajout de l'usager ajout‚ dans le groupe de s‚curit‚ des repr‚sentants s'il est un repr‚sentant */ 
	INSERT Mo_UserGroupDtl (UserID, UserGroupID)
	SELECT I.UserID, G.UserGroupID
	FROM INSERTED I
	INNER JOIN Un_Rep R
		ON I.UserID = R.RepID
	CROSS JOIN (SELECT UserGroupID FROM Mo_UserGroup WHERE UserGroupDesc = 'Représentant') G

	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END

GO

CREATE TRIGGER [dbo].[TMo_User] ON [dbo].[Mo_User] FOR INSERT, UPDATE
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
	
  UPDATE Mo_User SET
    PasswordDate = dbo.fn_Mo_DateNoTime( i.PasswordDate)
  FROM Mo_User M, inserted i
  WHERE M.UserID = i.UserID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_User] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Tables des usagers.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de l''usager.  Correspond à un HumanID de la table Mo_Human.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'UserID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom d''usager.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'LoginNameID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Mot de passe encrypté.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'PassWordID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Code de l''utilisateur: 0 = Employés du Siège Social, 1 = Souscripteurs, 2 = Bénéficiaires, 12 = Représentants', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'CodeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''entré en vigueur de ce mot de passe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'PassWordDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date du départ de l''usager. Rend l''usager inactif.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'TerminatedDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''expiration du mot de passe.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_User', @level2type = N'COLUMN', @level2name = N'PassWordEndDate';

