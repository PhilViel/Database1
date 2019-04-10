CREATE RULE [dbo].[Mo_Sex_RULE]
    AS @Sex IN ('U', 'F', 'M');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[Mo_Sex].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreur4].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[Mo_Human].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurL].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[Mo_Cheque].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[Mo_CivilStatus].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[tblCONV_ReleveDeCompte_RecensementPCEEerreurM].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[TMPRepSynchro].[SexID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Sex_RULE]', @objname = N'[dbo].[MoSex]';

