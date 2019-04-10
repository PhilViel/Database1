CREATE DEFAULT [dbo].[Un_ExternalTransferStatusID_DEF]
    AS 0;


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_ExternalTransferStatusID_DEF]', @objname = N'[dbo].[Un_ExternalTransferStatusHistory].[ExternalTransferStatusID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_ExternalTransferStatusID_DEF]', @objname = N'[dbo].[UnExternalTransferStatusID]';

