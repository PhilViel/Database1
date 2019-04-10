CREATE DEFAULT [dbo].[Mo_InterestLevel_DEF]
    AS 'R';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_InterestLevel_DEF]', @objname = N'[dbo].[MoInterestLevel]';

