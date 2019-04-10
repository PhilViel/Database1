CREATE RULE [dbo].[Un_PCGType_RULE]
    AS @PCGType IN (1,2);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Apres_Conversion_15].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Apres_Conversion_12].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[Un_CESP511].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[Un_CESP400].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[Un_Beneficiary].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Apres_Conversion_10].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Apres_Conversion_14].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Avant_Conversion].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[TMP_Convention_Apres_Conversion_13].[tiPCGType]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_PCGType_RULE]', @objname = N'[dbo].[UnPCGType]';

