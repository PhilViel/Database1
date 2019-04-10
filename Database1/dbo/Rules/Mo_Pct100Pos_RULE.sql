CREATE RULE [dbo].[Mo_Pct100Pos_RULE]
    AS @Pct100Pos BETWEEN 0 AND 100;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Pct100Pos_RULE]', @objname = N'[dbo].[MoPct100Pos]';

