/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************    */

/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	IU_UN_IntReimbBatchCheck
Description         :	Procédure d’insertion des groupes unités cochés pour un usager.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000694	IA	2005-06-08	Bruno Lapointe		Création
                                        2018-01-22  Pierre-Luc Simard   N'est plus utilisé
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_IntReimbBatchCheck] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a coché les groupes d’unités.
	@UnitIDs INTEGER ) -- ID du blob contenant les UnitID séparés par des « , » des groupes d’unités cochés.
AS
BEGIN
    
    SELECT 1/0
    /*
	DECLARE
		@iResult INTEGER,
		@iUserID INTEGER

	SET @iResult = 1

	-----------------
	BEGIN TRANSACTION
	-----------------

	SELECT @iUserID = UserID
	FROM Mo_Connect
	WHERE ConnectID = @ConnectID
	
	DELETE Un_IntReimbBatchCheck
	FROM Un_IntReimbBatchCheck
	JOIN dbo.Un_Unit U ON U.UnitID = Un_IntReimbBatchCheck.UnitID
	JOIN Mo_Connect C ON C.ConnectID = Un_IntReimbBatchCheck.ConnectID
	WHERE U.TerminatedDate IS NOT NULL
		OR U.IntReimbDate IS NOT NULL
		OR C.UserID = @iUserID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		INSERT INTO Un_IntReimbBatchCheck (
				UnitID,
				ConnectID )
			SELECT
				Val,
				@ConnectID
			FROM dbo.FN_CRQ_BlobToIntegerTable(@UnitIDs)

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
		------------------
		COMMIT TRANSACTION
		------------------
	ELSE
		--------------------
		ROLLBACK TRANSACTION
		--------------------

	RETURN @iResult
    */
END