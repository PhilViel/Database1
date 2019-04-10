/****************************************************************************************************
Copyrights (c) 2003 Gestion Universitas inc
Nom                 :	DL_UN_CESPSendFile
Description         :	Destruction d'un fichier d'envoi au PCEE
Valeurs de retours  :	@Return_Value :
									>0  :	Tout à fonctionné
		                  	<=0 :	Erreur SQL
Note                :	ADX0000811	IA	2006-04-13	Bruno Lapointe	Création
                    :                     2008-10-16  Fatiha Araar    Modification
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[DL_UN_CESPSendFile] (
	@iCESPSendFileID INTEGER) -- ID du fichier d'envoi
AS
BEGIN
	DECLARE
		@iResult INTEGER

	SET @iResult = @iCESPSendFileID

	-----------------
	BEGIN TRANSACTION
	-----------------

	-- Libère les enregistrements 100 liés à ce fichier
	UPDATE Un_CESP100
	SET iCESPSendFileID = NULL
	WHERE iCESPSendFileID = @iCESPSendFileID

	IF @@ERROR <> 0
		SET @iResult = -1

	IF @iResult > 0
	BEGIN
		-- Libère les enregistrements 200 liés à ce fichier
		UPDATE Un_CESP200
		SET iCESPSendFileID = NULL
		WHERE iCESPSendFileID = @iCESPSendFileID

		IF @@ERROR <> 0
			SET @iResult = -2
	END

	IF @iResult > 0
	BEGIN
		-- Libère les enregistrements 400 liés à ce fichier
		UPDATE Un_CESP400
		SET iCESPSendFileID = NULL
		WHERE iCESPSendFileID = @iCESPSendFileID

		IF @@ERROR <> 0
			SET @iResult = -3
	END

	IF @iResult > 0
	BEGIN
		-- Supprime les enregistrements 700 liés à ce fichier
		DELETE
		FROM Un_CESP700
		WHERE iCESPSendFileID = @iCESPSendFileID

		IF @@ERROR <> 0
			SET @iResult = -5
	END
       
    IF @iResult > 0
    BEGIN
		-- Libère les enregistrements 511 liés à ce fichier
		UPDATE Un_CESP511
		SET iCESPSendFileID = NULL
		WHERE iCESPSendFileID = @iCESPSendFileID

		IF @@ERROR <> 0
			SET @iResult = -6
	END

	IF @iResult > 0
	BEGIN
		-- Supprime le fichier
		DELETE
		FROM Un_CESPSendFile
		WHERE iCESPSendFileID = @iCESPSendFileID

		IF @@ERROR <> 0
			SET @iResult = -4
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
END
