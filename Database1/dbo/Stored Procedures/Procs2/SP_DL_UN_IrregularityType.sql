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
Nom                 :	SP_DL_UN_IrregularityType
Description         :	Suppression d'un type d'anomalies.
Valeurs de retours  :	>0 : Suppression réussie
								<=0 : Erreur SQL
Note                :	ADX0000496	IA	2005-02-03	Bruno Lapointe		Création
                                        2018-01-19  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[SP_DL_UN_IrregularityType] (
	@ConnectID MoID, -- Id unique de la connection de l'usager
	@IrregularityTypeID MoID ) -- Id unique du type d'anomalies
AS
BEGIN

    SELECT 1/0
    /*
	DECLARE
		@ResultID MoID

	SET @ResultID = 1

	DELETE
	FROM Un_IrregularityType
	WHERE IrregularityTypeID = @IrregularityTypeID

	IF @@ERROR <> 0
		SET @ResultID = -1 -- Erreur lors de la suppression du type d'anomalies

	RETURN @ResultID
    */
END