CREATE RULE [dbo].[Mo_InterestLevel_RULE]
    AS @Mo_InterestLevel IN ('R', 'W');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_InterestLevel_RULE]', @objname = N'[dbo].[MoInterestLevel]';

