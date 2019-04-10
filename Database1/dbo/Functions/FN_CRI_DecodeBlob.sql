/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_DecodeBlob
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	ADX0000696	IA	2005-09-13	Bruno Lapointe		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_DecodeBlob (
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
		@iPosClass INTEGER,
		@iPosValue INTEGER,
		@iPosValue2 INTEGER,
		@iBlobLength INTEGER,
		@iNextDelimiter INTEGER,
		@iFieldNameNumber INTEGER,
		@iMaxFieldNumber INTEGER,
		@vcClassName VARCHAR(100),
		@vcFieldName VARCHAR(8000),
		@cClassDelimiter VARCHAR(5), -- Délimiteur de classe
		@cFieldDelimiter VARCHAR(5), -- Délimiteur de record
		@cValueDelimiter VARCHAR(5) -- Délimiteur de champs

	DECLARE @tFieldName TABLE (
			iFieldNameNumber INTEGER,
			vcFieldName VARCHAR(255)
			)

	SET @cClassDelimiter = CHAR(6)
	SET @cFieldDelimiter = CHAR(21)
	SET @cValueDelimiter = CHAR(30)

	SET @iObjectID = 1

	-- Recherche la première classe(type d'objet), et détermine la grosseur du blob
	SELECT 
		@iPosClass = dbo.FN_CRI_CHARINDEX(@cClassDelimiter, txBlob, 1),
		@vcClassName = SUBSTRING(txBlob, dbo.FN_CRI_CHARINDEX(@cClassDelimiter, txBlob, 1) + 1, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, 1) - dbo.FN_CRI_CHARINDEX(@cClassDelimiter, txBlob, 1) - 1),
		@iPosValue = dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, 1),
		@iPosValue2 = dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, 1)+1),
		@vcFieldName = SUBSTRING(txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, 1)+1), dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, 1) - dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, 1)+1)),
		@iBlobLength = DATALENGTH(txBlob)
	FROM CRI_Blob
	WHERE iBlobID = @iBlobID

	WHILE @iPosClass > 0
	BEGIN
		DELETE FROM @tFieldName
		INSERT INTO @tFieldName
			SELECT *
			FROM dbo.FN_CRI_GetFieldsName(@cFieldDelimiter,@vcFieldName)
			
		SELECT
			@iMaxFieldNumber = MAX(iFieldNameNumber)
		FROM @tFieldName

		WHILE @iPosClass <> 0
			AND @vcClassName <> ''
		BEGIN
			SET @iFieldNameNumber = 1
	
			WHILE @iFieldNameNumber <= @iMaxFieldNumber
				AND @iPosClass <> 0
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
						F.vcFieldName,
						txValue = SUBSTRING(txBlob, @iPosValue2+1, CAST(SUBSTRING(txBlob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER))
					FROM CRI_Blob
					JOIN @tFieldName F ON F.iFieldNameNumber = @iFieldNameNumber
					WHERE iBlobID = @iBlobID
	
				SET @iFieldNameNumber = @iFieldNameNumber + 1
				SELECT @iNextDelimiter = @iPosValue2 + CAST(SUBSTRING(txBlob, @iPosValue+1, @iPosValue2-(@iPosValue+1)) AS INTEGER) + 1
				FROM CRI_Blob
				WHERE iBlobID = @iBlobID
	
				IF @iPosValue <= @iBlobLength
				BEGIN
					SELECT
						@iPosValue = dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, @iNextDelimiter),
						@iPosValue2 = dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cValueDelimiter, txBlob, @iNextDelimiter)+1)
					FROM CRI_Blob
					WHERE iBlobID = @iBlobID
				END
				ELSE
					SET @iPosClass = 0
			END

			SET @iObjectID = @iObjectID + 1

			IF @iPosClass <> 0
			AND EXISTS (
					SELECT iBlobID
					FROM CRI_Blob
					WHERE iBlobID = @iBlobID
						AND SUBSTRING(txBlob, @iNextDelimiter, 1) <> @cValueDelimiter
					)
					SET @vcClassName = ''
		END
	
		IF @iPosClass <> 0
			AND EXISTS (
					SELECT iBlobID
					FROM CRI_Blob
					WHERE iBlobID = @iBlobID
						AND SUBSTRING(txBlob, @iNextDelimiter, 1) = @cClassDelimiter
					)
		BEGIN
			SELECT 
				@iPosClass = @iNextDelimiter,
				@vcClassName = SUBSTRING(txBlob, @iNextDelimiter + 1, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, @iNextDelimiter) - @iNextDelimiter - 1),
				@vcFieldName = SUBSTRING(txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, @iNextDelimiter) + 1), @iPosValue - dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, dbo.FN_CRI_CHARINDEX(@cFieldDelimiter, txBlob, @iNextDelimiter) + 1))
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID
		END
		ELSE
			SET @iPosClass = 0
	END

	-- Fin des traitements
	RETURN
END
