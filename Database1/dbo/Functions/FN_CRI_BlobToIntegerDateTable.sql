/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 			:	FN_CRI_BlobToIntegerDateTable
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note			:	ADX0001114	IA	2006-11-21	Alain Quirion		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_BlobToIntegerDateTable (@iBlobID INTEGER) -- ID du blob de la table CRQ_Blob qui contient les IDs et les dates
RETURNS @Table TABLE (
	iValID INTEGER IDENTITY, 
	iVal INTEGER,
	dtValDate DATETIME)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@iPosStart INTEGER,
		@iPosEnd INTEGER,
		@iVal INTEGER,
		@dtValDate DATETIME,
		@iValStr VARCHAR(8000)

	-- Initilisation des variables	
	SELECT 
		@iPosEnd = 1,
		@iPosStart = 1

	-- Boucle tant qu'il reste des caractères dans la chaîne
	WHILE @iPosEnd > 0
	BEGIN
		SELECT
			@iPosEnd = dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart),
			@iValStr = 
				CASE 
					WHEN dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart) > 0 THEN
						SUBSTRING(txBlob, @iPosStart, dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart) - @iPosStart)
				ELSE
					SUBSTRING(txBlob, @iPosStart, DATALENGTH(txBlob))
				END
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID
	
		SET @iValStr = LTRIM(RTRIM(@iValStr)) -- Enlève les espaces
	
		-- Vérification que la prochaine valeur est bien numérique
		IF @iValStr LIKE '%[0-9]%' 
			AND (@iValStr NOT LIKE '%[^0-9]%' OR @iValStr LIKE '[-+]%' AND SUBSTRING(@iValStr, 2, LEN(@iValStr)) NOT LIKE '[-+]%[^0-9]%')
		BEGIN
			SET @iVal = CONVERT(INTEGER, @iValStr)			
		END
	
		SET @iPosStart = @iPosEnd + 1

		IF @iPosEnd > 0
		BEGIN
			-- Recherche de la date
			SELECT
				@iPosEnd = dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart),
				@iValStr = 
					CASE 
						WHEN dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart) > 0 THEN
							SUBSTRING(txBlob, @iPosStart, dbo.FN_CRI_CHARINDEX(',', txBlob, @iPosStart) - @iPosStart)
					ELSE
						SUBSTRING(txBlob, @iPosStart, DATALENGTH(txBlob))
					END
			FROM CRI_Blob
			WHERE iBlobID = @iBlobID
		
			SET @iValStr = LTRIM(RTRIM(@iValStr)) -- Enlève les espaces
		
			-- Vérification que la prochaine valeur est bien une date
			IF @iValStr LIKE '%[0-9]%-%[0-9]%-%[0-9]%' 
			BEGIN
				SET @dtValDate = CONVERT(DATETIME, @iValStr)	
		
				-- Insertion de la valeur dans la table
				INSERT @Table(iVal, dtValDate) 
				VALUES(@iVal, @dtValDate)			
			END
		
			SET @iPosStart = @iPosEnd + 1		
		END
	END

	-- Fin des traitements
	RETURN
END

