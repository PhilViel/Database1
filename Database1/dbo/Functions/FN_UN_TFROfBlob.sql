/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_TFROfBlob
Description 		:	Retourne tous les objets de type Un_TFR contenu dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000984	IA	2006-05-15	Alain Quirion		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_TFROfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tTFR
	TABLE (
		OperID INTEGER,
		bSendToPCEE BIT
		)
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@vcLine VARCHAR(8000),
		@iPos INTEGER,
		@iEndPos INTEGER,
		-----------------
		@OperID INTEGER,		
		@bSendToPCEE BIT

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
		-- Recherche la prochaine ligne de données TFR du blob
		IF CHARINDEX('Un_TFR', @vcLine, 0) > 0
		BEGIN
			-- Saute par dessus le nom de la table qui est Un_TFR dans tout les cas
			SET @iPos = CHARINDEX(';', @vcLine, 1) + 1

			-- Va chercher le OperID
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @OperID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INTEGER)
			SET @iPos = @iEndPos + 1

			-- Va chercher le bSendToPCEE
			SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
			SET @bSendToPCEE = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS BIT)

			-- Insère l'objet qu'on vient de finir de lire.
			INSERT INTO @tTFR (
				OperID,
				bSendToPCEE )
			VALUES (
				@OperID,
				@bSendToPCEE )

			-- Remet les variables de champs vides pour le prochain objet.
			SET @OperID = NULL
			SET @bSendToPCEE = NULL
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


