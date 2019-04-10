CREATE DEFAULT [dbo].[Mo_AdrType_DEF]
    AS 'H';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_AdrType_DEF]', @objname = N'[dbo].[Mo_Adr_Old].[AdrTypeID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_AdrType_DEF]', @objname = N'[dbo].[MoAdrType]';

