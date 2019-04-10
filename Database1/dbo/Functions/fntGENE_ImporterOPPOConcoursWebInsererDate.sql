CREATE FUNCTION [dbo].[fntGENE_ImporterOPPOConcoursWebInsererDate]
(@iParaSansDate INT, @iParaOperation INT, @nvUsager NVARCHAR (255), @nvMotPasse NVARCHAR (255), @nvParaURL NVARCHAR (255))
RETURNS 
     TABLE (
        [code_exportation]           NVARCHAR (255) NULL,
        [code_exportationSpectified] NVARCHAR (255) NULL)
AS
 EXTERNAL NAME [assSQLCommonFunctions].[SQLCommonFunctions.OPPO].[Inserer_Date_Heure]

