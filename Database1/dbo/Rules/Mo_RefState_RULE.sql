CREATE RULE [dbo].[Mo_RefState_RULE]
    AS @Mo_RefState IN ('', 'R', 'I', 'C', 'X');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_RefState_RULE]', @objname = N'[dbo].[MoRefState]';

