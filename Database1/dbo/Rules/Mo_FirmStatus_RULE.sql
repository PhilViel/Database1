CREATE RULE [dbo].[Mo_FirmStatus_RULE]
    AS @Mo_FirmStatus IN ('A', 'I');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_FirmStatus_RULE]', @objname = N'[dbo].[Mo_Firm].[FirmStatusID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_FirmStatus_RULE]', @objname = N'[dbo].[MoFirmStatus]';

