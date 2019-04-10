CREATE DEFAULT [dbo].[Un_RepLevelBracketType_DEF]
    AS 'COM';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_RepLevelBracketType_DEF]', @objname = N'[dbo].[Un_RepLevelBracket].[RepLevelBracketTypeID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_RepLevelBracketType_DEF]', @objname = N'[dbo].[UnRepLevelBracketType]';

