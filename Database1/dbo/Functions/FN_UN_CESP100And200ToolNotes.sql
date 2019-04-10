/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_UN_CESP100And200ToolNotes
Description 		:	Retourne tous les notes contenus dans un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESP100And200ToolNotes (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @CESP100And200ToolNotes
	TABLE (
		iCESP800ID INT,
		vcNote VARCHAR(75))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@iPos INT,
		@iEndPos INT,
		@iCESP800ID INT,
		@vcNote VARCHAR(75)

	-- Va chercher les lignes contenus dans le blob
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première ligne			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		-- Saute par dessus le nom de la table qui est CRQ_BankReturnLink dans tout les cas
		SET @iPos = 1

		-- Va chercher le iCESP800ID 
		SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
		SET @iCESP800ID = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS INT)
		SET @iPos = @iEndPos + 1

		-- Va chercher le vcNote
		SET @iEndPos = CHARINDEX(';', @vcLine, @iPos)
		SET @vcNote = CAST(SUBSTRING(@vcLine, @iPos, @iEndPos - @iPos) AS VARCHAR(75))

		INSERT INTO @CESP100And200ToolNotes ( 
			iCESP800ID,
			vcNote)
		VALUES (
			@iCESP800ID,
			@vcNote)

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

