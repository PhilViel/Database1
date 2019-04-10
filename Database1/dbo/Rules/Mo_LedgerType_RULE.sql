CREATE RULE [dbo].[Mo_LedgerType_RULE]
    AS @LedgerType IN ('UNK','AST','EXP','INC','LIA','EQT');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_LedgerType_RULE]', @objname = N'[dbo].[MoLedgerType]';

