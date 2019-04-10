CREATE RULE [dbo].[Un_ConventionStatus_RULE]
    AS @ConventionStatus IN 
('PRO','PRD','PRT','PRV','PTI','CAC','CTI','CTO','CRT','CER','CSU',
'CAR','CDE','CDA','CDF','CRE','CRZ','CRM','CBR','CAR','CMR','CMS');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_ConventionStatus_RULE]', @objname = N'[dbo].[UnConventionStatus]';

