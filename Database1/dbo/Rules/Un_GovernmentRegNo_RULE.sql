CREATE RULE [dbo].[Un_GovernmentRegNo_RULE]
    AS (Substring(@RegNo,1,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,2,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,3,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,4,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,5,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,6,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,7,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,8,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,9,1) in ('0','1','2','3','4','5','6','7','8','9'))
AND (Substring(@RegNo,10,1) in ('0','1','2','3','4','5','6','7','8','9'));


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_GovernmentRegNo_RULE]', @objname = N'[dbo].[Un_ExternalPlan].[ExternalPlanGovernmentRegNo]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_GovernmentRegNo_RULE]', @objname = N'[dbo].[Un_Plan].[PlanGovernmentRegNo]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_GovernmentRegNo_RULE]', @objname = N'[dbo].[UnGovernmentRegNo]';

