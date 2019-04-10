CREATE RULE [dbo].[Un_GovernmentShipCode_RULE]
    AS @GovernmentShipCode  IN ('NOT','AUT','FOR');


GO
EXECUTE sp_bindrule @rulename = N'[dbo].[Un_GovernmentShipCode_RULE]', @objname = N'[dbo].[UnGovernmentShipCode]';

