CREATE RULE [dbo].[Un_BenefLinkType_RULE]
    AS @BenefLinkType BETWEEN 1 AND 6;


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_BenefLinkType_RULE]', @objname = N'[dbo].[UnBenefLinkType]';

