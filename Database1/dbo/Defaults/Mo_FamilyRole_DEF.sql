CREATE DEFAULT [dbo].[Mo_FamilyRole_DEF]
    AS 'U';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_FamilyRole_DEF]', @objname = N'[dbo].[Mo_FamilyDtl].[FamilyRoleID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_FamilyRole_DEF]', @objname = N'[dbo].[MoFamilyRole]';

