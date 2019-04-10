/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_LinesOfBlob
Description 		:	Retourne toutes les lignes d'un blob. Les lignes doivent être délémité par des retours de 
							chariots dans le blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_LinesOfBlob (
	@iBlobID INTEGER ) -- ID du blob de la table CRQ_Blob qui contient les IDs 
RETURNS @tLineTable TABLE (vcVal VARCHAR(8000))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@iPosOper INTEGER,
		@iEndPos INTEGER,
		@vcBlobPart VARCHAR(8000)

	-- Découpe le blob en section de moins de 8000 caractères
	DECLARE crBlobPart CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_SectionOfBlob(@iBlobID)
		
	OPEN crBlobPart
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM crBlobPart
	INTO
		@vcBlobPart
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @iPosOper = 1
		SET @iEndPos = 1

		WHILE @iEndPos > 0
		BEGIN
			IF CHARINDEX(CHAR(13)+CHAR(10), @vcBlobPart, @iPosOper) > 0
				SET @iEndPos = CHARINDEX(CHAR(13)+CHAR(10), @vcBlobPart, @iPosOper)
			ELSE 
				SET @iEndPos = 0
	
			IF @iEndPos > 0
			BEGIN
				INSERT INTO @tLineTable (vcVal)
				VALUES (SUBSTRING(@vcBlobPart, @iPosOper, @iEndPos - @iPosOper))
	
				SET @iPosOper = @iEndPos + 2
			END
		END

		-- Passe à la prochaine section
		FETCH NEXT FROM crBlobPart
		INTO
			@vcBlobPart
	END

	CLOSE crBlobPart
	DEALLOCATE crBlobPart

	-- Fin des traitements
	RETURN
END
