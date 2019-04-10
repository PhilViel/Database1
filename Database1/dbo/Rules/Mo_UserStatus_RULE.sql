CREATE RULE [dbo].[Mo_UserStatus_RULE]
    AS @Mo_UserStatus IN ('A', 'I', 'V');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_UserStatus_RULE]', @objname = N'[dbo].[MoUserStatus]';

