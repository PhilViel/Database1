CREATE DEFAULT [dbo].[Mo_UserState_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_UserState_DEF]', @objname = N'[dbo].[MoUserState]';

