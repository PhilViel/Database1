CREATE RULE [dbo].[Un_BreakingType_RULE]
    AS @BreakingType IN ('STP', 'SUS', 'RES', 'RNA', 'TRI');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_BreakingType_RULE]', @objname = N'[dbo].[Un_Breaking].[BreakingTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_BreakingType_RULE]', @objname = N'[dbo].[Un_BreakingCPA].[BreakingTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_BreakingType_RULE]', @objname = N'[dbo].[UnBreakingType]';

