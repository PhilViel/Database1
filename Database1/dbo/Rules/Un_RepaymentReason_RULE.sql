CREATE RULE [dbo].[Un_RepaymentReason_RULE]
    AS @RepaymentReason IN (1, 2, 3, 4, 5, 6, 7);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepaymentReason_RULE]', @objname = N'[dbo].[UnRepaymentReason]';

