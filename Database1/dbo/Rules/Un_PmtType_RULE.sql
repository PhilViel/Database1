CREATE RULE [dbo].[Un_PmtType_RULE]
    AS @PmtType IN ('AUT','CHQ');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PmtType_RULE]', @objname = N'[dbo].[Un_Convention].[PmtTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PmtType_RULE]', @objname = N'[dbo].[UnPmtType]';

