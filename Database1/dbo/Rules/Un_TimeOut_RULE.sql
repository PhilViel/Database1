CREATE RULE [dbo].[Un_TimeOut_RULE]
    AS @TimeUnit BETWEEN 0 AND 4;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TimeOut_RULE]', @objname = N'[dbo].[Un_AutomaticDeposit].[TimeUnit]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TimeOut_RULE]', @objname = N'[dbo].[UnTimeOut]';

