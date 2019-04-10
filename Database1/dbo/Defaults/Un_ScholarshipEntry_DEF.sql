CREATE DEFAULT [dbo].[Un_ScholarshipEntry_DEF]
    AS 'A';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_ScholarshipEntry_DEF]', @objname = N'[dbo].[Un_Convention].[ScholarshipEntryID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_ScholarshipEntry_DEF]', @objname = N'[dbo].[UnScholarshipEntry]';

