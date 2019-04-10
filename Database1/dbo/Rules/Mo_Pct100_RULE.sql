CREATE RULE [dbo].[Mo_Pct100_RULE]
    AS @Pct100Pos BETWEEN -100 AND 100;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Pct100_RULE]', @objname = N'[dbo].[Un_InterestRate].[InterestRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Pct100_RULE]', @objname = N'[dbo].[Un_InterestRate].[GovernmentGrantInterestRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Pct100_RULE]', @objname = N'[dbo].[MoPct100]';

