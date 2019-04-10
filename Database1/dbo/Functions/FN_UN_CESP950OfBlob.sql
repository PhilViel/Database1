/****************************************************************************************************
Copyright (c) 2003 Gestion Universitas Inc
Nom 					:	FN_UN_CESP950OfBlob
Description 		:	Fonction qui extrait les enregistrements 950 d'un blob.
Valeurs de retour	:	Table temporaire
Note					:	ADX0000811	IA	2006-04-17	Bruno Lapointe	Création
*******************************************************************************************************************/
CREATE FUNCTION dbo.FN_UN_CESP950OfBlob (
	@iBlobID INTEGER) -- ID Unique du blob de la table CRI_Blob
RETURNS @tCESP950 
	TABLE (
		dtCESPReg DATETIME,
		ConventionNo VARCHAR(15),
		iConventionState INTEGER,
		tiCESP950ReasonID VARCHAR(1))
AS
BEGIN
	-- Variables de travail
	DECLARE 
		@vcLine VARCHAR(8000),
		@dtCESPReg DATETIME,
		@ConventionNo VARCHAR(15),
		@iConventionState INTEGER,
		@tiCESP950ReasonID VARCHAR(1)

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
		IF SUBSTRING(@vcLine, 1, 3) = '950'
		BEGIN
			-- Va chercher les valeurs dans la string
			IF SUBSTRING(@vcLine, 44, 8) <> '00000000'
				SET @dtCESPReg = CAST(SUBSTRING(@vcLine, 44, 4)+'-'+SUBSTRING(@vcLine, 48, 2)+'-'+SUBSTRING(@vcLine, 50, 2) AS DATETIME)
			ELSE 
				SET @dtCESPReg = NULL
			SET @ConventionNo = LTRIM(RTRIM(SUBSTRING(@vcLine, 29, 15)))
			SET @iConventionState = CAST(SUBSTRING(@vcLine, 52, 1) AS INTEGER)
			SET @tiCESP950ReasonID = LTRIM(RTRIM(SUBSTRING(@vcLine, 53, 1)))

			INSERT INTO @tCESP950 ( 
				dtCESPReg,
				ConventionNo,
				iConventionState,
				tiCESP950ReasonID)
			VALUES (
				@dtCESPReg,
				@ConventionNo,
				@iConventionState,
				@tiCESP950ReasonID)
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

