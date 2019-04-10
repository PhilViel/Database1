CREATE RULE [dbo].[Un_FileNumber_RULE]
    AS @FileNumber BETWEEN 1 AND 99;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_FileNumber_RULE]', @objname = N'[dbo].[UnFileNumber]';

