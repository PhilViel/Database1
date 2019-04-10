CREATE TABLE [dbo].[Mo_Def] (
    [CompanyName]        [dbo].[MoCompanyName] NULL,
    [DefaultStateID]     [dbo].[MoIDoption]    NULL,
    [DefaultCountryID]   [dbo].[MoCountry]     NOT NULL,
    [GeneralPath]        [dbo].[MoDescoption]  NULL,
    [ModulexVersion]     [dbo].[MoID]          NULL,
    [ApplicationVersion] [dbo].[MoID]          NULL,
    [PatchVersion]       [dbo].[MoIDoption]    NULL,
    [VersionDate]        [dbo].[MoDate]        NULL,
    [MaxActiveUser]      [dbo].[MoIDoption]    NULL
);


GO

CREATE TRIGGER [dbo].[TMo_Def] ON [dbo].[Mo_Def] FOR INSERT, UPDATE
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

  UPDATE Mo_Def SET
    VersionDate = dbo.fn_Mo_DateNoTime( i.VersionDate)
  FROM Mo_Def M, inserted i
--  WHERE M.Version = i.Version
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des options modulex de l''application.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la compagnie par défaut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'CompanyName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la province (Mo_State) par défaut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'DefaultStateID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique du pays (Mo_Country) par défaut.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'DefaultCountryID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Arborescence générique aux usagers (Ex: V:).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'GeneralPath';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Version courante du module Modulex de la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'ModulexVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Version courante du module UniSql de la base de données.  Avec le ModulexVersion on peut s''assurer que la version de l''application est celle qui correspond à la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'ApplicationVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de compilation avec laquel fonctionne la base de données courante.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'PatchVersion';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date d''implantation de la version courante dans la base de données.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'VersionDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nombre maximum d''usagers pouvant ce connecter simultanément.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Def', @level2type = N'COLUMN', @level2name = N'MaxActiveUser';

