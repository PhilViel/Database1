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
Nom                 :	SP_SL_UN_IrregularityType
Description         :	Liste des anomalies
Valeurs de retours  :	Dataset de données
Note                :	ADX0000496	IA	2005-02-03	Bruno Lapointe		Création
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_SL_UN_IrregularityType]
AS
BEGIN
    
    SELECT 1/0
    /*
	SELECT
		IrregularityTypeID,
		IrregularityTypeName,
		SearchStoredProcedure,
		CorrectingStoredProcedure,
		Active
	FROM Un_IrregularityType
   ORDER BY IrregularityTypeName
   */
END