CREATE RULE [dbo].[Un_Reason950_RULE]
    AS @950Reason IN ('0', '1', '2', '3', '4');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_Reason950_RULE]', @objname = N'[dbo].[UnReason950]';

