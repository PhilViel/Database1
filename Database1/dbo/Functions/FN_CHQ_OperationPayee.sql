/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_OperationPayee
Description 		:	Decode un blob et met CHQ_OperationPayee dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000709	IA	2005-09-14	Bernie MacIntyre		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_OperationPayee (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appel la fonction
RETURNS @tCHQ_OperationPayee
	TABLE (
		bDelete BIT,
		iOperationPayeeID INT,
		iPayeeID INT,
		iOperationID INT,
		iPayeeChangeAccepted INT,
		dtCreated DATETIME,
		vcReason VARCHAR(255)
	)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@bDelete BIT,
		@iOperationPayeeID INT,
		@iPayeeID INT,
		@iOperationID INT,
		@iPayeeChangeAccepted INT,
		@dtCreated DATETIME,
		@vcReason VARCHAR(255),
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
		WHERE vcClassName = 'CHQ_OperationPayee'
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
		ELSE IF @vcFieldName = 'iOperationPayeeID' 
			SET @iOperationPayeeID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'iPayeeID' 
			SET @iPayeeID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'iOperationID' 
			SET @iOperationID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'iPayeeChangeAccepted' 
			SET @iPayeeChangeAccepted = CAST(@vcValue AS INT)
/*	Impossible d'utiliser GETDATE() dans une fonction, mais on peux utiliser un VIEW qui contient GETDATE() -- A créer
		ELSE IF @vcFieldName = 'dtCreated' 
			SET @dtCreated = CAST(@vcValue AS DATETIME)
*/
		ELSE IF @vcFieldName = 'vcReason' 
			SET @vcReason = SUBSTRING(@vcValue, 1, 255)

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
			INSERT INTO @tCHQ_OperationPayee (
				iOperationPayeeID,
				iPayeeID,
				iOperationID,
				iPayeeChangeAccepted,
				dtCreated,
				vcReason )
			VALUES (
				@iOperationPayeeID,
				@iPayeeID,
				@iOperationID,
				@iPayeeChangeAccepted,
				@dtCreated,
				@vcReason )

    			-- Remet les variables de champs vides pour le prochain objet.
			SET @iOperationPayeeID = NULL
			SET @iPayeeID = NULL
			SET @iOperationID = NULL
			SET @iPayeeChangeAccepted = NULL
			SET @dtCreated = NULL
			SET @vcReason = NULL

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
