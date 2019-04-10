/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_ChequeSuggestionOfBlob
Description 		:	Retourne tous les objets de type Un_ChequeSuggestion contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_ChequeSuggestionOfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRQ_Blob
RETURNS @tChequeSuggestion
	TABLE (
		ChequeSuggestionID INTEGER, -- ID unique de la suggestion
		OperID INTEGER, -- ID de l'opération
		iHumanID INTEGER -- ID de l'humain qui est le destinataire du chèque
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@ChequeSuggestionID INTEGER,
		@OperID INTEGER,
		@iHumanID INTEGER

	-- Va chercher les lignes contenus dans le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Recherche la prochaine ligne de remboursement intégral du blob
		IF CHARINDEX('Un_ChequeSuggestion', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_IntReimb dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le ChequeSuggestionID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @ChequeSuggestionID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le OperID 
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le HumanID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @iHumanID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)

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
		END

		-- Passe à la prochaine ligne
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END

