CREATE RULE [dbo].[Mo_RefStatus_RULE]
    AS @Mo_RefStatus IN ('', 'R', 'I', 'C', 'X');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_RefStatus_RULE]', @objname = N'[dbo].[MoRefStatus]';

