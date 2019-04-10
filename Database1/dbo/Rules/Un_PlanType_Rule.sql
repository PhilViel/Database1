CREATE RULE [dbo].[Un_PlanType_Rule]
    AS @PlanTypeID IN ('IND', 'COL', 'FAM', 'GRO');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PlanType_Rule]', @objname = N'[dbo].[Un_Plan].[PlanTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PlanType_Rule]', @objname = N'[dbo].[Un_ExternalPlan].[ExternalPlanTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PlanType_Rule]', @objname = N'[dbo].[UnPlanType]';

