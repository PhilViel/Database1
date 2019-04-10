CREATE RULE [dbo].[Mo_RegularSign_RULE]
    AS @LedgerType IN ('CT','DT');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_RegularSign_RULE]', @objname = N'[dbo].[MoRegularSign]';

