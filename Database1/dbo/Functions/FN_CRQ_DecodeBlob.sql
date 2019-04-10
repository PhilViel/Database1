
/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRQ_DecodeBlob
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000693	IA	2005-05-17	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_DecodeBlob (
	@iBlobID INTEGER ) -- Identifiant unique du blob
RETURNS 
	@tField TABLE (
		iObjectID INTEGER,
		vcClassName VARCHAR(100),
		vcFieldName VARCHAR(100),
		txValue TEXT
		)
AS
BEGIN
	DECLARE
		-- Variables de réception des informations de ligne :
		@iObjectID INTEGER,
		@iPos INTEGER,
		@iPosRecord INTEGER,
		@iPosField INTEGER,
		@iPosValue INTEGER,
		@iPosValue2 INTEGER,
		@iBlobLength INTEGER,
		@vcClassName VARCHAR(100),
		@cRecordDelimiter VARCHAR(5), -- Délimiteur de classe
		@cFieldDelimiter VARCHAR(5), -- Délimiteur de record
		@cValueDelimiter VARCHAR(5) -- Délimiteur de champs

	SET @cRecordDelimiter = CHAR(6)
	SET @cFieldDelimiter = CHAR(21)
	SET @cValueDelimiter = CHAR(30)

	-- Ajoute les % nécesaire au PathIndex
	SET @cRecordDelimiter = '%'+@cRecordDelimiter+'%'
	SET @cFieldDelimiter = '%'+@cFieldDelimiter+'%'
	SET @cValueDelimiter = '%'+@cValueDelimiter+'%'

	-- Recherche le premier record, et détermine la grosseur du blob
	SELECT 
		@iPosRecord = PATINDEX(@cRecordDelimiter, Blob),
		@iPosField = PATINDEX(@cFieldDelimiter, Blob),
		@iPosValue = PATINDEX(@cValueDelimiter, Blob),
		@iPosValue2 = PATINDEX(@cValueDelimiter, Blob) + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, PATINDEX(@cValueDelimiter, Blob)+1, DATALENGTH(Blob)-PATINDEX(@cValueDelimiter, Blob))),
		@iBlobLength = DATALENGTH(Blob)
	FROM CRQ_Blob
	WHERE BlobID = @iBlobID

	IF @iPosRecord = 0
		SET @iPosRecord = @iBlobLength

	SET @iObjectID = 1

	WHILE @iPosRecord < @iBlobLength
		AND @iPosRecord < @iPosField
		AND @iPosField < @iPosValue
		AND @iPosValue < @iPosValue2
	BEGIN
		-- Insère le record dans la table temporaire
		INSERT INTO @tField (
				iObjectID,
				vcClassName,
				vcFieldName,
				txValue )
			SELECT
				@iObjectID,
				vcClassName = SUBSTRING(Blob, @iPosRecord+1, @iPosField-(@iPosRecord+1)),
				vcFieldName = SUBSTRING(Blob, @iPosField+1, @iPosValue-(@iPosField+1)),
				txValue = SUBSTRING(Blob, @iPosValue2+1, CAST(SUBSTRING(Blob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER))
			FROM CRQ_Blob
			WHERE BlobID = @iBlobID

		-- ce positionne aprés la valeur lu
		SELECT
			@vcClassName = SUBSTRING(Blob, @iPosRecord+1, @iPosField-(@iPosRecord+1)),
			@iPos = @iPosValue2 + CAST(SUBSTRING(Blob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER)
		FROM CRQ_Blob
		WHERE BlobID = @iBlobID

		IF @iPos+1 = @iBlobLength
		BEGIN
			SET @iPosRecord = @iBlobLength
			SET @iPosField = @iBlobLength
		END		
		ELSE
		BEGIN
			-- Recherche le premier record, et détermine la grosseur du blob
			SELECT 
				@iPosRecord = @iPos + PATINDEX(@cRecordDelimiter, SUBSTRING(Blob, @iPos+2, @iBlobLength-@iPos-1)) + 1,
				@iPosField = @iPos + PATINDEX(@cFieldDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)),
				@iPosValue = @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)),
				@iPosValue2 = @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)) + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1))+1, @iBlobLength-(@iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1))+1)))
			FROM CRQ_Blob
			WHERE BlobID = @iBlobID

			IF @iPosRecord = @iPos + 1
				SET @iPosRecord = @iBlobLength
	
			IF @iPosField = @iPos
				SET @iPosField = @iBlobLength
		END

		WHILE @iPosField < @iBlobLength
			AND @iPosRecord > @iPosField
			AND @iPosField < @iPosValue
			AND @iPosValue < @iPosValue2	
		BEGIN
			-- Insère le record dans la table temporaire
			INSERT INTO @tField (
					iObjectID,
					vcClassName,
					vcFieldName,
					txValue )
				SELECT
					@iObjectID,
					@vcClassName,
					vcFieldName = SUBSTRING(Blob, @iPosField+1, @iPosValue-(@iPosField+1)),
					txValue = SUBSTRING(Blob, @iPosValue2+1, CAST(SUBSTRING(Blob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER))
				FROM CRQ_Blob
				WHERE BlobID = @iBlobID

			-- ce positionne aprés la valeur lu
			SELECT
				@iPos = @iPosValue2 + CAST(SUBSTRING(Blob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER)
			FROM CRQ_Blob
			WHERE BlobID = @iBlobID
	
			IF @iPos+1 = @iBlobLength
			BEGIN
				SET @iPosRecord = @iBlobLength
				SET @iPosField = @iBlobLength
			END		
			ELSE
			BEGIN
				-- Recherche le premier record, et détermine la grosseur du blob
				SELECT 
					@iPosRecord = @iPos + PATINDEX(@cRecordDelimiter, SUBSTRING(Blob, @iPos+2, @iBlobLength-@iPos-1)) + 1,
					@iPosField = @iPos + PATINDEX(@cFieldDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)),
					@iPosValue = @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)),
					@iPosValue2 = @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1)) + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1))+1, @iBlobLength-(@iPos + PATINDEX(@cValueDelimiter, SUBSTRING(Blob, @iPos+1, @iBlobLength-@iPos-1))+1)))
				FROM CRQ_Blob
				WHERE BlobID = @iBlobID
		
				IF @iPosRecord = @iPos + 1
					SET @iPosRecord = @iBlobLength
		
				IF @iPosField = @iPos
					SET @iPosField = @iBlobLength
			END
		END

		SET @iObjectID = @iObjectID + 1
	END
	-- Fin des traitements
	RETURN
END
