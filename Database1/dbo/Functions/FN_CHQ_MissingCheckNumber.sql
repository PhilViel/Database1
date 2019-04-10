/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CHQ_MissingCheckNumber
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000696	IA	2005-09-13	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CHQ_MissingCheckNumber (
	@iSPID INTEGER ) -- ID de processus de la procédure stockée qui appelle la fonction
RETURNS @tCHQ_MissingCheckNumber
	TABLE (
		iCheckNumber INTEGER,
		vcReason VARCHAR(50)
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@iCheckNumber INTEGER,
		@vcReason VARCHAR(50),
		----------------
		@iObjectID INTEGER,
		@iCurrentObjectID INTEGER,
		@vcFieldName VARCHAR(100),
		@vcValue VARCHAR(100)

	SET @iCurrentObjectID = 0

	DECLARE crMissingCheckNumber CURSOR FOR
		SELECT 
			iObjectID,
			vcFieldName,
			SUBSTRING(txValue, 1, 50)
		FROM CRI_ObjectOfBlob
		WHERE vcClassName = 'CHQ_MissingCheckNumber'
			AND iSPID = @iSPID
		ORDER BY iObjectID 

	OPEN crMissingCheckNumber

	FETCH NEXT FROM crMissingCheckNumber
	INTO
		@iObjectID,
		@vcFieldName,
		@vcValue

	SET @iCurrentObjectID = @iObjectID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcFieldName = 'iCheckNumber' 
			SET @iCheckNumber = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'vcReason' 
			SET @vcReason = SUBSTRING(@vcValue, 1, 50)

		FETCH NEXT FROM crMissingCheckNumber
		INTO
			@iObjectID,
			@vcFieldName,
			@vcValue

		-- Vérifie si on vient de changer d'objet ou encore si on a tout lu (dernier objet lu).
		IF @iCurrentObjectID <> @iObjectID
		OR @@FETCH_STATUS <> 0
		BEGIN
			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tCHQ_MissingCheckNumber (
				iCheckNumber,
				vcReason )
			VALUES (
				@iCheckNumber,
				@vcReason )
			-- Remet les variables de champs vides pour le prochain objet.
			SET @iCheckNumber = NULL
			SET @vcReason = NULL
			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID
		END
	END

	CLOSE crMissingCheckNumber
	DEALLOCATE crMissingCheckNumber

	-- Fin des traitements
	RETURN
END
