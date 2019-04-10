CREATE RULE [dbo].[Un_RepContestType_RULE]
    AS @RepContestType IN ('CBP', 'REC', 'DIR', 'OTH');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepContestType_RULE]', @objname = N'[dbo].[Un_RepContestCfg].[RepContestType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepContestType_RULE]', @objname = N'[dbo].[UnRepContestType]';

