/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_Operation
Description 		:	Decode un blob et met CHQ_Operation dans une table temporaire
Valeurs de retour	:	Table temporaire
Note				:	ADX0000709	IA	2005-09-14	Bernie MacIntyre		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_Operation (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appel la fonction
RETURNS @tCHQ_Operation
	TABLE (
		bDelete BIT,
		iOperationID INT,
		bStatus BIT,
		iConnectID INTEGER,
		dtOperation DATETIME,
		vcDescription VARCHAR(50),
		vcRefType VARCHAR(10),
		vcAccount VARCHAR(50)
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@bDelete BIT,
		@iOperationID INT,
		@bStatus BIT,
		@iConnectID INTEGER,
		@dtOperation DATETIME,
		@vcDescription VARCHAR(50),
		@vcRefType VARCHAR(10),
		@vcAccount VARCHAR(50),
		----------------
		@iObjectID INTEGER,
		@iCurrentObjectID INTEGER,
		@vcFieldName VARCHAR(100),
		@vcValue VARCHAR(100)

	SET @iCurrentObjectID = 0

	DECLARE crVerticalObject CURSOR FOR
		SELECT 
			iObjectID,
			vcFieldName,
			SUBSTRING(txValue, 1, 50)
		FROM CRI_ObjectOfBlob
		WHERE vcClassName = 'CHQ_Operation'
			AND iSPID = @iSPID
		ORDER BY iObjectID 

	OPEN crVerticalObject

	FETCH NEXT FROM crVerticalObject
	INTO
		@iObjectID,
		@vcFieldName,
		@vcValue

	SET @iCurrentObjectID = @iObjectID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcFieldName = 'bDelete' 
			SET @bDelete = CAST(@vcValue AS BIT)
		ELSE IF @vcFieldName = 'iOperationID' 
			SET @iOperationID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'bStatus' 
			SET @bStatus = CAST(@vcValue AS BIT)
		ELSE IF @vcFieldName = 'iConnectID' 
			SET @iConnectID = CAST(@vcValue AS BIT)
		ELSE IF @vcFieldName = 'dtOperation' 
			SET @dtOperation = CAST(@vcValue AS BIT)
		ELSE IF @vcFieldName = 'vcDescription' 
			SET @vcDescription = SUBSTRING(@vcValue, 1, 50)
		ELSE IF @vcFieldName = 'vcRefType' 
			SET @vcRefType = SUBSTRING(@vcValue, 1, 10)
		ELSE IF @vcFieldName = 'vcAccount' 
			SET @vcAccount = SUBSTRING(@vcValue, 1, 50)

		FETCH NEXT FROM crVerticalObject
		INTO
			@iObjectID,
			@vcFieldName,
			@vcValue

		-- Vérifie si on vient de changer d'objet ou encore si on a tout lu (dernier objet lu).
		IF @iCurrentObjectID <> @iObjectID
		OR @@FETCH_STATUS <> 0
		BEGIN
			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tCHQ_Operation (
				bDelete,
				iOperationID,
				bStatus,
		    		iConnectID,
		    		dtOperation,
		    		vcDescription,
		    		vcRefType,
		    		vcAccount )
			VALUES (
				@bDelete,
				@iOperationID,
		    		@bStatus,
		    		@iConnectID,
		    		@dtOperation,
		    		@vcDescription,
		    		@vcRefType,
		    		@vcAccount )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @bDelete = NULL
			SET @iOperationID = NULL
			SET @bStatus = NULL
		    	SET @iConnectID = NULL
		    	SET @dtOperation = NULL
		    	SET @vcDescription = NULL
		    	SET @vcRefType = NULL
		    	SET @vcAccount = NULL

			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID

		END
	END

	CLOSE crVerticalObject
	DEALLOCATE crVerticalObject

	-- Fin des traitements
	RETURN
END
