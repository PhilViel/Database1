CREATE RULE [dbo].[Mo_FirmState_RULE]
    AS @Mo_FirmState IN ('A', 'I');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_FirmState_RULE]', @objname = N'[dbo].[MoFirmState]';

