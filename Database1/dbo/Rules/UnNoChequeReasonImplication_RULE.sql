CREATE RULE [dbo].[UnNoChequeReasonImplication_RULE]
    AS @NoChequeReasonImplication IN (0,1,2);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[UnNoChequeReasonImplication_RULE]', @objname = N'[dbo].[Un_NoChequeReason].[NoChequeReasonImplicationID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[UnNoChequeReasonImplication_RULE]', @objname = N'[dbo].[UnNoChequeReasonImplication]';

