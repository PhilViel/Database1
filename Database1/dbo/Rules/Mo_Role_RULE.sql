CREATE RULE [dbo].[Mo_Role_RULE]
    AS @RoleID IN ('MOD', 'ADM', 'VER', 'SUP','DIR','EMP','GUE');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Role_RULE]', @objname = N'[dbo].[MoRole]';

