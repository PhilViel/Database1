CREATE RULE [dbo].[Un_ProjectionType_RULE]
    AS @ProjectionType IN(1, 2, 4, 12);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ProjectionType_RULE]', @objname = N'[dbo].[Un_Def].[ProjectionType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ProjectionType_RULE]', @objname = N'[dbo].[UnProjectionType]';

