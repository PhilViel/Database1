CREATE DEFAULT [dbo].[Mo_Role_DEF]
    AS 'GUE';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Role_DEF]', @objname = N'[dbo].[MoRole]';

