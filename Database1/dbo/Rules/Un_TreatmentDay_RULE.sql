CREATE RULE [dbo].[Un_TreatmentDay_RULE]
    AS @TreatmentDay BETWEEN 1 AND 7;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TreatmentDay_RULE]', @objname = N'[dbo].[Un_AutomaticDepositTreatmentCfg].[TreatmentDay]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_TreatmentDay_RULE]', @objname = N'[dbo].[UnTreatmentDay]';

