CREATE DEFAULT [dbo].[Un_GovernmentShipCode_DEF]
    AS 'AUT';


GO
EXECUTE sp_bindefault @defname = N'[dbo].[Un_GovernmentShipCode_DEF]', @objname = N'[dbo].[UnGovernmentShipCode]';

