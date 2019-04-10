CREATE RULE [dbo].[Un_ScholarshipStatus_RULE]
    AS @StudyGrantStatus IN ('RES','PAD','ADM','WAI','TPA','DEA','REN','25Y','24Y', 'ANL');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipStatus_RULE]', @objname = N'[dbo].[Un_Scholarship].[ScholarshipStatusID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipStatus_RULE]', @objname = N'[dbo].[Un_Scholarship_Archive_Projet_Critere].[ScholarshipStatusID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ScholarshipStatus_RULE]', @objname = N'[dbo].[UnScholarshipStatus]';

