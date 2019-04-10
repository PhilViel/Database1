/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_CheckProposal
Description 		:	Decode un blob et met CHQ_CheckProposal dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000709	IA	2005-09-14	Bernie MacIntyre		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_CheckProposal (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appel la fonction
RETURNS @tCHQ_CheckProposal
	TABLE (
		iCheckID INT,
		iPayeeID INT,
		dtEmission DATETIME,
		fAmount DECIMAL(18,4)
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@iCheckID INT,
		@iPayeeID INT,
		@dtEmission DATETIME,
		@fAmount DECIMAL(18,4),
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
		WHERE vcClassName = 'CHQ_CheckProposal'
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
		IF @vcFieldName = 'iCheckID' 
			SET @iCheckID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'iPayeeID' 
			SET @iPayeeID = CAST(@vcValue AS INT)
		ELSE IF @vcFieldName = 'dtEmission' 
			SET @dtEmission = CAST(@vcValue AS DATETIME)
		ELSE IF @vcFieldName = 'fAmount' 
			SET @fAmount = CAST(@vcValue AS DECIMAL(18, 4))

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
			INSERT INTO @tCHQ_CheckProposal (
				iCheckID,
				iPayeeID,
				dtEmission,
				fAmount )
			VALUES (
				@iCheckID,
				@iPayeeID,
				@dtEmission,
				@fAmount )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @iCheckID = NULL
			SET @iPayeeID = NULL
			SET @dtEmission = NULL
			SET @fAmount = NULL

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
