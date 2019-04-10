CREATE DEFAULT [dbo].[Un_RepContestType_DEF]
    AS 'OTH';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_RepContestType_DEF]', @objname = N'[dbo].[Un_RepContestCfg].[RepContestType]';

