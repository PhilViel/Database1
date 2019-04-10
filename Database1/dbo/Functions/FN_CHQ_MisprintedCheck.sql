/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_MisprintedCheck
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000696	IA	2005-09-13	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_MisprintedCheck (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appelle la fonction
RETURNS @tCHQ_MisprintedCheck
	TABLE (
		iStartCheckNumber INTEGER,
		iEndCheckNumber INTEGER,
		vcReason VARCHAR(50),
		bPropose BIT,
		bLost BIT
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@iStartCheckNumber INTEGER,
		@iEndCheckNumber INTEGER,
		@vcReason VARCHAR(50),
		@bPropose BIT,
		@bLost BIT,
		----------------
		@iObjectID INTEGER,
		@iCurrentObjectID INTEGER,
		@vcFieldName VARCHAR(100),
		@vcValue VARCHAR(100)

	SET @iCurrentObjectID = 0

	DECLARE crMisprintedCheck CURSOR FOR
		SELECT 
			iObjectID,
			vcFieldName,
			SUBSTRING(txValue, 1, 50)
		FROM CRI_ObjectOfBlob
		WHERE vcClassName = 'CHQ_MisprintedCheck'
			AND iSPID = @iSPID
		ORDER BY iObjectID 

	OPEN crMisprintedCheck

	FETCH NEXT FROM crMisprintedCheck
	INTO
		@iObjectID,
		@vcFieldName,
		@vcValue

	SET @iCurrentObjectID = @iObjectID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcFieldName = 'iStartCheckNumber' 
			SET @iStartCheckNumber = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'iEndCheckNumber' 
			SET @iEndCheckNumber = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'vcReason' 
			SET @vcReason = SUBSTRING(@vcValue, 1, 50)
		ELSE IF @vcFieldName = 'bPropose' 
			SET @bPropose = CAST(@vcValue AS BIT)
		ELSE IF @vcFieldName = 'bLost' 
			SET @bLost = CAST(@vcValue AS BIT)

		FETCH NEXT FROM crMisprintedCheck
		INTO
			@iObjectID,
			@vcFieldName,
			@vcValue

		-- Vérifie si on vient de changer d'objet ou encore si on a tout lu (dernier objet lu).
		IF @iCurrentObjectID <> @iObjectID
		OR @@FETCH_STATUS <> 0
		BEGIN
			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tCHQ_MisprintedCheck (
				iStartCheckNumber,
				iEndCheckNumber,
				vcReason,
				bPropose,
				bLost )
			VALUES (
				@iStartCheckNumber,
				@iEndCheckNumber,
				@vcReason,
				@bPropose,
				@bLost )
			-- Remet les variables de champs vides pour le prochain objet.
			SET @iStartCheckNumber = NULL
			SET @iEndCheckNumber = NULL
			SET @vcReason = NULL
			SET @bPropose = 0
			SET @bLost = 0
			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID
		END
	END

	CLOSE crMisprintedCheck
	DEALLOCATE crMisprintedCheck

	-- Fin des traitements
	RETURN
END
