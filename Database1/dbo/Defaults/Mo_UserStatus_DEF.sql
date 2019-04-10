CREATE DEFAULT [dbo].[Mo_UserStatus_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_UserStatus_DEF]', @objname = N'[dbo].[MoUserStatus]';

