/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/*
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------
    2016-09-14  Steeve Picard           Deprecated - Renommer fntCONV_ObtenirStatutConventionEnDate_PourTous
*/
CREATE FUNCTION [dbo].[fnGENE_ObtenirAdresseEnDate]
(
	@iID_Humain int,
	@iID_Type int,
	@dtDate datetime
)
RETURNS TABLE
AS RETURN
	SELECT TOP 1
          ADR.iID_Adresse,
		ADR.vcNumero_Civique, --VARCHAR(10),
		ADR.vcNom_Rue, --VARCHAR(75),
		ADR.vcVille ,  -- Varchar(100)
		ADR.vcProvince,  --Varchar(75)
		ADR.vcPays,--as char(4)
		ADR.vcUnite,
		ADR.cID_Pays,
		ADR.vcCodePostal, --as Varchar(10),
		ADR.iID_TypeBoite,
		ADR.vcBoite
	FROM dbo.fntGENE_ObtenirAdresseEnDate(@iID_Humain, @iID_Type, @dtDate, 0) ADR
	ORDER BY 
		ADR.dtDate_Debut DESC