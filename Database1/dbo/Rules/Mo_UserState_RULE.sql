CREATE RULE [dbo].[Mo_UserState_RULE]
    AS @Mo_UserState IN ('A', 'I', 'V');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_UserState_RULE]', @objname = N'[dbo].[MoUserState]';

