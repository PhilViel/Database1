CREATE DEFAULT [dbo].[Mo_RefStatus_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_RefStatus_DEF]', @objname = N'[dbo].[MoRefStatus]';

