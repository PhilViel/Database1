CREATE DEFAULT [dbo].[Mo_FirmStatus_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_FirmStatus_DEF]', @objname = N'[dbo].[Mo_Firm].[FirmStatusID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_FirmStatus_DEF]', @objname = N'[dbo].[MoFirmStatus]';

