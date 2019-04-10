/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_SectionOfBlob
Description 		:	Fonction de transformation d'un blob en chaîne de 8000 caractères maximum.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000861	IA	2005-09-29	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_SectionOfBlob (
	@iBlobID INTEGER) -- ID du blob de la table CRI_Blob qui contient les IDs 
RETURNS @Table TABLE (
	vcVal VARCHAR(8000)
	)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@iPosOper INTEGER,
		@iBlobPos INTEGER,
		@vcBlobPart VARCHAR(8000),
		@iBlobLength INTEGER

	SET @iBlobPos = 1

	SELECT 
		@vcBlobPart = 
			CASE 
				WHEN DATALENGTH (txBlob) < 8000 THEN SUBSTRING(txBlob, @iBlobPos, DATALENGTH (txBlob))
			ELSE SUBSTRING(txBlob, @iBlobPos, 8000)
			END,
		@iBlobLength = DATALENGTH (txBlob)
	FROM CRI_Blob
	WHERE iBlobID = @iBlobID

	WHILE @iBlobPos < @iBlobLength 
	BEGIN
		SET @iPosOper = 1
		-- Va chercher la position du dernier retour de chariot
		IF CHARINDEX(CHAR(13)+CHAR(10), @vcBlobPart, @iPosOper) > 0
			SET @iPosOper = 1
		ELSE 
			SET @iPosOper = LEN(@vcBlobPart)+1

		WHILE CHARINDEX(CHAR(13)+CHAR(10), @vcBlobPart, @iPosOper) > 0
			SET @iPosOper = CHARINDEX(CHAR(13)+CHAR(10), @vcBlobPart, @iPosOper) + 2
		SET @iBlobPos = @iBlobPos - 1 + @iPosOper

		SET @vcBlobPart = SUBSTRING(@vcBlobPart,1,@iPosOper-1) 

		INSERT INTO @Table (vcVal)
		VALUES (@vcBlobPart)

		IF @iBlobPos < @iBlobLength
			-- Passe à la prochaine section
			SELECT 
				@vcBlobPart = 
					CASE 
						WHEN @iBlobLength < (@iBlobPos + 8000) THEN SUBSTRING(txBlob, @iBlobPos, @iBlobLength - @iBlobPos + 1)
					ELSE SUBSTRING(txBlob, @iBlobPos, 8000)
					END
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID
	END

	-- Fin des traitements
	RETURN
END
