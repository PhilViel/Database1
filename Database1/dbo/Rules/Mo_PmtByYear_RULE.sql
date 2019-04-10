CREATE RULE [dbo].[Mo_PmtByYear_RULE]
    AS @PmtByYear IN (1,2,3,4,6,12);


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PmtByYear_RULE]', @objname = N'[dbo].[Un_BenefInsur].[BenefInsurPmtByYear]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PmtByYear_RULE]', @objname = N'[dbo].[Un_Modal].[PmtByYearID]';


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Mo_PmtByYear_RULE]', @objname = N'[dbo].[MoPmtByYear]';

