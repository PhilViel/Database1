CREATE RULE [dbo].[Mo_Priority_RULE]
    AS @PriorityID BETWEEN 1 AND 5;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_Priority_RULE]', @objname = N'[dbo].[MoPriority]';

