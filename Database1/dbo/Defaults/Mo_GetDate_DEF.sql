CREATE DEFAULT [dbo].[Mo_GetDate_DEF]
    AS GetDate();


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_BeneficiaryCeilingCfg].[Effectdate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_UnitReduction].[ReductionDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_BankReturnFile].[BankReturnFileDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepException].[RepExceptionDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Log].[LogTime]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_AvailableFeeExpirationCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_ChequeOrder].[ChequeOrderDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepContestUnitMultFactorCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Cotisation].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_ConventionConventionState].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepFormationFeeCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Oper].[OperDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_ConventionYearQualif].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_AutomaticDeposit].[FirstAutomaticDepositDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Convention].[FirstPmtDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_AutomaticDeposit].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_HumanSocialNumber].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_ExternalTransferStatusHistoryFile].[ExternalTransferStatusHistoryFileDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepTreatment].[RepTreatmentDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[RepTreatmentDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[FirstDepositDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[InforceDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Adr_Old].[InForce]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepConservBonusCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Xx_RepCommission].[CommissionDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Modal].[ModalDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_UnitHoldPayment].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Adr_Old].[InsertTime]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepBossHist].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_BenefInsur].[BenefInsurDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepBusinessBonusCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_SpecialAdvance].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[RepTreatmentDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Exception].[ExceptionDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_IrregularityTypeCorrection].[CorrectingDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Connect].[ConnectStart]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_BreakingCPA].[BreakingStartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_SubscriberAgeLimitCfg].[Effectdate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Breaking].[BreakingStartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_TFRCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[tmpSommIND].[DateOuverture]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_MinConvUnitQtyCfg].[Effectdate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_MaxConvDepositDateCfg].[Effectdate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Mo_Version].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepContestCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[RepTreatmentDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepCharge].[RepChargeDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_UnitUnitState].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepLevelBracket].[EffectDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_Unit].[InForceDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepConservRateCfg].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[Un_RepLevelHist].[StartDate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_GetDate_DEF]', @objname = N'[dbo].[MoGetDate]';

