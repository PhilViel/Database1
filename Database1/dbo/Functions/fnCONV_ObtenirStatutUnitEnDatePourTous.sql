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
    2016-09-14  Steeve Picard           Deprecated - Renommer fntCONV_ObtenirStatutUnitEnDate_PourTous
*/
CREATE FUNCTION [dbo].[fnCONV_ObtenirStatutUnitEnDatePourTous]
(
	@dtDateStatut	DATETIME = NULL,
	@idUnit	INT = NULL
)
RETURNS TABLE AS
RETURN (
	SELECT *
	FROM dbo.fntCONV_ObtenirStatutUnitEnDate_PourTous(@dtDateStatut, @idUnit)
)