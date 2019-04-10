CREATE DEFAULT [dbo].[Mo_Lang_DEF]
    AS 'UNK';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[Mo_Cheque].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurL].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[Mo_Human].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[TMPRepSynchro].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreur4].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[Mo_Company].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurM].[LangID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Lang_DEF]', @objname = N'[dbo].[MoLang]';

