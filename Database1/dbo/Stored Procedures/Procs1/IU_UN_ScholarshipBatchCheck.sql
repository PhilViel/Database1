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
Nom                 :	IU_UN_ScholarshipBatchCheck
Description         :	Procédure d’insertion des bourses cochées pour un usager.
Valeurs de retours  :	@ReturnValue :
									>0 = Pas d’erreur
									<=0 = Erreur SQL
Note                :	ADX0000704	IA	2005-07-05	Bruno Lapointe		Création
                                        2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[IU_UN_ScholarshipBatchCheck] (
	@ConnectID INTEGER, -- ID unique de l’usager qui a coché les groupes d’unités.
	@ScholarshipIDs INTEGER) -- ID du blob contenant les ScholarshipID séparés par des « , » des bourses cochées.
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
	
	-- Supprime les bourses cochés précédemment pour cet usager
	DELETE Un_ScholarshipBatchCheck
	FROM Un_ScholarshipBatchCheck
	JOIN Mo_Connect C ON C.ConnectID = Un_ScholarshipBatchCheck.ConnectID
	WHERE C.UserID = @iUserID
	
	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Insère les bourses cochées pour l'usager
		INSERT INTO Un_ScholarshipBatchCheck (
				ScholarshipID,
				ConnectID )
			SELECT
				Val,
				@ConnectID
			FROM dbo.FN_CRQ_BlobToIntegerTable(@ScholarshipIDs)

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