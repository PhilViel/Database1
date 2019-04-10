CREATE DEFAULT [dbo].[Mo_Priority_DEF]
    AS 5;


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Priority_DEF]', @objname = N'[dbo].[MoPriority]';

