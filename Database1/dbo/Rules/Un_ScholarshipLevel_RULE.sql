CREATE RULE [dbo].[Un_ScholarshipLevel_RULE]
    AS @ScholarshipLevel IN ('UNK','NDI','SEC','COL','UNI');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipLevel_RULE]', @objname = N'[dbo].[Un_Subscriber].[ScholarshipLevelID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipLevel_RULE]', @objname = N'[dbo].[UnScholarshipLevel]';

