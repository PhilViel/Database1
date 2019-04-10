CREATE RULE [dbo].[Mo_Lang_RULE]
    AS @Lang IN ('UNK', 'ENU', 'FRA');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[TMPRepSynchro].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[Mo_Human].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurL].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[Mo_Cheque].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurM].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreur4].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[Mo_Company].[LangID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Lang_RULE]', @objname = N'[dbo].[MoLang]';

