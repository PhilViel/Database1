CREATE RULE [dbo].[Un_RepLevelBracketType_RULE]
    AS @RepLevelBracketType IN ('COM', 'ADV', 'CAD');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepLevelBracketType_RULE]', @objname = N'[dbo].[Un_RepLevelBracket].[RepLevelBracketTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_RepLevelBracketType_RULE]', @objname = N'[dbo].[UnRepLevelBracketType]';

