/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_ChequeSuggestion
Description 		:	Recupere les objets de proposition de modification de chèque
Valeurs de retour	:	Table contenant les objets
Note					:	ADX0000693	IA	2005-05-17	Bruno Lapointe		Création
							ADX0000753	IA	2005-10-04	Bruno Lapointe		1. Le codage de l’objet Un_ChequeSuggestion dans le 
																						blob a changé pour celui-ci :
																						Un_ChequeSuggestion;ChequeSuggestionID;OperID;HumanID;
************************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_ChequeSuggestion (
	@iBlobID INTEGER ) -- Identifiant unique du blob
RETURNS @tChequeSuggestion
	TABLE (
		ChequeSuggestionID INTEGER, -- ID unique de la suggestion
		OperID INTEGER, -- ID de l'opération
		iHumanID INTEGER -- ID de l'humain qui est le destinataire du chèque
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@ChequeSuggestionID INTEGER,
		@OperID INTEGER,
		@iHumanID INTEGER,
		----------------
		@iObjectID INTEGER,
		@iCurrentObjectID INTEGER,
		@vcFieldName VARCHAR(100),
		@vcValue VARCHAR(100)

	SET @iCurrentObjectID = 0

	DECLARE crChequeSuggestionObj CURSOR FOR
		SELECT 
			iObjectID,
			vcFieldName,
			SUBSTRING(txValue, 1, 100)
		FROM dbo.FN_CRQ_DecodeBlob(@iBlobID)
		WHERE vcClassName = 'Un_ChequeSuggestion'
		ORDER BY iObjectID 

	OPEN crChequeSuggestionObj

	FETCH NEXT FROM crChequeSuggestionObj
	INTO
		@iObjectID,
		@vcFieldName,
		@vcValue

	SET @iCurrentObjectID = @iObjectID

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @vcFieldName = 'ChequeSuggestionID' 
			SET @ChequeSuggestionID = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'OperID' 
			SET @OperID = CAST(@vcValue AS INTEGER)
		ELSE IF @vcFieldName = 'HumanID' 
			SET @iHumanID = CAST(@vcValue AS INTEGER)

		FETCH NEXT FROM crChequeSuggestionObj
		INTO
			@iObjectID,
			@vcFieldName,
			@vcValue

		-- Vérifie si on vient de changer d'objet ou encore si on a tout lu (dernier objet lu).
		IF @iCurrentObjectID <> @iObjectID
		OR @@FETCH_STATUS <> 0
		BEGIN
			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tChequeSuggestion (
				ChequeSuggestionID,
				OperID,
				iHumanID ) 
			VALUES (
				@ChequeSuggestionID,
				@OperID,
				@iHumanID )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @ChequeSuggestionID = NULL
			SET @OperID = NULL
			SET @iHumanID = NULL

			-- Met à jour la variable donnant l'objet présentement traité.
			IF @@FETCH_STATUS = 0
				SET @iCurrentObjectID = @iObjectID
		END
	END

	CLOSE crChequeSuggestionObj
	DEALLOCATE crChequeSuggestionObj

	-- Fin des traitements
	RETURN
END

