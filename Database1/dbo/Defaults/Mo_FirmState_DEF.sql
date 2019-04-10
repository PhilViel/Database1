CREATE DEFAULT [dbo].[Mo_FirmState_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_FirmState_DEF]', @objname = N'[dbo].[MoFirmState]';

