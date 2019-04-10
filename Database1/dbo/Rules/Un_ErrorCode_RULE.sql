CREATE RULE [dbo].[Un_ErrorCode_RULE]
    AS @ErrorCode BETWEEN 1 AND 9015;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ErrorCode_RULE]', @objname = N'[dbo].[Un_GovernmentPrevalError].[ErrorCode]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ErrorCode_RULE]', @objname = N'[dbo].[UnErrorCode]';

