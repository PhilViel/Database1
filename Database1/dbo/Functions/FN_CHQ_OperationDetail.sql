/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_OperationDetail
Description 		:	Decode un blob et met CHQ_OperationDetail dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000709	IA	2005-09-14	Bernie MacIntyre		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_OperationDetail (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appel la fonction
RETURNS @tCHQ_OperationDetail
	TABLE (
		bDelete BIT,
		iOperationDetailID INT,
		iOperationID INT,
		fAmount DECIMAL(18, 4),
		vcAccount VARCHAR(50),
		vcDescription VARCHAR(50)
	)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@bDelete BIT,
		@iOperationDetailID INT,
		@iOperationID INT,
		@fAmount DECIMAL(18, 4),
		@vcAccount VARCHAR(50),
		@vcDescription VARCHAR(50),
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
		WHERE vcClassName = 'CHQ_OperationDetail'
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
		ELSE IF @vcFieldName = 'iOperationDetailID' 
			SET @iOperationDetailID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'iOperationID' 
			SET @iOperationID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'fAmount' 
			SET @fAmount = CAST(@vcValue AS DECIMAL(18,4))
		ELSE IF @vcFieldName = 'vcAccount' 
			SET @vcAccount = SUBSTRING(@vcValue, 1, 50)
		ELSE IF @vcFieldName = 'vcDescription' 
			SET @vcDescription = SUBSTRING(@vcValue, 1, 50)

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
			INSERT INTO @tCHQ_OperationDetail (
				bDelete,
		    		iOperationID,
		    		fAmount,
		    		vcAccount,
		    		vcDescription )
			VALUES (
				@bDelete,
		    		@iOperationID,
		    		@fAmount,
		    		@vcAccount,
		    		@vcDescription )

	  		-- Remet les variables de champs vides pour le prochain objet.
			SET @bDelete = NULL
			SET @iOperationDetailID = NULL
			SET @iOperationID = NULL
		    	SET @fAmount = NULL
		    	SET @vcAccount = NULL
		    	SET @vcDescription = NULL

			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID

		END
	END

	CLOSE crVerticalObject
	DEALLOCATE crVerticalObject
	PRINT 'lnsnfksf'
	-- Fin des traitements
	RETURN
END
