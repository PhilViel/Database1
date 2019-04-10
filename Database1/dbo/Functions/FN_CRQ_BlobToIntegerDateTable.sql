/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 			:	FN_CRQ_BlobToIntegerDateTable
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note			:	ADX0001114	IA	2006-11-21	Alain Quirion		Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRQ_BlobToIntegerDateTable (@iBlobID INTEGER) -- ID du blob de la table CRQ_Blob qui contient les IDs et les dates
RETURNS @Table TABLE (
	ValID INTEGER IDENTITY, 
	Val INTEGER,
	dtValDate DATETIME)
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@iPosStart INTEGER,
		@iPosEnd INTEGER,
		@Val INTEGER,
		@dtValDate DATETIME,
		@ValStr VARCHAR(8000)

	-- Initilisation des variables	
	SELECT 
		@iPosEnd = 1,
		@iPosStart = 1

	-- Boucle tant qu'il reste des caractères dans la chaîne
	WHILE @iPosEnd > 0
	BEGIN
		SELECT
			@iPosEnd = dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart),
			@ValStr = 
				CASE 
					WHEN dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart) > 0 THEN
						SUBSTRING(Blob, @iPosStart, dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart) - @iPosStart)
				ELSE
					SUBSTRING(Blob, @iPosStart, DATALENGTH(Blob))
				END
		FROM CRQ_Blob
		WHERE BlobID = @iBlobID
	
		SET @ValStr = LTRIM(RTRIM(@ValStr)) -- Enlève les espaces
	
		-- Vérification que la prochaine valeur est bien numérique
		IF @ValStr LIKE '%[0-9]%' 
			AND (@ValStr NOT LIKE '%[^0-9]%' OR @ValStr LIKE '[-+]%' AND SUBSTRING(@ValStr, 2, LEN(@ValStr)) NOT LIKE '[-+]%[^0-9]%')
		BEGIN
			SET @Val = CONVERT(INTEGER, @ValStr)			
		END
	
		SET @iPosStart = @iPosEnd + 1

		IF @iPosEnd > 0
		BEGIN
			-- Recherche de la date
			SELECT
				@iPosEnd = dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart),
				@ValStr = 
					CASE 
						WHEN dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart) > 0 THEN
							SUBSTRING(Blob, @iPosStart, dbo.FN_CRI_CHARINDEX(',', Blob, @iPosStart) - @iPosStart)
					ELSE
						SUBSTRING(Blob, @iPosStart, DATALENGTH(Blob))
					END
			FROM CRQ_Blob
			WHERE BlobID = @iBlobID
		
			SET @ValStr = LTRIM(RTRIM(@ValStr)) -- Enlève les espaces
		
			-- Vérification que la prochaine valeur est bien une date
			IF @ValStr LIKE '%[0-9]%-%[0-9]%-%[0-9]%' 
			BEGIN
				SET @dtValDate = CONVERT(DATETIME, @ValStr)	
		
				-- Insertion de la valeur dans la table
				INSERT @Table(Val, dtValDate) 
				VALUES(@Val, @dtValDate)			
			END
		
			SET @iPosStart = @iPosEnd + 1		
		END
	END

	-- Fin des traitements
	RETURN
END

