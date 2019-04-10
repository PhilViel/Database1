/****************************************************************************************************
Copyright (c) 2003 Compurangers.Inc
Nom 					:	FN_CRI_BlobToIntegerTable
Description 		:	Decode un blob est le met dans une table temporaire
Valeurs de retour	:	Table temporaire
Note					:	
	ADX0000696	IA	2005-09-23	Bruno Lapointe		Création
	ADX0001276	UP	2008-01-31	Bruno Lapointe		Quand le iBlobID = 0 la fonction tournait en boucle infini.
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_CRI_BlobToIntegerTable (@iBlobID INTEGER) -- ID du blob de la table CRI_Blob qui contient les IDs 
RETURNS @Table TABLE (
	iValID INTEGER IDENTITY, 
	iVal INTEGER)
AS
BEGIN
	IF EXISTS (
		SELECT *
		FROM CRI_Blob
		WHERE iBlobID = @iBlobID
		)
	BEGIN
		-- Variables de travail
		DECLARE 
			@iPosStart INTEGER,
			@iPosEnd INTEGER,
			@iVal INTEGER,
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
		
				-- Insertion de la valeur dans la table
				INSERT @Table(iVal) 
				VALUES(@iVal)
			END
		
			SET @iPosStart = @iPosEnd + 1
		
		END
	END

	-- Fin des traitements
	RETURN
END
