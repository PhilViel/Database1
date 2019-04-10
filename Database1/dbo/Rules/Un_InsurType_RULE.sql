CREATE RULE [dbo].[Un_InsurType_RULE]
    AS @InsurType IN ('ISB','IB5','IB1','IB2');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_InsurType_RULE]', @objname = N'[dbo].[Un_RepBusinessBonus].[InsurTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_InsurType_RULE]', @objname = N'[dbo].[Un_RepBusinessBonusCfg].[InsurTypeID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_InsurType_RULE]', @objname = N'[dbo].[UnInsurType]';

