CREATE RULE [dbo].[Mo_LogAction_RULE]
    AS @LogAction IN ('I','U','D');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_LogAction_RULE]', @objname = N'[dbo].[Mo_Log].[LogActionID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_LogAction_RULE]', @objname = N'[dbo].[MoLogaction]';

