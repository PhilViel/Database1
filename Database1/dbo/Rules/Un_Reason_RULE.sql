CREATE RULE [dbo].[Un_Reason_RULE]
    AS @Reason IN ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_Reason_RULE]', @objname = N'[dbo].[UnReason]';

