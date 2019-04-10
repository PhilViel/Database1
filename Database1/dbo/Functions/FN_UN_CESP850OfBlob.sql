/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CESP850OfBlob
Description 		:	Fonction qui extrait les enregistrements 850 d'un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESP850OfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tCESP850 
	TABLE (
		tiCESP850ErrorID TINYINT,
		vcTransaction VARCHAR(8000))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000)

	-- Découpe le blob en section de moins de 8000 caractères
	DECLARE crLinesOfBlob CURSOR FOR
		SELECT vcVal
		FROM dbo.FN_CRI_LinesOfBlob(@iBlobID)
		
	OPEN crLinesOfBlob
	
	-- Va chercher la première section du blob			
	FETCH NEXT FROM crLinesOfBlob
	INTO
		@vcLine
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF SUBSTRING(@vcLine, 1, 3) = '850'
		BEGIN
			INSERT INTO @tCESP850 ( 
				tiCESP850ErrorID,
				vcTransaction)
			VALUES (
				CAST(RTRIM(LTRIM(SUBSTRING(@vcLine, 4, 4))) AS SMALLINT),
				RTRIM(LTRIM(SUBSTRING(@vcLine, 8, 493))))
		END

		-- Passe à la prochaine section
		FETCH NEXT FROM crLinesOfBlob
		INTO
			@vcLine
	END

	CLOSE crLinesOfBlob
	DEALLOCATE crLinesOfBlob

	-- Fin des traitements
	RETURN
END

