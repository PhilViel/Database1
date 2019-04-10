CREATE RULE [dbo].[Mo_FamilyRole_RULE]
    AS @FamilyRole IN ('U','O','C','P','G','S','H', 'M');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_FamilyRole_RULE]', @objname = N'[dbo].[Mo_FamilyDtl].[FamilyRoleID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_FamilyRole_RULE]', @objname = N'[dbo].[MoFamilyRole]';

