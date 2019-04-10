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

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	SP_SL_UN_IrregularityTypeCorrection
Description         :	Renvoi la liste de toutes les corrections faites pour un type d'anomalies.
Valeurs de retours  :	Dataset de données
Note                :	ADX0000496	IA	2005-02-03	Bruno Lapointe	    Création
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_IrregularityTypeCorrection] (
	@IrregularityTypeID MoID ) -- Id unique du type d'anomalies 
AS
BEGIN

    SELECT 1/0
    /*
	SELECT
		IrregularityTypeCorrectionID,
		IrregularityTypeID,
		CorrectingStoredProcedure,
		CorrectingDate,
		CorrectingCount
	FROM Un_IrregularityTypeCorrection
	WHERE IrregularityTypeID = @IrregularityTypeID
    */
END