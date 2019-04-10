CREATE RULE [dbo].[Mo_AdrType_RULE]
    AS @AdrType IN ('H','C');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_AdrType_RULE]', @objname = N'[dbo].[Mo_Adr_Old].[AdrTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_AdrType_RULE]', @objname = N'[dbo].[MoAdrType]';

