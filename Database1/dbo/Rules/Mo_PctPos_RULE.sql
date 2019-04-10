CREATE RULE [dbo].[Mo_PctPos_RULE]
    AS @PctPos >= 0;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_Modal].[PmtRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_Modal].[SubscriberInsuranceRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepLevel].[ConservationRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepBossHist].[RepBossPct]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepConservBonusCfg].[ConservBonusRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepContestUnitMultFactorCfg].[RecruitUnitMultFactor]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepContestUnitMultFactorCfg].[NonRecruitUnitMultFactor]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepTreatment].[MaxRepRisk]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_Def].[MaxRepRisk]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_HalfSubscriberInsurance].[HalfSubscriberInsuranceRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepConservRateCfg].[MinConservRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepConservRateCfg].[MaxConservRate]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Un_RepConservRateCfg].[RateOnBonus]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Mo_State].[StateTaxPct]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[Mo_Country].[CountryTaxPct]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PctPos_RULE]', @objname = N'[dbo].[MoPctPos]';

