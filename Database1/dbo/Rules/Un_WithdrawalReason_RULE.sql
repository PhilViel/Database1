CREATE RULE [dbo].[Un_WithdrawalReason_RULE]
    AS @WithdrawalReasonID BETWEEN 1 AND 6;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_WithdrawalReason_RULE]', @objname = N'[dbo].[Un_WithdrawalReason].[WithdrawalReasonID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_WithdrawalReason_RULE]', @objname = N'[dbo].[UnWithdrawalReason]';

