CREATE TABLE [dbo].[Mo_Company] (
    [CompanyID]        [dbo].[MoID]          IDENTITY (1, 1) NOT NULL,
    [CompanyName]      [dbo].[MoCompanyName] NOT NULL,
    [LangID]           [dbo].[MoLang]        NOT NULL,
    [WebSite]          [dbo].[MoEmail]       NULL,
    [CountryTaxNumber] [dbo].[MoDescoption]  NULL,
    [StateTaxNumber]   [dbo].[MoDescoption]  NULL,
    [EndBusiness]      [dbo].[MoDateoption]  NULL,
    CONSTRAINT [PK_Mo_Company] PRIMARY KEY CLUSTERED ([CompanyID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_Mo_Company_CompanyName]
    ON [dbo].[Mo_Company]([CompanyName] ASC) WITH (FILLFACTOR = 90);


GO

CREATE TRIGGER [dbo].[TMo_Company] ON [dbo].[Mo_Company] FOR INSERT, UPDATE
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
	
  UPDATE Mo_Company SET
    EndBusiness = dbo.fn_Mo_DateNoTime( i.EndBusiness)
  FROM Mo_Company M, inserted i
  WHERE M.CompanyID = i.CompanyID
	EXEC dbo.TT_PrintDebugMsg @@ProcID, 'End'
END;


GO
GRANT SELECT
    ON OBJECT::[dbo].[Mo_Company] TO PUBLIC
    AS [dbo];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Table des compagnies.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'ID unique de la compagnie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'CompanyID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Nom de la compagnie.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'CompanyName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Chaîne de trois caractères de la langue de communication de la compagnie (ENU=Anglais, FRA=Français, UNK=Inconnu).', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'LangID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Adresse du site internet de la compgnie s''il y en a un.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'WebSite';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de taxe fédérale.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'CountryTaxNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Numéro de taxe provincial.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'StateTaxNumber';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = 'Date de fin des affaires.', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'Mo_Company', @level2type = N'COLUMN', @level2name = N'EndBusiness';

