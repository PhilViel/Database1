CREATE DEFAULT [dbo].[Mo_Dep_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Dep_DEF]', @objname = N'[dbo].[Mo_Dep].[DepType]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Dep_DEF]', @objname = N'[dbo].[MoDep]';

