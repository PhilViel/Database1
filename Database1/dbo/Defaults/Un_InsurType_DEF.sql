CREATE DEFAULT [dbo].[Un_InsurType_DEF]
    AS 'ISB';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_InsurType_DEF]', @objname = N'[dbo].[Un_RepBusinessBonusCfg].[InsurTypeID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_InsurType_DEF]', @objname = N'[dbo].[Un_RepBusinessBonus].[InsurTypeID]';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_InsurType_DEF]', @objname = N'[dbo].[UnInsurType]';

