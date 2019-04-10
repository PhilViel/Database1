CREATE DEFAULT [dbo].[Mo_Zero_DEF]
    AS 0;


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[ScholarshipNo]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[EligibleUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[PlanValue]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[UnitValue]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[Rest]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepAccount].[AjustmentAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ExternalTransfert].[UnassistedCapitalAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ExternalTransfert].[AssistedCapitalAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ExternalTransfert].[GovernmentGrantOldAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ExternalTransfert].[TotalAssetAmountTransfered]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Convention].[ScholarshipYear]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Scholarship].[ScholarshipNo]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepLevel].[TargetUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepLevel].[ConservationRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepException].[RepExceptionAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_Document].[DocIsExtract]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_Country].[CountryTaxPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_Firm].[MonthlyTarget]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[GovernmentGrantForm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[PersonalInfo]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[BirthCertificate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_Human].[IsCompany]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_NoteType].[NoteTypePrivate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepContestUnitMultFactorCfg].[RecruitUnitMultFactor]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepContestUnitMultFactorCfg].[NonRecruitUnitMultFactor]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_OtherAccountOper].[OtherAccountOperAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Cotisation].[Cotisation]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Cotisation].[Fee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Cotisation].[BenefInsur]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Cotisation].[SubscInsur]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Cotisation].[TaxOnInsur]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_MinDepositCfg].[MinAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[TotalFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[CoverdAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[ServiceComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[PeriodComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[CumComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[ServiceBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[PeriodBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[CumBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[PaidAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjection].[CommExpenses]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_AutomaticDeposit].[CotisationFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_AutomaticDeposit].[SubscInsur]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_AutomaticDeposit].[BenefInsur]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepFormationFeeCfg].[FormationFeeAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Convention].[YearQualif]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[PeriodCommBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[YearCommBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[PeriodCoveredAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[YearCoveredAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[AVSAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[AVRAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[AdvanceSolde]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[AVSAmountSolde]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepProjectionSumary].[AVRAmountSolde]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[REPPeriodUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CumREPPeriodUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[DIRPeriodUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CumDIRPeriodUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[REPConsPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[DIRConsPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[ConsPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[BusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CoveredAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[NewAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CommANDBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepBusinessBonus].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepBusinessBonus].[BusinessBonusAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_NoteType].[NoteTypeLogText]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_NoteType].[NoteTypeAllowObject]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_MinUniqueDepCfg].[MinAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepBusinessBonusCfg].[BusinessBonusByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_IntReimb].[FeeRefund]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_SpecialAdvance].[Amount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_StudyCost].[StudyCost]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_StudyCost].[StudyCostCA]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_MinIndAutDepositCfg].[MinAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Scholarship].[ScholarshipAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_IntReimb].[CESGRenonciation]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[PeriodUnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[TotalFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[PeriodAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[CoverdAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[CumAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[ServiceComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[PeriodComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[CummComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[FuturComm]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[BusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[PeriodBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[CummBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[FuturBusinessBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[SweepstakeBonusAjust]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[PaidAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatment].[CommExpenses]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Modal].[PmtRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Modal].[SubscriberInsuranceRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Modal].[FeeByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Modal].[FeeSplitByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Modal].[FeeRefundable]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservBonusCfg].[UnitMin]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservBonusCfg].[UnitMax]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservBonusCfg].[ConservBonusRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepTreatment].[MaxRepRisk]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanOper].[PlanOperAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_InterestRate].[InterestRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_InterestRate].[GovernmentGrantInterestRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepContestPriceCfg].[MinUnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Xx_RepCommission].[Advance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Xx_RepCommission].[AnnualBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Xx_RepCommission].[Commission]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Xx_RepCommission].[FormationFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Xx_RepCommission].[OtherFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepBossHist].[RepBossPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[ProjectionOnNextRepTreatment]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[MaxSubscribeAmountAjustmentDiff]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_BenefInsur].[BenefInsurRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[ScholarshipGrantAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_PlanValues].[CollectiveGrantAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[MaxRepRisk]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[LastDepositMaxInInterest]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_BenefInsur].[BenefInsurFaceValue]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ScholarshipPmt].[RegistrationProof]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ScholarshipPmt].[SchoolReport]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ScholarshipPmt].[EligibilityQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ScholarshipPmt].[CaseOfJanuary]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[Adjustment]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[ChqBrut]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CumChqBrut]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[Retenu]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[ChqNet]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[Mois]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CumMois]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[Advance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[FuturCom]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Dn_RepTreatmentSumary].[CommPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Subscriber].[AddressLost]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[TotalAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20071231]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080105]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080112]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080119]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080126]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080202]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080209]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080216]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080223]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080301]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080308]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080315]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080322]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080329]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080405]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080412]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080419]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080426]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080503]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080510]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080517]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080524]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080531]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080607]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080614]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080621]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080628]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080705]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080712]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080719]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080726]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080802]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080809]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080816]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080823]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080830]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080906]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080913]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080920]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20080927]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081004]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081011]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081018]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081025]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081101]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081108]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081115]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReportCrossTab].[20081122]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_MinConvUnitQtyCfg].[MinUnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Subscriber].[AnnualIncome]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Subscriber].[SemiAnnualStatement]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[DemandeCOT].[NombreUnite]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_ConventionOper].[ConventionOperAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_Cheque].[ChequeAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_TFRCfg].[AvailableMonth]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[RegistrationProof]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[SchoolReport]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[EligibilityQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Beneficiary].[CaseOfJanuary]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_BeneficiaryCeilingCfg].[AnnualCeiling]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_BeneficiaryCeilingCfg].[LifeCeiling]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_UnitReduction].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_UnitReduction].[FeeSumByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_UnitReduction].[SubscInsurSumByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_ChequeDtl].[ChequeDtlAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_OperType].[HoldGovernmentOnPending]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_OperType].[TotalZero]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[CoveredAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Unit].[SubscribeAmountAjustment]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[NewAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[CommAndBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[Adjustment]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[Retenu]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[ChqNet]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[Advance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[TerminatedAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[TMPRepTreatmentReport].[SpecialAdvance]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCharge].[RepChargeAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepLevelBracket].[TargetFeeByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepLevelBracket].[AdvanceByUnit]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Unit].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Scholarship_Archive_Projet_Critere].[ScholarshipAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Mo_State].[StateTaxPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Scholarship_Archive_Projet_Critere].[ScholarshipNo]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[IntReimbAge]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_HalfSubscriberInsurance].[HalfSubscriberInsuranceRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanMaxCotisationFirstYear]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanMaxCotisationByYear]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanLifeTimeCotisationByBeneficiary]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanMaxGovernmentGrant]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservRateCfg].[MinConservRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservRateCfg].[MaxConservRate]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepConservRateCfg].[RateOnBonus]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanScholarshipQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Plan].[PlanOrderID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[UnitQty]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[RepPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[TotalFee]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[AdvanceAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[CoveredAdvanceAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_RepCommission].[CommissionAmount]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[MaxLifeCotisation]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[Un_Def].[MaxYearCotisation]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoBitFalse]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoOrder]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoPct]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoPct100]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoPct100Pos]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoPctPos]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Mo_Zero_DEF]', @objname = N'[dbo].[MoMoney]';

