CREATE RULE [dbo].[Un_ScholarshipEntry_RULE]
    AS @ScholarshipEntry IN ('S','A','R','G');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipEntry_RULE]', @objname = N'[dbo].[Un_Convention].[ScholarshipEntryID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipEntry_RULE]', @objname = N'[dbo].[UnScholarshipEntry]';

