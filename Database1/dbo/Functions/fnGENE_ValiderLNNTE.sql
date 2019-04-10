CREATE FUNCTION [dbo].[fnGENE_ValiderLNNTE]
(@nvUsager NVARCHAR (255), @nvMotPasse NVARCHAR (255), @biTelephone BIGINT, @nvTelephoneSpecified NVARCHAR (5), @nvParaURL NVARCHAR (255))
RETURNS NVARCHAR (4000)
AS
 EXTERNAL NAME [assSQLCommonFunctions].[SQLCommonFunctions.WebService].[ValidateLNNTE]

