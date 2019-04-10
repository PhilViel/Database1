CREATE RULE [dbo].[UnExternalTransferStatusID_RULE]
    AS @ExternalTransferStatusID IN ('30D','60D','90D','ACC');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[UnExternalTransferStatusID_RULE]', @objname = N'[dbo].[Un_ExternalTransferStatusHistory].[ExternalTransferStatusID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[UnExternalTransferStatusID_RULE]', @objname = N'[dbo].[UnExternalTransferStatusID]';

