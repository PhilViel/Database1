CREATE RULE [dbo].[Un_EligibilityCondition_RULE]
    AS @EligibilityCondition IN ('UNK','YEA','CRS','CDT', 'SES', '3MT', 'HRS');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_EligibilityCondition_RULE]', @objname = N'[dbo].[Un_College].[EligibilityConditionID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_EligibilityCondition_RULE]', @objname = N'[dbo].[UnEligibilityCondition]';

